# split

## Question
Q1. How many leaves, under which owner, in what order?

### Carries
- Merged map: slots/map-merged.md
- Disposal fork: forks/disposal.md. Taken Q4 4a: the successor reuses slug overlay-plugin and adopts the existing worktree and branch at 0df6f48, which is not on main.
- Owner index today: issues/open/varhop/ISSUE.md (prompt-core, repo-sync, overlay-plugin). Seat block goes there at handoff (CHART.md Handoff choices).
- Taken forks: proof-bar, editor, look, picker, controls (forks/*.md). Skill rule: only an actual dependency orders work, never file overlap.

## Findings
Notes: slots/split-A.md, -B.md, -C.md, merged slots/split-merged.md, rebuttals slots/split-rebuttal-B.md, -C.md.
- Owner stays issues/open/varhop/ISSUE.md. prompt-core and repo-sync are merged (A,B,C).
- 0df6f48 is 33 commits ahead of main, and main has no plugin. That is a real dependency for any leaf branched from main (A,B,C).
- A reusable uinput keyboard helper with a known-good pass and a caught deliberate break is absent on main and must land before a live criterion relies on it (B,C).
- Open: tree. B: proof-tools leaf, then overlay-plugin doing everything. C: overlay-plugin lands today's code plus the helper and a smoke, then overlay-rework does the five forks and carries the seed. C's tree changes the disposal carry that the successor lists Tamdoma/varhop#1.

## Taken

## Taken
Operator 2026-10-13: `1b | 2a`.
- 1b: two leaves under issues/open/varhop/ISSUE.md.
  - `overlay-plugin` adopts the branch and worktree at 0df6f48 (disposal 4a) and lands it on main behavior-unchanged. It also commits a reusable uinput keyboard helper inside the plugin repo, proven by an observable expected input result passing and a deliberate break failing, with cleanup both ways. It runs an install-and-summon smoke that drives keys into the overlay. It carries the criterion-to-evidence table. It does not list Tamdoma/varhop#1 in sources. Its end state is the installed copy repointed at a main-tracking source, enabled, with the selection intact.
  - `overlay-rework` does editor, look, picker, controls and the proof-bar final-build criteria, and owns the final live sweep and the post-merge operator checklist. It lists Tamdoma/varhop#1 in sources and has blocked-by: [overlay-plugin].
  - This amends the disposal carry: the seed source moves from the successor to overlay-rework, approved by the operator.
- 2a: if overlay-plugin's checks fail on untouched code, it makes the smallest repair needed to land and records it. Any F1-F7 behavior stays out of its scope.
- C's open questions are settled by default. The leaf slug is `overlay-rework`, which matches the chart and is free in issues/. ISSUE.md gets a line for each leaf.
- Operator 2026-10-13, after akrogon moved issues/open/varhop to issues/closed/varhop at 12:30 (all its remaining leaves merged): `1a`. Both leaves go under a new standalone issue issues/open/overlay-rework/ISSUE.md, with the seat block there. This replaces "under issues/open/varhop/ISSUE.md" above and the disposal carry's owner path.
