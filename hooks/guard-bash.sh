#!/usr/bin/env bash
# agent-team plugin — PreToolUse guard for Bash. The only Bash guard: hooks.json has no Bash `if:` rules.
# Claude Code cannot parse a loop, `$(...)` or a heredoc against an `if:` rule and treats the command as
# a match, so those rules refused ordinary commands (`for f in *.ts; do ...; done` came back as
# "blocked git clean"). This script reads the real command instead: it splits it into simple commands and
# checks the program each one runs — which also catches flag reordering (`rm -fr`), a global option before
# the subcommand (`git -C dir push`), and a secret file read through a shell command, which the Read guard
# never sees. Exit 2 blocks the call; anything else lets it through.
set -u

payload=$(cat)

# Pull out tool_input.command. Git Bash on Windows usually has neither jq nor python, so without jq match
# the JSON string directly — checking the whole payload instead would match on the description too.
if command -v jq >/dev/null 2>&1; then
  cmd=$(jq -r '.tool_input.command // ""' <<<"$payload" 2>/dev/null)
else
  cmd=
  json_str='"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  if [[ $payload =~ $json_str ]]; then
    cmd=${BASH_REMATCH[1]}
    bs=$'\x01'
    cmd=${cmd//\\\\/$bs}
    cmd=${cmd//\\n/$'\n'}
    cmd=${cmd//\\t/$'\t'}
    cmd=${cmd//\\\"/\"}
    cmd=${cmd//$bs/\\}
  fi
fi
[ -n "$cmd" ] || exit 0

block() { echo "agent-team: blocked — $1. A human runs this." >&2; exit 2; }

# Heredoc bodies are data (a review appended with `cat >> file <<EOF`), not commands: drop them first.
code= delim=
heredoc='(^|[^<])<<-?[[:space:]]*["'"'"']?([A-Za-z_][A-Za-z0-9_]*)'
while IFS= read -r line || [ -n "$line" ]; do
  if [ -n "$delim" ]; then
    [ "${line//[[:space:]]/}" = "$delim" ] && delim=
    continue
  fi
  code+=$line$'\n'
  [[ $line =~ $heredoc ]] && delim=${BASH_REMATCH[2]}
done <<<"$cmd"

# 1. Secret files. Template copies are fine (`.env.example`, `.env.local.example`), so drop them first.
#    `.env` counts only as a file name — `process.env.X` and `import.meta.env` are code, not a secret.
scrubbed=$code
template='\.env[A-Za-z0-9._-]*\.(example|sample|template|dist)'
while [[ $scrubbed =~ $template ]]; do scrubbed=${scrubbed/"${BASH_REMATCH[0]}"/}; done
env_file='(^|[^A-Za-z0-9_$])\.env'
pem_file='\.pem([^A-Za-z0-9]|$)'
ssh_key='(id_rsa|id_ed25519|id_ecdsa)'
[[ $scrubbed =~ $env_file ]] && block "the command touches a .env file"
[[ $scrubbed =~ $pem_file ]] && block "the command touches a .pem key"
[[ $scrubbed =~ $ssh_key ]] && block "the command touches an SSH private key"

# 2. Split into simple commands and check what each one runs.
flat=$code
for sep in $'\n' ';' '&' '|' '(' ')' '`' '{' '}'; do flat=${flat//"$sep"/$'\x1f'}; done
IFS=$'\x1f' read -r -d '' -a segments <<<"$flat"

wrapper='^[[:space:]]*((sudo|env|exec|nohup|time|command|builtin|xargs|if|then|do|else|while|until|!)[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'"'"'[^'"'"']*'"'"'|[^[:space:]]*)[[:space:]]+)'
git_opt='^[[:space:]]+(-C|-c|--git-dir|--work-tree|--namespace)[[:space:]]+("[^"]*"|'"'"'[^'"'"']*'"'"'|[^[:space:]]+)'
git_flag='^[[:space:]]+-[^[:space:]]*'
rm_call='(^|[[:space:]])rm[[:space:]]+(.*)'
has_word() { [[ " $args " =~ [[:space:]]($1)[[:space:]] ]]; }

for seg in "${segments[@]}"; do
  # Recursive/forced delete anywhere in the segment, whatever the flag order — also `find -exec rm -rf`.
  if [[ $seg =~ $rm_call ]]; then
    rm_args=${BASH_REMATCH[2]}
    if [[ $rm_args =~ (^|[[:space:]])-[A-Za-z]*[rR] ]] || [[ $rm_args == *--recursive* ]]; then
      block "recursive rm"
    fi
  fi

  while [[ $seg =~ $wrapper ]]; do seg=${seg:${#BASH_REMATCH[0]}}; done
  seg=${seg#"${seg%%[![:space:]]*}"}
  prog=${seg%%[[:space:]]*}
  args=${seg#"$prog"}
  prog=${prog//[\"\']/}
  prog=${prog##*/}
  prog=${prog%.exe}

  case $prog in
    terraform) has_word 'apply|destroy' && block "terraform ${BASH_REMATCH[1]}" ;;
    kubectl)   has_word 'apply|delete|rollout' && block "kubectl ${BASH_REMATCH[1]}" ;;
    helm)      has_word 'install|upgrade' && block "helm ${BASH_REMATCH[1]}" ;;
    docker)    has_word 'push' && block "docker push" ;;
    npm|pnpm)  has_word 'publish' && block "$prog publish" ;;
    aws|gcloud|az|ssh|scp) block "$prog" ;;
    git)
      # The subcommand is the first word after git's global options, so `git stash push` is not `git push`.
      sub=$args
      while [[ $sub =~ $git_opt || $sub =~ $git_flag ]]; do sub=${sub:${#BASH_REMATCH[0]}}; done
      sub=${sub#"${sub%%[![:space:]]*}"}
      sub=${sub%%[[:space:]]*}
      sub=${sub//[\"\']/}
      case $sub in
        push)  block "git push" ;;
        clean) block "git clean" ;;
        reset) has_word '--hard' && block "git reset --hard" ;;
      esac
      ;;
  esac
done

exit 0
