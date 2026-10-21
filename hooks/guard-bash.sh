#!/usr/bin/env bash
# agent-team plugin — PreToolUse guard for Bash. This is the only Bash guard.
#
# hooks.json used to carry `if:` rules (`Bash(git push:*)` …) as well. Claude Code
# matches those against its own parse of the command, and when it cannot parse a
# command — a for loop, a ${…} expansion, some redirects — every `if:` rule fires
# at once, so harmless commands were blocked under a random rule's name. This
# script reads the real command string instead, splits it into simple commands,
# and judges each one by its own command word.
#
# Exit 2 blocks the call; anything else lets it through.
# Written for bash 3.2 (macOS /bin/bash): no "${arr[@]}" on possibly-empty arrays.
set -u

payload=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(jq -r '.tool_input.command // ""' <<<"$payload" 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' <<<"$payload" 2>/dev/null)
else
  cmd=$payload
fi
[ -n "$cmd" ] || exit 0

block() { echo "agent-team: blocked — $1. A human runs this." >&2; exit 2; }

# 1. Secret files, anywhere in the command: cat, grep, head, cp all count.
#    Example/sample/template files are fine, so drop them first. `.env` must be a
#    file name, not part of an identifier like process.env or import.meta.env.
scrubbed=$cmd
for allowed in .env.example .env.sample .env.template .env.dist; do
  scrubbed=${scrubbed//"$allowed"/}
done
if [[ $scrubbed =~ (^|[^A-Za-z0-9_])\.env([^A-Za-z0-9_]|$) ]]; then block "the command touches a .env file"; fi
if [[ $scrubbed =~ \.pem([^A-Za-z0-9]|$) ]]; then block "the command touches a .pem key"; fi
if [[ $scrubbed =~ (id_rsa|id_ed25519|id_ecdsa) ]]; then block "the command touches an SSH private key"; fi

# 2. Split into simple commands. A separator inside quotes also splits, which can
#    only make the guard stricter, never let something through.
segs=$cmd
for sep in '&&' '||' '$(' ';' '|' '&' '`' '(' ')' '{' '}'; do
  segs=${segs//"$sep"/$'\n'}
done

# Block when any argument of the current command is one of the given words.
w=()
has_word() {
  local j k
  for ((j = 1; j < ${#w[@]}; j++)); do
    for k in "$@"; do
      [ "${w[$j]}" = "$k" ] && block "$name $k"
    done
  done
  return 0
}

while IFS= read -r seg; do
  # Drop leading VAR=value assignments and wrappers that run the next word.
  read -r -a w <<<"$seg"
  while [ ${#w[@]} -gt 0 ] && [[ ${w[0]} =~ ^([A-Za-z_][A-Za-z0-9_]*=.*|sudo|command|exec|nohup|time|env|if|elif|then|else|while|until|do|!)$ ]]; do
    w=("${w[@]:1}")
  done
  [ ${#w[@]} -gt 0 ] || continue
  name=${w[0]##*/}   # /usr/bin/git → git

  case $name in
    rm)
      for ((j = 1; j < ${#w[@]}; j++)); do
        if [[ ${w[$j]} =~ ^-[A-Za-z]*[rR] ]] || [ "${w[$j]}" = "--recursive" ]; then
          block "recursive rm"
        fi
      done
      ;;
    git)
      # The subcommand is the first word after the global options (-C dir, -c k=v, …).
      i=1
      while [ $i -lt ${#w[@]} ] && [[ ${w[$i]} == -* ]]; do
        case ${w[$i]} in
          -C | -c | --git-dir | --work-tree | --namespace) i=$((i + 2)) ;;
          *) i=$((i + 1)) ;;
        esac
      done
      sub=""
      [ $i -lt ${#w[@]} ] && sub=${w[$i]}
      case $sub in
        push) block "git push" ;;
        clean) block "git clean" ;;
        reset) [[ " ${w[*]} " == *" --hard "* ]] && block "git reset --hard" ;;
      esac
      ;;
    terraform) has_word apply destroy ;;
    kubectl) has_word apply delete rollout ;;
    helm) has_word install upgrade ;;
    docker) has_word push ;;
    npm | pnpm | yarn) has_word publish ;;
    aws | gcloud | az | ssh | scp) block "$name" ;;
  esac
done <<<"$segs"

exit 0
