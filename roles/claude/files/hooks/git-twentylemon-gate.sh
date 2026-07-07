#!/usr/bin/env bash
# Gate destructive git ops on the twentylemon/* branch prefix.
# Auto-approves on twentylemon/*, blocks elsewhere. Covers:
#   - commit, push (upstream-affecting)
#   - reset --hard, clean -f/--force, checkout ., restore ., stash drop/clear
#     (locally destructive of uncommitted work)
#
# Worktree-aware: when the command targets a directory other than the bash
# tool's cwd (via `git -C <dir>` or a leading `cd <dir> &&`), the branch
# check runs in that directory so commits inside graft worktrees aren't
# blocked by the outer repo being on master.

set -uo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."')

gp='\bgit\b([[:space:]]+-[Cc][[:space:]]+\S+)*[[:space:]]+'
if   printf '%s' "$cmd" | grep -qE "${gp}(commit|push)\b"; then :
elif printf '%s' "$cmd" | grep -qE "${gp}reset\b.*--hard\b"; then :
elif printf '%s' "$cmd" | grep -qE "${gp}clean\b[[:space:]]+(-[a-zA-Z]*f|--force)"; then :
elif printf '%s' "$cmd" | grep -qE "${gp}(checkout|restore)\b[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)"; then :
elif printf '%s' "$cmd" | grep -qE "${gp}stash[[:space:]]+(drop|clear)\b"; then :
else
  exit 0
fi

# Resolve which directory the git command will actually run in.
git_dir=""
if [[ "$cmd" =~ git[[:space:]]+-[Cc][[:space:]]+([^[:space:]]+) ]]; then
  git_dir="${BASH_REMATCH[1]}"
elif [[ "$cmd" =~ ^[[:space:]]*cd[[:space:]]+\"([^\"]+)\" ]]; then
  git_dir="${BASH_REMATCH[1]}"
elif [[ "$cmd" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]&;]+) ]]; then
  git_dir="${BASH_REMATCH[1]}"
fi

if [[ -z "$git_dir" ]]; then
  git_dir="$cwd"
elif [[ "$git_dir" != /* ]]; then
  git_dir="$cwd/$git_dir"
fi

branch=$(git -C "$git_dir" branch --show-current 2>/dev/null || true)

if [[ "$branch" == twentylemon/* ]]; then
  jq -nc --arg reason "on twentylemon/* branch ($branch)" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", permissionDecisionReason: $reason}}'
  exit 0
fi

echo "destructive git ops (commit, push, reset --hard, clean -f, checkout ., restore ., stash drop/clear) are only auto-allowed on twentylemon/* branches. Current branch: '${branch:-<none>}' (checked dir: $git_dir). Switch with: git switch -c twentylemon/<name>" >&2
exit 2
