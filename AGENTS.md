# app-ui

Shared, source-only design tokens and UI primitives for paullorb apps. No
runtime JavaScript, no registry dependency, no product-specific selector:
consumers pin a Git commit and `@import "@paullorb/app-ui/styles.css"`.
Product branding and feature styles stay in each application.

- A change here lands in every consumer at its next pin bump; keep tokens
  generic and never name a product in a selector.
- `npm run lint` and `npm run build` must pass; the README is the reference.

## Working as an agent here — the same in every paullorb repo

- **Keep the context small.** Hand off to a fresh session once the context
  passes about 200k tokens; never open a 1M-window session for routine work.
  A turn at 500k costs five times a turn at 100k even when it is all cache
  reads (the 2026-10-07 cross-project token audit).
- **Sweep with a subagent, not from the main context.** A `grep`/`sed`/`cat`
  pass over the tree belongs in an Explore subagent that returns the
  conclusion; read a file yourself only when you are about to edit it.
- **Routine work runs on Sonnet.** Red PRs, Dependabot follow-ups, gate
  re-runs and canary triage do not need the most expensive model.
- **Work in a worktree, never the primary checkout**
  (`.claude/hooks/primary-checkout-guard.sh` refuses the edit). The session
  starts by listing the repo's red PRs (`.claude/hooks/red-prs.sh`); your own
  red PR comes before new work.
- **Report the verdict, not the mechanics**: "CI passed" is the whole report.
  Wait for an outcome once, do not poll for it.
- **Every change goes through a PR into `main` with auto-merge armed**; never
  merge by hand.
