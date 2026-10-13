# Disposal fork notes, slot C (blind), 2026-10-13

## Q1. What happens to the failed leaf and its code?

### Pick
Retire the leaf, keep the code as the base of new work. Concretely: archive
the old leaf's records out of the leaf scan (Q2), then the first successor
leaf reuses slug `overlay-plugin` so it adopts branch `overlay-plugin` at
`0df6f48` instead of branching from main.

Reason: the code is not the failure. The final B re-check found no open
product defect and the check passes 77 (leaf review-B.md, final handoff).
The branch holds the whole plugin (33 commits ahead of main, 0 behind),
the repairs for review findings F1-F14 and F16, and the latency work in
`lib/search.mjs` and `lib/import.mjs` without which search misses its
50 ms budget (measured p95 115 ms at 2000 prompts before, 4 ms after;
leaf implementation/report.md). Adoption is a tool-supported path, not a
transplant: when akrogon creates a worktree for a leaf whose slug names
an existing branch, it checks out that branch
(/home/ivan/Work/infra/akrogon/src/next.ts:325-333).

Cost: retirement is manual. No akrogon verb retires a leaf (verb list at
src/akrogon.ts:187), so a named person moves the folder and verifies
`akrogon status` afterwards. The successor also inherits a 950-line
Varhop.qml and must carry an evidence table showing which old proofs
still count, because its fresh state (fix_rounds 0, new frozen tests)
says nothing about the adopted code's history. Only one successor can
adopt the branch, so at least the first new leaf is a single leaf until
the code lands on main.

### Rejected options
- Recover the same leaf with `akrogon phase`, revising its contract.
  Mechanically legal: from failed, every non-terminal phase is allowed
  (src/routing.ts:37-49), the operator runs the move without `--slot`
  (src/phase.ts:351-353), and recovery to plan.synthesis would re-record
  frozen tests on the move to implement (src/phase.ts:436-441), so even
  the frozen stacked-editor tests are not a hard wall. Rejected because
  recovery declares the blocker resolved, and OA1-OA4 are not resolved,
  they are waiting on this chart's proof-bar fork. It also forces the
  one-leaf shape that burned 4 fix rounds (state.yaml fix_rounds carries
  over, src/phase.ts:159-162), keeps the old brief's roughly 40
  done-criteria and the old readiness grants as the contract to revise
  in place, and makes it ambiguous which brief version the existing
  review and report evidence belongs to. The chart's remaining forks
  (editor mechanism, look, picker, controls) may want more than one
  leaf; recovery pre-decides that they do not.
- Retire the leaf and discard the code, rebuild from main. Main has no
  plugin at all, so this deletes 33 commits: the sync transaction, draft
  ownership, copier, per-name undo, clipboard-safe test wrappers and the
  latency fix in merged prompt-core files. Search then fails its budget
  again at 2000 prompts (report latency repair numbers above) and every
  fixed review finding can recur. It also re-runs the whole live proof
  list on the operator's one shell. This is the largest option, and
  nothing found says the code is bad, only that its editor shape and
  look are wrong.
- Drop the overlay product altogether. Contradicts the same-day operator
  notes, which say both "resolve all of them" and "I think it needs to
  be removed" about the leaf (INTAKE.md sources), and the locked
  destination in issues/chart/varhop/CHART.md (hotkey overlay replaces
  Notion for prompts). It orphans the merged prompt-core and repo-sync
  leaves with no consumer, and it still does not avoid work: the
  installed plugin, its cache and state and the bind line all need the
  removal steps in Q2 anyway, and seed Tamdoma/varhop#1 stays open.

### Evidence
- better-than-training · akrogon source read 2026-10-13 ·
  /home/ivan/Work/infra/akrogon/src/next.ts:325-333 (branch adoption by
  slug), src/phase.ts:351-353 (operator recovery without --slot),
  src/phase.ts:436-441 (frozen re-recorded only at plan.synthesis to
  implement), src/phase.ts:159-162 (fix_rounds preserved),
  src/akrogon.ts:187 (no retire verb). Changed the pick: adoption makes
  "retire leaf, keep code" a supported route instead of a cherry-pick.
- better-than-training · akrogon source read 2026-10-13 ·
  src/state.ts allLeaves throws `Duplicate leaf slug` when the same slug
  appears twice across issues/open and issues/closed. Changed the pick's
  shape: the old folder must leave both areas before a same-slug
  successor can exist.
- better-than-training · leaf files read 2026-10-13 ·
  issues/open/varhop/overlay-plugin/state.yaml (failed, blocked,
  check.fix, fix_rounds 4, frozen test hashes), review-B.md final
  handoff (no open product defect, check 77 pass),
  implementation/report.md (latency before and after, live outcomes
  already proven). Supports: code is an asset, proof bar is the blocker.
