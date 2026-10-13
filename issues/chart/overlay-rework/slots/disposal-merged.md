# Disposal merged notes (A, B, C), 2026-10-13

## Q1 failed leaf and its code
- Retire the leaf, keep code as base of new work (A,B,C). Reason: leaf failed on proof, not code; last B re-check no open defect, 77 pass; branch holds whole plugin plus lib latency fix (p95 115 ms -> 4 ms at 2000). Cost: retirement is manual (no akrogon verb); successor inherits 950-line root; needs criterion-to-evidence table.
- Recover same leaf via `akrogon phase` (B: valid second choice; A,C reject). Legal (routing.ts:37, phase.ts:351), frozen tests re-recorded at plan.synthesis->implement (phase.ts:436-441, C) or cited (phase.ts:562-598, B). Rejected: recovery declares blocker resolved while OA1-OA4 wait on this chart; fix_rounds 4 carry over; mixes old ~40-criterion contract with new one; forces one-leaf shape (A,C).
- Rebuild from main (rejected A,B,C): main has no plugin; deletes 33 commits and latency fix; re-proves everything.
- Drop product (rejected A,B,C): contradicts "resolve all of them" and locked destination; orphans merged prompt-core/repo-sync; seed #1 stays open.

## Q2 records and installed copy
- Records: move the whole leaf folder into issues/chart/overlay-rework/archive/overlay-plugin/ (A,B,C). Only brief/design/readiness/state are tracked; plan, reviews, report, logs are untracked (C, git status), so deletion is unrecoverable. Chart folders are outside leaf scans (state.ts allLeaves scans open+closed) (B,C).
  Rejected: delete (A,B,C); leave in open (pins varhop owner open forever, slug taken) (B,C); hand-move to issues/closed (still scanned; completeOwner throws when issues/closed/varhop exists, phase.ts:211-213) (B,C); park (moves merged siblings, refuses tab/worktree) (B,C).
- Installed copy: keep installed, enabled and bound until replacement lands, then `omarchy plugin update` + `omarchy-restart-shell` (A,B,C). Installed checkout is a clean clone at 0df6f48 (C, inspected), update keeps the shell.json selection (report.md), remove/disable delete it (design.md). Cost: operator keeps the clunky build meanwhile.
  B: present records and install as separate choices; install removal is not implied by retiring the leaf.

## Where slots differ
- Successor slug and branch: C reuse slug `overlay-plugin` so akrogon adopts branch directly (next.ts:325-333), after old folder leaves open/closed (duplicate slug throws). A,B new slug, door creates branch <new-slug> at 0df6f48 and keeps old branch until ancestry checked (B). Adoption only happens when the worktree path does not exist (C, next.ts:315-323), so old worktree must be removed first either way.
- Successor owner folder (C): place successor under issues/open/varhop/ so its merge completes the varhop owner (completeOwner needs every leaf merged, phase.ts:203-237); a new owner folder leaves varhop open forever.
- Seed #1 close (C): failed leaf sources empty; successor must list Tamdoma/varhop#1.
- Old tab wK:t7 (panes wK:pB, wK:pC): close at retirement (A); verify what they host first (B).
- Only one leaf can adopt the branch, so any parallel split waits for the first leaf to land (C).

## Pitfalls and removers
- Successor starts from main -> verify worktree HEAD 0df6f48 and clean before editing (B,C).
- Duplicate slug throw -> archive first, then `akrogon status` shows no overlay-plugin line (C).
- Old evidence lost or assumed -> archive complete folder incl. untracked, verify before removing; criterion-to-evidence table in successor brief (A,B,C).
- Stale build tested -> read deployed revision, restart shell (B,C).
- Successor lifecycle check ends with plugin removed -> done-criterion end state: installed, enabled at merged head, selection intact (C).
- Operator's cache/state deleted as fixtures -> binding line: pre-existing cache and state are not fixtures (B,C).
