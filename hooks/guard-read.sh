#!/usr/bin/env bash
# agent-team plugin — PreToolUse guard for Read. hooks.json runs it only when an `if:` rule matched a
# secret-looking path (.env, .env.*, *.pem, id_rsa*); this script makes the final call, because a rule
# cannot say "except template copies" and `Read(./.env.*)` alone refused `.env.local.example`.
# Exit 2 blocks the call; anything else lets it through.
set -u

payload=$(cat)

if command -v jq >/dev/null 2>&1; then
  file=$(jq -r '.tool_input.file_path // ""' <<<"$payload" 2>/dev/null)
else
  file=
  json_str='"file_path"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  [[ $payload =~ $json_str ]] && file=${BASH_REMATCH[1]//\\\\/\\}
fi

name=${file##*[/\\]}
case $name in
  *.example|*.sample|*.template|*.dist) exit 0 ;;
esac

echo "agent-team: blocked reading $name — secrets stay out of agent context. A human opens this file." >&2
exit 2
