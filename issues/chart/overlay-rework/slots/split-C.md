# Split fork notes, slot C (blind), 2026-10-13

## S1. How many leaves, grouped how?

### Pick
Two leaves. L1 `overlay-plugin`, the successor: adopt the branch at
0df6f48 and land it on main behavior-unchanged, carrying the
criterion-to-evidence table (disposal carry), a green configured check,
an install-and-summon live smoke, a committed evdev-keyboard test helper
(S3), and the installed clone repointed at a main-tracking source when
it merges. L2 `overlay-rework`: all five taken forks (editor, look,
picker, controls, proof-bar's final-build criteria OA1, OA2, OA3) as
internal waves, closing Tamdoma/varhop#1.

The Drain test is whether outcomes are independently checkable. On main
today there is no plugin at all: the manifest, QML and tests exist only
on the unmerged branch. So no rework leaf branched from main can install,
summon, or component-test anything until 0df6f48 lands. That makes the
base an actual dependency, not file overlap. L1 exists to remove it.
After L1, the remaining forks are independently checkable in principle,
but they share one live surface and one final build: OA1 needs the new
picker's confirmation path, OA2 and OA3 test the new editor under the new
look and header, and every live run serializes on the operator's one
shell, keyboard and clipboard (old leaf standing design). Parallel
branches would mostly parallelize typing, not proof, and each would
re-point the installed clone at its own worktree. Internal waves inside
L2 get the same separation with one lifecycle.

Cost: L2 is a large leaf. Bounded by the editor prototype already
passing 23/23 plus a live run, and by L1 having already re-verified the
adopted code, so L2's review reads only rework diff, not 3300 inherited
lines.

### Rejected options
- One leaf total (successor does base plus all rework). Saves one
  lifecycle, mixes adopted-and-proven code with new code in one review,
  and one bad fork's fix rounds block the merged prerequisites from
  reaching main. The old leaf's 4 fix rounds are the price record for
  that shape.
- Four or five parallel rework leaves after L1 (editor, look, picker,
  controls, close-out). Each pays plan, review and merge overhead; live
  sessions still serialize on one desktop; and no parallel leaf ever
  sees the integrated final build that proof-bar's OA1-OA3 name, forcing
  the close-out leaf anyway. Five lifecycles for one operator's plugin.
- Parallel leaves all based directly on 0df6f48 (door pre-creates each
  slug's branch at that head). Possible by the same adoption rule, but
  every leaf then merges the same 33-commit base, later merges replay it
  over a changed main, and only one can own the installed copy's origin
  at a time. The dependency is hidden, not removed.

### Evidence
- better-than-training · git inspection, 2026-10-13 · branch
  overlay-plugin at 0df6f48 is 33 ahead, 0 behind main; main has no
  manifest.json or QML (map-merged facts). Installed clone origin is
  file:///home/ivan/.akrogon/worktrees/varhop/overlay-plugin, the
  adopted worktree.
- better-than-training · CHART.md Forks taken · OA1-OA3 are criteria "on
  the final build", which presupposes one leaf that owns a final build.
- operator · skill Drain rule (SKILL.md:45) · only an actual dependency
  orders work. Substrate absence on main is one; shared files are not.

### Pitfalls and what removes each
- L1 ballooning into re-proving the old brief. Removed by L1's brief
  excluding F1-F7 and OA2/OA3 by name (owned by L2), with the evidence
  table marking which old proofs carry, which L2 invalidates.
- L1 merging breaks the installed clone (its origin is the successor's
  worktree, which reconcile removes after merge). Removed by an L1
  done-criterion: end state installed and enabled from a main clone,
  `omarchy plugin list` clean, selection intact (disposal end state).
- L2's internal waves re-serializing everything anyway. Bounded:
  component work per view is independent; only live sessions queue.

### Questions the fork does not ask
- L2's slug: `overlay-rework` names the chart, not the outcome. Fine, or
  should it name the destination state so status lines read sensibly?
- If L1's check or smoke fails on code nobody touched, is L1 allowed
  minimal repairs, or does any product change push it into L2's scope?

## S2. Owner folder, order and blocked-by

### Pick
Both leaves under the existing owner, issues/open/varhop/, listed in its
ISSUE.md, with the seat block written there per CHART.md Handoff choices.
Order: L2 blocked-by L1 only. L1 blocked-by prompt-core and repo-sync
(both merged, satisfied) for an accurate graph. L2 lists
Tamdoma/varhop#1 in sources; L1 does not (it delivers none of the seed's
asks).

The old leaf folder was removed from this owner and ISSUE.md still links
overlay-plugin/brief.md, so the successor at the same slug restores a
live index instead of leaving a dangling line. Owner completion moves
varhop to issues/closed only when every leaf under it is merged
(completeOwner), so finishing this epic here is what closes the original
destination. A new overlay-rework owner would strand varhop in open with
two merged leaves and no leaf left to trigger completion.

### Rejected options
- New owner issues/open/overlay-rework/. Cleaner naming, strands the
  original epic and puts the seat block in a second index.
- L2 with no blocked-by, "based on the branch informally". akrogon would
  branch it from main, where the plugin does not exist; the first live
  criterion fails for a bookkeeping reason.
- L1 also listing the seed as a source. Completion of the owner closes
  sources; L1 alone must never be able to look like the seed delivered.

### Evidence
- better-than-training · issues/open/varhop/ISSUE.md and `akrogon
  status`, 2026-10-13 · prompt-core and repo-sync merged under varhop;
  no overlay-plugin leaf line; CHART Pending steps records the archive
  move and status check done.
- better-than-training · disposal Findings · slug reuse, branch adoption
  and successor under varhop were already the recorded route.

### Pitfalls and what removes each
- Successor created before the archive verified: duplicate slug held
  only while the old folder existed; already removed per CHART Pending
  steps, and handoff re-verifies with status.
- ISSUE.md seat block written after state.yaml: CHART Handoff choices
  already order it before; keep that order for both leaves.

### Questions the fork does not ask
- Should ISSUE.md's one-line purpose for overlay-plugin be rewritten for
  the successor's narrower landing scope, with rework's line carrying the
  destination wording?

## S3. Prerequisite machinery leaf or proof close-out leaf?

### Pick
Neither as its own leaf. The evdev uinput helper is committed by L1 as
test machinery (python-evdev sender under test/, proven by one
known-good key run and one deliberate wrong-target failure), because L1
is the leaf that makes things land on main. The final live sweep is
owned by L2, the last leaf, whose build is the final build by
construction. The post-merge operator checklist (physical paste, mouse
spot-check) is written into L2's completion notes per proof-bar Taken.

Machinery on the default branch is a real prerequisite for criteria that
cite it (skill Handoff rule), but the machinery here is a script the
chart already proved in throwaway form (proof-bar probe 2a, passed).
Promoting it inside L1 satisfies "present on main before L2's criteria
run" without a dedicated lifecycle for one file. A close-out leaf that
only runs proofs becomes a fix leaf the first time a proof fails, paying
a second lifecycle to own defects L2 would have owned directly.

### Rejected options
- Standalone machinery leaf first. A full plan-review-merge cycle to
  land a test script python-evdev already runs today, blocking L1 behind
  it for no product reason.
- Standalone close-out leaf after L2. Only needed if the rework were
  parallel leaves with no final-build owner (rejected in S1). Under the
  two-leaf split it duplicates L2's final criteria.
- Throwaway scripts per live run, never committed. What the failed leaf
  did; its evidence is prose about scripts nobody can rerun. L1
  committing the helper is the cheap fix.

### Evidence
- better-than-training · proof-bar Taken probe 2a result · the uinput
  keyboard route passed with no install, identity user ivan via
  /dev/uinput ACL; productizing it is transcription, not research.
- better-than-training · archive/overlay-plugin report and review-B ·
  live proof executed through one-off commands consumed most of four fix
  rounds; repeatability is the gap, not capability.

### Pitfalls and what removes each
- Helper committed but never exercised until L2's expensive live runs.
  Removed by L1's own smoke driving one key sequence into the summoned
  overlay and one deliberate failure (keys sent while hidden change
  nothing), the known-good plus deliberate-break pattern.
- L2's final sweep discovering a base-code defect (not rework).
  Still L2's to fix; the evidence table from L1 says why it was believed
  good, so the fix is scoped, not a reopening of L1.

### Questions the fork does not ask
- Does the helper belong under test/ (shipped in the plugin repo, hence
  in the installed clone) or in the leaf's implementation records? Test
  files ship to users of the plugin folder; a uinput sender is harmless
  but is the first non-product executable in the install.
