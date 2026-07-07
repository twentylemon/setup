#!/usr/bin/env bash
# Deny write-shaped `gh api` invocations while letting reads pass through.
# Reads (GET, no method flag) fall through to the normal allow-list; writes
# (POST/PATCH/PUT/DELETE and GraphQL mutations) are blocked with exit 2.

set -uo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Not a gh api call → pass through
if ! printf '%s' "$cmd" | grep -qE '\bgh[[:space:]]+api\b'; then
  exit 0
fi

# Explicit write method: -X <METHOD> or --method <METHOD>
if printf '%s' "$cmd" | grep -qiE '(-X|--method)[[:space:]]+(POST|PATCH|PUT|DELETE)\b'; then
  echo "gh api write methods (POST/PATCH/PUT/DELETE) are blocked by hook. Use gh pr/issue subcommands or run manually." >&2
  exit 2
fi

# GraphQL mutation: -f query='mutation ...' / --raw-field query="mutation ..." / bare mutation
if printf '%s' "$cmd" | grep -qiE "query=[\"']?[[:space:]]*mutation\b"; then
  echo "gh api graphql mutations are blocked by hook." >&2
  exit 2
fi

exit 0