- better-than-training · git in the worktree, 2026-10-13 · branch
  overlay-plugin is 33 ahead, 0 behind main; diff is 19 files, about
  3300 insertions, including lib/search.mjs and lib/import.mjs. Supports:
  discard means rebuilding everything, not a delta.
- operator · INTAKE.md (chart overlay-rework), read 2026-10-13 · the two
  operator notes quoted above. The "removed" note names the leaf ("which
  has failed as a leaf"), which is this pick, not the product.

### Pitfalls and what removes each
- Successor created while the old folder still sits in issues/open or
  issues/closed: every akrogon command that scans leaves throws
  `Duplicate leaf slug` (src/state.ts allLeaves). Removed by a handoff
  step, owned by the chart door: archive the old folder (Q2) first, then
  run `akrogon status` and see no failed overlay-plugin line before the
  successor leaf is handed off. Pending until done.
- Adoption silently not taken because the old worktree still exists:
  adoption runs only in the branch where the worktree path does not
  exist (src/next.ts ensureWorktree, path-exists branch reuses the
  worktree). A failed leaf's worktree is removed by reconcile when no
  live pane is inside (src/reconcile.ts:306-317). Removed by a done-step
  in the successor's first phase: worktree `git rev-parse HEAD` reads
  `0df6f48` and `git status` is clean before any editing.
- Adopted code treated as newly written: the 4 rounds of live evidence
  in report.md get re-run or, worse, silently assumed. Removed by a
  criterion-to-evidence table in the successor brief (merged map
  pitfall), one row per old done-criterion: still counts, invalidated
  by the editor redesign, or moved to operator check.
- Settled chart locks re-litigated because the new leaf looks fresh.
  Removed by carrying the old design.md Taken sections into the
  successor brief verbatim, except the forks this chart takes.
- Nothing removes this cost of the pick: branch adoption serves exactly
  one slug, so a parallel multi-leaf split cannot all start from the
  branch. Later leaves must wait for the first to land on main.

### Questions the fork does not ask
- Under which owner folder does the successor leaf live? If it is
  charted under a new overlay-rework owner, the old varhop owner
  (prompt-core and repo-sync merged, overlay-plugin archived) has no
  leaf left to trigger owner completion, so issues/open/varhop may sit
  in open forever. Owner completion moves the whole owner to
  issues/closed only when every leaf under it is merged
  (src/phase.ts:203-237 completeOwner). Charting the successor under
  varhop instead would let its merge close the original epic.
- Who performs the manual retirement move, the chart door at handoff or
  the operator, and is it recorded as a handoff step with a named owner?
  No verb does it.
- Which leaf lists Tamdoma/varhop#1 as a source so completion closes it?
  The failed leaf's `sources` is empty (state.yaml), so nothing closes
  the seed today.
- What happens to the failed leaf's herdr tab and panes (state.yaml tab
  wK:t7, pane A and B)? Recovery renames the tab back
  (src/phase.ts:173); retirement has no such step.

## Q2. If retired: where do the records go, and what happens to the installed copy?

### Pick
Two parts. Records: move the whole leaf folder into this chart as
evidence, for example issues/chart/overlay-rework/evidence/overlay-plugin/,
keeping every file including state.yaml. Installed copy: leave it
installed, enabled and bound to Super+Alt+P until the successor merges,
then the successor's landing updates it (`omarchy plugin update`, then
`omarchy-restart-shell`, the documented update path in the worktree
README).

Reason for the archive location: the valuable records are not in git.
In the leaf folder, only brief.md, design.md, readiness.yaml and
state.yaml are tracked; plan.md, review-A.md, review-B.md (67 KB) and
implementation/ (report plus probe and check logs) are untracked
(`git status` shows them as `??`, checked 2026-10-13). Deleting or
losing the folder is unrecoverable. The chart folder is tracked, is not
scanned as leaves (leaf scans cover issues/open and issues/closed only,
src/state.ts allLeaves), and puts the evidence next to the forks that
cite it. Total size is 376 KB, small enough to keep whole.

Reason for keeping the installed copy: it works today with known
workarounds (type full owner/repo, Ctrl+P back, Ctrl+, settings; seed
workaround note). The installed checkout is a clean git clone at the
same `0df6f48` as the branch (checked 2026-10-13), so a later
`omarchy plugin update` fast-forwards it. Update leaves the shell.json
entry, including the saved repo selection, byte-identical (proven live,
report.md update checks), while remove and disable delete the whole
entry, selection included (leaf design.md, settings-and-hotkey
Lifecycle). Keeping it also keeps ~/.cache/varhop and
~/.local/state/varhop as live data the successor's first run can use.

Cost: the operator keeps using the clunky build until the replacement
lands, and an installed old build is exactly the thing that can be
tested by mistake (see pitfalls). Cost of the archive: the records stop
being a leaf, so `akrogon status` and timing reports lose the failure
from view; the chart evidence folder is the only pointer.

