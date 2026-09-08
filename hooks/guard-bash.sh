#!/usr/bin/env bash
# agent-team plugin — PreToolUse guard for Bash.
# The `if:` patterns in hooks.json catch the plain forms (`git push`, `rm -rf`).
# They cannot catch flag reordering (`rm -fr`), a global option before the
# subcommand (`git -C . push`), or reading a secret through a shell command,
# which the Read-tool guard never sees. This script inspects the real command.
# Exit 2 blocks the call; anything else lets it through.
set -u

payload=$(cat)

# Pull out the command string; fall back to the whole payload if no parser exists.
if command -v jq >/dev/null 2>&1; then
  cmd=$(jq -r '.tool_input.command // ""' <<<"$payload" 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' <<<"$payload" 2>/dev/null)
else
  cmd=$payload
fi
[ -n "$cmd" ] || exit 0

block() { echo "agent-team: blocked — $1. A human runs this." >&2; exit 2; }

# 1. Secret files. Example/sample/template files are fine, so drop them first.
scrubbed=$cmd
for allowed in .env.example .env.sample .env.template .env.dist; do
  scrubbed=${scrubbed//$allowed/}
done
if [[ $scrubbed =~ \.env ]]; then block "the command touches a .env file"; fi
if [[ $scrubbed =~ \.pem([^A-Za-z0-9]|$) ]]; then block "the command touches a .pem key"; fi
if [[ $scrubbed =~ (id_rsa|id_ed25519|id_ecdsa) ]]; then block "the command touches an SSH private key"; fi

# 2. Recursive/forced delete, whatever the flag order (-rf, -fr, -r -f, --recursive).
if [[ $cmd =~ (^|[[:space:]\;\&\|\(])rm[[:space:]]+([^\;\&\|]*) ]]; then
  rm_args=${BASH_REMATCH[2]}
  if [[ $rm_args =~ (^|[[:space:]])-[A-Za-z]*[rR] ]] || [[ $rm_args == *--recursive* ]]; then
    block "recursive rm"
  fi
fi

# 3. git subcommands that change something outside this working tree, including
#    forms with a global option first (`git -C dir push`).
if [[ $cmd =~ (^|[[:space:]\;\&\|\(])git([[:space:]]|$) ]]; then
  [[ $cmd =~ [[:space:]]push([[:space:]]|$) ]]                && block "git push"
  [[ $cmd =~ [[:space:]]reset([[:space:]].*)?[[:space:]]--hard ]] && block "git reset --hard"
  [[ $cmd =~ [[:space:]]clean([[:space:]]|$) ]]               && block "git clean"
fi

exit 0
