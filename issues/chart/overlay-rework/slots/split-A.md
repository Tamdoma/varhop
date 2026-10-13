# Split notes, slot A

## Q1 how many leaves
Pick: one leaf, `overlay-plugin`, continuing the existing branch at 0df6f48. Reason: every taken fork changes the same unmerged code (0df6f48 is not on main, checked `git merge-base --is-ancestor`). A second leaf would have to branch from main, where none of this code exists, or from the overlay-plugin branch, which is a real dependency, so it could not run in parallel anyway. The live acceptance (proof-bar) checks the whole overlay at once on the final build. Cost: one long leaf; mitigated by the brief's criterion-to-evidence table (disposal carry).
Rejected: C's four leaves (look+nav, picker, editor, close-out). Each depends on the unmerged base, so they serialize; four merges, four live runs, same files. B's one owner with internal areas matches this pick.
Evidence: primary · disposal Taken 4a; worktree HEAD 0df6f48 not ancestor of main; chart-issues SKILL Drain rule.

## Q2 owner
Pick: existing issues/open/varhop/ISSUE.md, which already lists overlay-plugin. Seat block goes there. No new owner folder.

## Q3 order and prerequisites
Pick: no blocked-by. prompt-core and repo-sync are both phase merged (their state.yaml), and overlay-plugin calls lib/ and varhop-sync. A prerequisite leaf is needed only if a live criterion needs machinery missing on main; proof-bar showed the uinput probe works, so none expected. Confirm at handoff review.