### Rejected options
- Leave the records in issues/open/varhop/overlay-plugin. Then the slug
  stays taken, so the successor cannot adopt the branch and must use a
  different slug with a manual code transplant. Worse, owner completion
  requires every leaf under varhop to be merged (completeOwner above),
  so the failed leaf pins the whole varhop epic in open permanently and
  `akrogon status` prints the Failed line forever.
- Move the records to issues/closed/varhop/overlay-plugin by hand. Two
  traps: closed is still leaf-scanned, so the duplicate-slug throw
  still blocks a same-slug successor; and completeOwner renames the
  whole owner folder to issues/closed/varhop and throws if that
  destination already exists (src/phase.ts:211-213). A hand-made
  issues/closed/varhop poisons the day prompt-core and repo-sync's
  owner would complete.
- Park the leaf. `park` moves the whole issues/open/varhop folder,
  merged leaves included, and refuses a leaf with a tab or worktree
  recorded (merged map, akrogon facts). It cannot isolate this leaf.
- Delete the records. Untracked in git (above), so deletion destroys
  the review history, the probe logs behind OA1-OA4, and the only record
  of which live outcomes were already proven. The successor would
  re-prove or re-discover them.
- Uninstall the desktop copy now (`omarchy plugin remove`). Deletes the
  shell.json entry with the saved repo selection (design lifecycle
  above), turns Super+Alt+P into a silent no-op, and still leaves
  ~/.cache/varhop, ~/.local/state/varhop and the bind line behind as
  hand-cleanup (worktree README, Removal). Nothing is gained: the
  successor's live proofs must install a build anyway, and the operator
  loses working prompt access in the gap.
- Disable instead of remove. Same entry wipe as remove, so same
  selection loss, with a disabled plugin still on disk. No advantage
  over either neighbour.

### Evidence
- better-than-training · git and filesystem, 2026-10-13 ·
  `git ls-files` and `git status` on the leaf folder (tracked vs
  untracked split above); folder is 376 KB. Changed the records answer
  from "git keeps them" to "move, never delete".
- better-than-training · akrogon source, 2026-10-13 ·
  src/phase.ts:203-237 (completeOwner: all-merged check, closed
  destination-exists throw), src/state.ts allLeaves (open plus closed
  scan, duplicate slug throw). Rules out both staying in open and a
  hand-move to closed.
- better-than-training · live desktop inspection, 2026-10-13 ·
  `omarchy plugin list` shows ivan.varhop enabled; installed checkout
  `git log` head is `0df6f48`, worktree clean; bind at
  ~/.config/hypr/bindings.lua:12; ~/.cache/varhop and
  ~/.local/state/varhop present. Supports: update-later is a clean
  fast-forward, and the copy is in daily-use shape.
- better-than-training · leaf files, 2026-10-13 · report.md (plugin
  update left the shell.json entry byte-identical, twice; remove left
  only README-listed paths) and design.md (disable and remove delete
  the whole shell.json entry). Supports: keep installed preserves the
  selection, removal does not.
- operator · INTAKE.md seed, 2026-10-13 · the operator installed this
  build and live-tested it, so the desktop copy is in use, not a test
  leftover.

### Pitfalls and what removes each
- Stale build tested as if new: the running shell executes what it
  loaded until restarted, and `plugin add` clones a backup path, not
  the worktree (report.md addendum caveat). Removed by a done-criterion
  in the successor leaf: every live run starts by reading the deployed
  revision (`git -C ~/.config/omarchy/plugins/ivan.varhop rev-parse
  HEAD`) and restarts the shell after any update.
- Successor's lifecycle proof removes the plugin and nobody puts it
  back (old brief criterion 10 ends at remove). Removed by a
  done-criterion naming the end state: plugin installed and enabled at
  the merged head, selection intact, Super+Alt+P summoning it.
- Archived state.yaml mistaken for a live leaf later. Removed by the
  archive path itself: under issues/chart/, outside both scanned areas,
  verified by a clean `akrogon status` after the move (same step as Q1).
- Operator's live data lost in cleanup zeal: ~/.cache/varhop library
  and usage state are the operator's, created by real use since the
  leaf's own cleanup passed. Removed by a binding line in the
  successor brief: test fixtures it creates are recorded and deleted,
  pre-existing cache and state are not fixtures.
- Nothing removes this cost of keeping the install: until the
  replacement lands, the bound hotkey opens an editor the operator has
  already rejected as clunky.

### Questions the fork does not ask
- Should the archive keep implementation/ check logs (13 near-identical
  run logs) or only the report and probe logs? Size says keep all
  (376 KB), but nobody has said the logs are evidence worth tracking.
- When the successor merges and the desktop copy updates, who runs the
  update and shell restart, the merge leaf or the operator? The leaf
  can run both (old leaf did), but the running desktop belongs to the
  operator's session.
- If the proof-bar fork later drops the overlay to a post-merge
  checklist, does the installed copy get updated at merge or only after
  the operator passes those checks?
