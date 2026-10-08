#!/bin/sh
# PreToolUse (Bash): refuses a `git push` to a branch whose pull request has
# already merged. Auto-merge squashes and GitHub then deletes the branch; a
# commit pushed in the minutes after that lands on a branch no pull request
# points at any more. Nobody reviews it, nothing merges it, and the sweep can
# only keep it, which is why its log said "pushed to after PR #79 merged" in
# six repos at once on 2026-10-08: one session's follow-up to the shared hooks,
# orphaned six times over. Cut a new branch off origin/main instead.
# Shared across paullorb repos; every failure is silence (exit 0).
payload=$(cat 2>/dev/null) || exit 0
read_field() {
  printf '%s' "$payload" | python3 -I -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get(sys.argv[1], "") or "")
except Exception:
    print("")' "$1" 2>/dev/null
}
# One `gh` call costs the shared 5,000/hour budget, so only a push pays for it.
case "$(read_field command)" in
  *'git push'*|*'git-push'*) ;;
  *) exit 0 ;;
esac
cwd=$(printf '%s' "$payload" | python3 -I -c '
import json, sys
try:
    print(json.load(sys.stdin).get("cwd", "") or "")
except Exception:
    print("")' 2>/dev/null)
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0
branch=$(git -C "$cwd" branch --show-current 2>/dev/null) || exit 0
[ -n "$branch" ] || exit 0
base=$(git -C "$cwd" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
[ "$branch" = "${base:-main}" ] && exit 0
command -v gh >/dev/null 2>&1 || exit 0
# An open pull request is the whole point of pushing, so it is asked first and
# it answers for the common case. Anything gh cannot answer is silence.
open=$(gh pr list --head "$branch" --state open --limit 1 --json number -q 'length' 2>/dev/null) || exit 0
[ "$open" = "0" ] || exit 0
merged=$(gh pr list --head "$branch" --state merged --limit 1 --json number -q '.[0].number' 2>/dev/null) || exit 0
[ -n "$merged" ] || exit 0
printf '%s' "$merged" | python3 -I -c '
import json, sys
n = sys.stdin.read().strip()
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "PR #" + n + " for this branch has already merged and no PR is open on it, so a push here lands where nothing will review or merge it. Cut a new branch off origin/main: git worktree add .claude/worktrees/<name> -b <branch> origin/main"}}))'
exit 0
