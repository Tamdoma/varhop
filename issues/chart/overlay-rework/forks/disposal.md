# Disposal of the failed overlay-plugin leaf

## Question
Q1. What happens to the failed leaf `overlay-plugin` and its code (branch overlay-plugin, 0df6f48)?
 - retire the leaf, keep the code as the base of new work
 - recover the same leaf with `akrogon phase`, revising its contract
 - retire the leaf and discard the code, rebuild from main
 - drop the overlay product altogether
Q2. If the leaf is retired: where do its records (brief, design, plan, reviews, report) go, and what happens to the copy installed on the desktop right now (Super+Alt+P bound) until replacement lands?

### Carries
- Operator note verbatim: "We also need to decide what to do with the overlay plugin, which has failed as a leaf. I think it needs to be removed."
- Old chart locks: issues/chart/varhop/CHART.md Forks taken (destination: hotkey overlay replaces Notion for prompts).
- Merged map: slots/map-merged.md.
- Related forks (not yet open): proof bar for OA1-OA3, inline editor mechanism, look, picker, visible controls.

## Findings
Notes: slots/disposal-A.md, -B.md, -C.md. Merged: slots/disposal-merged.md. Rebuttals: slots/disposal-rebuttal-B.md, -C.md.
- Retire the leaf, keep the code as base (A,B,C). Recover-in-place is legal but carries fix_rounds 4, the old ~40-criterion contract and declares OA1-OA4 resolved (A,C; B second choice). Rebuild and drop rejected by all.
- Records: move whole leaf folder into this chart's archive/ (A,B,C); plan, reviews, report and logs are untracked, so delete is unrecoverable (C). Leaving it in open pins the varhop owner open; issues/closed breaks completeOwner (B,C).
- Installed copy: keep until replacement lands (A,B,C). Inspected 2026-10-13 (A): installed clone at 0df6f48, origin file:///home/ivan/.akrogon/worktrees/varhop/overlay-plugin, i.e. the old worktree path.
- Slug: C reuse `overlay-plugin`; A,B new slug with door-made branch. Worktree path is keyed by slug (next.ts:310); an existing worktree at that path is reused (next.ts:315-323), else a same-named branch is adopted (next.ts:325-333). Reuse therefore needs no git step and keeps the installed copy's update source (A, from the inspected origin URL). New slug needs a branch at 0df6f48 and a remote change in the installed clone before the old worktree goes (B R2).
- Successor under issues/open/varhop/ so its merge completes the varhop owner (C); successor lists Tamdoma/varhop#1 in sources (C).
- Old tab wK:t7: panes wK:pB (pi) and wK:pC (codex) have cwd in the old worktree, so they are the failed leaf's seats, not chart peers (A, herdr agent list 2026-10-13); close after archive (B,C order: verify first, done).

## Taken
2026-10-13 operator: `1a | 2a | 3a | 4a`
- Q1 1a: retire the failed leaf, a successor leaf continues on the existing code (0df6f48). Foreclosed: recover in place, rebuild from main, drop the overlay.
- Q2 2a: move the whole leaf folder (tracked and untracked) to issues/chart/overlay-rework/archive/overlay-plugin/, verify the copy, confirm with `akrogon status`, close the old tab wK:t7. Foreclosed: delete.
- Q3 3a: keep the installed plugin until the successor lands, then update in place keeping the shell.json selection. Foreclosed: uninstall now.
- Q4 4a: successor reuses slug `overlay-plugin` and adopts the existing worktree and branch, so the installed clone's origin keeps working. Foreclosed: new slug.
Binding carries: successor first checks worktree HEAD 0df6f48 and clean; successor brief carries a criterion-to-evidence table; live runs read the deployed revision and restart the shell; pre-existing cache/state are not fixtures; final live state is installed, enabled at the merged head, selection intact; successor lives under issues/open/varhop/ and lists Tamdoma/varhop#1 in sources.
