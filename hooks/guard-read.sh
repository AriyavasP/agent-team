#!/usr/bin/env bash
# agent-team plugin — PreToolUse guard for Read.
# Replaces the `if: "Read(./.env)"`-style rules that used to sit in hooks.json:
# like the Bash ones, they fired on paths Claude Code did not resolve the way the
# pattern assumed. This checks the file name itself, in any directory.
# Exit 2 blocks the call; anything else lets it through.
set -u

payload=$(cat)

if command -v jq >/dev/null 2>&1; then
  path=$(jq -r '.tool_input.file_path // ""' <<<"$payload" 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  path=$(python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' <<<"$payload" 2>/dev/null)
else
  exit 0
fi
[ -n "$path" ] || exit 0

name=${path##*/}

case $name in
  .env.example | .env.sample | .env.template | .env.dist) exit 0 ;;
  .env | .env.*) reason="a .env file" ;;
  *.pem) reason="a .pem key" ;;
  id_rsa* | id_ed25519* | id_ecdsa*) reason="an SSH private key" ;;
  *) exit 0 ;;
esac

echo "agent-team: blocked — reading $reason ($name). A human reads this." >&2
exit 2
