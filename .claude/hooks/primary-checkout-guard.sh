#!/bin/sh
# PreToolUse (Edit|Write): refuses an edit or a new file in the PRIMARY
# checkout while it sits on main. That checkout is shared by every session on
# this machine; work left there is the next session's surprise. A worktree is
# the answer. Shared across paullorb repos; every failure is silence (exit 0).
file=$(python3 -I -c '
import json, os, sys
try:
    p = json.load(sys.stdin)
    f = p.get("tool_input", {}).get("file_path", "")
    print(os.path.abspath(os.path.join(p.get("cwd", os.getcwd()), f)) if f else "")
except Exception:
    print("")' 2>/dev/null) || exit 0
[ -n "$file" ] || exit 0
root=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0
# A linked worktree has a .git FILE; only the primary checkout has the directory.
[ -d "$root/.git" ] || exit 0
[ "$(git -C "$root" branch --show-current 2>/dev/null)" = "main" ] || exit 0
case "$file" in
  "$root"/.claude/worktrees/*) exit 0 ;;   # a worktree that lives under the checkout
  "$root"/*) ;;
  *) exit 0 ;;
esac
# Ignored paths (.env.local, local artifacts) are nobody's surprise; everything
# else, tracked or new, would land in the shared tree.
git -C "$root" check-ignore -q -- "$file" 2>/dev/null && exit 0
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"This is the primary checkout on main, shared by every session on this machine. Work in a worktree: git worktree add .claude/worktrees/<name> -b <branch> origin/main"}}'
exit 0
