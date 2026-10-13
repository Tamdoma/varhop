# Disposal notes, slot A

## Q1
Pick: retire the leaf, keep the code as base. A new leaf (new slug) starts on a branch created at 0df6f48, so tested sync, search, copier, usage, latency and draft work stay; its review covers the full diff vs main because nothing of the plugin was merged. Cost: the new leaf inherits a 950-line root and frozen-test shape it may rewrite; planner decides what to keep.
Rejected:
- Recover same leaf: brief criteria 5 and the frozen tst_views.qml encode the stacked editor (map-C D3); changing a handed-off contract is new intake (shapes.md), and fix_rounds 4 carries over.
- Discard code: re-implements ~3300 lines and drops the lib latency fix (115 ms -> 50 ms at 2000+, report.md); no gain over branching from 0df6f48 and deleting what the planner rejects.
- Drop product: abandons the chart destination; operator wording "remove" reads as removing the failed unit, but this must be asked, not assumed.
Evidence: better-than-training · akrogon src/next.ts:325-333 (2026-10-13) · new leaf adopts a same-named branch, else branches from tracking ref · means the door must create branch <new-slug> at 0df6f48 before handoff. docs/guide/problems.md:16-27 · failed leaf only recovers by phase.
Pitfalls: two leaves claiming one branch -> door deletes old worktree, branch and leaf folder after creating the new branch. Old evidence lost -> archive leaf folder into the chart. Old tab wK:t7 panes left -> close them.
Extra question: new slug name.

## Q2
Pick: move the leaf folder (brief, design, plan, reviews, report, logs) into issues/chart/overlay-rework/archive/overlay-plugin/ so the evidence stays readable and issues/open/varhop holds only merged leaves; keep the installed plugin until the new leaf lands, since search/copy work today with the typed-repo workaround.
Rejected: delete records (loses review-B.md and proof logs). Uninstall now (operator loses a working tool for nothing; the new leaf's live checks reinstall anyway).
Pitfall: an archived state.yaml inside issues/chart could be picked up by dispatch? Dispatch reads issues/open only (assumption, low confidence) -> rename state.yaml to state.archived.yaml in the archive.
