# Proof-bar fork notes, slot C (blind), 2026-10-13

## Q1. Where do OA2, OA3 and OA4 sit: merge gate, post-merge checklist, or machinery first?

### Pick
Split by item. OA2 (exact cursor and selection resume) and OA3 (physical
Super+V and Super+C over browser and terminal) move to a one-time
post-merge operator checklist, with their behavior proven before merge at
component level. OA4 does not move and does not need the operator: Q3
removes its cause, so it stays an agent done-criterion.

Reasons. Precedent is exact: middle-click paste, dead-key composition and
IME preedit are already post-merge operator checks because they are not
agent-deliverable here (variable-editing handoff amendment 4a;
proofs-overlay.md rows 16-17). OA2 and OA3 failed for the same reason
class, input delivery to a layer surface, not for a code reason: arrows
sent by `hl.dsp.send_key_state` produced no cursor movement, and
synthetic Ctrl+V produced no insertion while Ctrl+C through the identical
APIs exported fine (archive report.md, F15 final round). The behaviors
underneath are component-provable under the real Wayland runner: the old
suite already proves Ctrl+Shift+V paste lands in a value, and draft
capture holds cursor and selection as plain data that a component test
can set, hide, restore and read back (worktree qml/EditorBody.qml
captureDraft and openPrompt restore; proofs-overlay.md row 16). The new
editor (F5) must re-earn those component proofs anyway, so the checklist
items test the redesigned editor once, on the installed merged build,
which is also the build the operator actually uses. The checklist runs
under the disposal end state (installed, enabled at merged head), and a
physical failure is recorded as a product defect seed, not an environment
excuse (the warning in archive review-B.md OA3 stands).

Cost: merge can land while physical paste or exact selection resume is
broken in the real compositor path even though components pass. That risk
is real and bounded to two interactions, found in one short physical
session. Nothing in this pick removes it.

### Rejected options
- Keep all three as merge-blocking operator done-criteria. That is the
  arrangement that just killed a leaf whose code passed: failed at
  check.fix after 4 fix rounds with no open product defect (disposal
  Findings). It also requires the operator's hands inside the check
  loop, on a moving build, once per redesign of the editor.
- Prerequisite machinery first, meaning install ydotool through
  `omarchy-dev-install-ydoo`. Three problems. It is itself an operator
  action: pkexec, adding the user to the input group, a persistent udev
  rule and a user service (read the script, /usr/share/omarchy/bin/
  omarchy-dev-install-ydoo:13-50), and ydotool is not installed today.
  Its pointer half is the same uinput mechanism that already failed
  here: a python-evdev uinput mouse focused a regular window but five
  attempts fired no layer-surface MouseArea (archive report.md:191-194),
  so paying for the install buys a nicer CLI over a device class already
  shown not to reach the overlay [unproven that ydotool's absolute
  positioning differs]. Its keyboard half needs no install at all:
  python-evdev is present and /dev/uinput already grants this user
  read-write today (ACL checked 2026-10-13), yet no evdev *keyboard*
  attempt is recorded anywhere in the archived report or reviews, only
  an evdev mouse. Buying machinery before testing the free keyboard
  route is the wrong order. A standing input-injection daemon also
  widens machine trust past this one proof.
- Machinery as an unconditional prerequisite leaf (own work item).
  Same objections, plus it delays every other fork on a maybe: if the
  evdev keyboard route fails on layer surfaces too, the chart is back
  at this fork having spent the prerequisite.

### Evidence
- operator · issues/chart/varhop/forks/variable-editing.md handoff
  amendment (operator 4a) and forks/disposal.md Taken, read 2026-10-13 ·
  physical-only checks already have a post-merge home, and the
  successor's final state is installed at merged head. Gave OA2 and OA3
  a place to land that is not the merge gate.
- better-than-training · archive/overlay-plugin/implementation/report.md
  F15 rounds and archive review-B.md OA1-OA4, read 2026-10-13 · arrows
  and synthetic paste not deliverable, Ctrl+C live-proven, evdev used
  only as a mouse (report.md:191), no evdev keyboard attempt recorded.
  Changed the machinery assessment: the untried route is free.
- better-than-training · /usr/share/omarchy/bin/omarchy-dev-install-ydoo,
  read 2026-10-13 · requires sudo marker, pkexec usermod and udev rule
  write, starts ydotool.service. ydotool, wlrctl and dotool absent;
  /dev/uinput exists with an ivan ACL; python-evdev imports. Supports
  probe-before-install.
- better-than-training · issues/chart/varhop/proofs-overlay.md rows
  16-17, read 2026-10-13 · qmltestrunner on Wayland pastes from the real
  clipboard and drives items directly, so component proofs are not
  mocks of the input path.
- better-than-training · `hyprctl devices`, 2026-10-13 · a physical
  mouse (Logitech MX Master 3S) is present now; the archived OA4 ran
  with none. Only makes the operator checklist easier, changes nothing
  for the agent.

### Pitfalls and what removes each
- The untried evdev keyboard route might make OA2 and OA3 fully
  agent-provable live, which would be better than a checklist. Removed
  by a named probe, pending until done: under the successor's readiness
  grant, create a uinput keyboard, send Left, Shift+Left and Ctrl+V to
  the focused overlay, record whether cursor moves, selection forms and
  text inserts. If it works, OA2 and OA3 promote back to agent
  done-criteria in the successor brief; if not, the checklist stands.
  This probe needs an operator grant because it types into the live
  desktop, so it is not a chart-time read-only step.
- Checklist with no teeth: merged, updated, never run. Removed by a
  done-criterion on the successor leaf's completion notes (the pattern
  the old design already used for its operator checks) and a recorded
  result: pass noted on the chart, fail filed as a seed against the
  merged build.
- Component proof mistaken for the full criterion. Removed by wording
  in the successor brief: component cases prove behavior, the checklist
  proves the physical path, and the criterion-to-evidence table
  (disposal carry) keeps the two in separate rows.
- OA4 quietly reappears through some other mouse-only control added by
  the visible-controls fork. Removed by Q3 as a binding rule, checked
  in review against every MouseArea in the views.

### Questions the fork does not ask
- Who owns the evdev-keyboard probe, the chart door before handoff or
  the successor as first task? Its result changes the successor's
  done-criteria, so before handoff is cleaner, but it needs a grant the
  chart does not currently name.
- If the checklist fails after merge, what is the response: leave the
  updated install in place and fix forward, or roll the desktop copy
  back? Disposal Taken updates at landing, before any checklist result.
- Is the operator checklist one combined list with the three older
  items (middle-click, dead key, IME), run once on the new editor? The
  older three were written against the stacked editor and need
  rewording for the inline one.

## Q2. OA1 second repo: which one, or off the gate?

### Pick
Use `Tamdoma/varhop-prompts-b` and keep OA1 on the merge gate as an
agent done-criterion, provided Q3 makes the switch confirmation
keyboard-reachable.

Reason: the repo already exists and was plainly made for this check. It
is private, id 1416586635, created 2026-10-13, with
`prompts/testing/second-repo.md` in two commits (`gh api
repos/Tamdoma/varhop-prompts-b` and its contents, read 2026-10-13). The
old blocker was never GitHub access, only that the readiness grant
named one repo (archive review-B.md OA1: no access-denied response was
observed). Naming varhop-prompts-b in the successor's readiness as a
read-only target with retention terms closes OA1 with words, no
creation and no operator action. The behavior at stake is worth a gate:
a successful switch discards the draft (locked, settings-and-hotkey),
so the success path is the data-loss-shaped one, and it is the only
repo-identity outcome never proven live.

Cost: the proof runs against the operator's real selection and cache.
The sequence must switch to B, verify draft discard and the new library,
then switch back to `Tamdoma/varhop-prompts` and end with the selection
intact (disposal end state). It also creates
`usage-1416586635.json` if a copy happens while on B, which the brief
must call a fixture or a keeper.

### Rejected options
- Create a fresh second repo for the successor. Pointless: one exists,
  purpose-built. Creation is also a GitHub write under the operator's
  account, outside a read-only grant.
- Use any other existing repo the login can read (for example
  Tamdoma/varhop itself). The switch would import a repo with no
  prompts/ layout, proving the no-prompts state, not a successful
  library switch with draft discard. B has a real prompt, so success is
  observable in search.
- Move OA1 off the gate to the operator checklist. Defensible only if
  Q3 fails (see pitfalls). As a default it wastes a now-cheap proof:
  unlike OA2 and OA3, nothing physical blocks the agent here, only a
  grant line and one confirm control.
- Keep OA1 on the gate with no repo named, "operator to supply".
  That is how it blocked the last leaf. The repo is known today; name
  it.

### Evidence
- better-than-training · `gh repo list Tamdoma`, `gh api
  repos/Tamdoma/varhop-prompts-b` and contents, 2026-10-13 · repo
  exists, private, id 1416586635, created today, holds
  prompts/testing/second-repo.md. Settled "which repo" by inspection.
- better-than-training · archive review-B.md OA1 and report.md OA1
  lines, read 2026-10-13 · blocker recorded as grant scope naming only
  Tamdoma/varhop-prompts (id 1416196860), identity gh login ivanjuras
  (6634086), one account reads both repos.
- better-than-training · archive report.md 7c evidence · the failed
  switch kept the draft live, but the success confirm was driven
  through an injected debug key because the Import button is mouse-only,
  and the debug key was reverted. Ties OA1's gate status to Q3.
- better-than-training · bin/varhop-sync on main (worktree copy) ·
  sync hardcodes `https://github.com/<owner/repo>.git` and `gh api
  repos/<arg>`, so no local fake can stand in for a second GitHub repo.

### Pitfalls and what removes each
- The confirm step is a MouseArea today, so OA1 is secretly OA4-class.
  Removed by Q3: the reconfirm and import actions get a keyboard path,
  and the successor brief states OA1 is proven through it, with no
  debug keys in shipped code (the old leaf's injected-key run is the
  anti-pattern).
- Proof leaves the desktop on repo B. Removed by the switch-back step
  and the disposal end state: selection reads Tamdoma/varhop-prompts,
  library restored by a final pull, both verified by reading shell.json
  and library.json back.
- Someone deletes or edits varhop-prompts-b between chart and proof.
  Removed by retention terms in the successor readiness (named target,
  read-only, retained), same treatment the starter repo had.
- B's single prompt is too thin to catch a wrong-library swap (for
  example stale A rows surviving). Removed by the done-criterion
  comparing row count and the B prompt's title after switch, not just
  the selection entry.

### Questions the fork does not ask
- Who created varhop-prompts-b and under what retention expectation?
  It appeared during the failed leaf's lifetime. If the operator made
  it as a throwaway, naming it as a retained fixture changes its fate.
- Does reset-usage isolation (brief 8) also run against B's usage file
  in the same session? It needs a second repo's usage file to exist,
  which OA1's run creates only if a copy happens on B. One combined
  live sequence could serve both criteria.

## Q3. Must every overlay control also work from the keyboard?

### Pick
Yes, as a binding rule on the successor: every action a mouse can take
must also be reachable and activatable by keyboard alone, with Tab plus
Enter or Space for controls and selection plus Enter for rows. Mouse
stays, as the second path, never the only one.

Reason: today the mouse-only actions are exactly the settings actions.
Search rows, the resume row, editor mirrors and scrim-hide all have
locked keys already (Enter, Ctrl+Shift+P, Tab, Esc). The gap is
SettingsBody: repo rows, Sync now, confirm-reimport, copy-bind and Reset
usage are bare MouseAreas (worktree qml/SettingsBody.qml:179, :233,
:248, :362, :386), and one of them (reset) manufactured OA4 while
another (confirm) forced a shipped-then-reverted debug key during OA1
proof. This is also a keyboard-first product: every locked interaction
in the chart is a chord or a field, so keyboard reachability is
consistency, not an accessibility extra. Tab and Enter are the right
substrate for the agent's live path too: Return, Tab, letters, Esc and
Ctrl+C were all delivered live in the old leaf's runs, while arrow keys
were not (archive report.md live evidence and OA2). So the rule is
stated on Tab and Enter, with arrows allowed as a bonus where a list
wants them.

Cost: focus becomes visible state that needs theme treatment (a focus
ring from the same tokens the look fork picks), and fields that grab
focus on sight (worktree qml/SearchBody.qml and SettingsBody.qml fields
call forceActiveFocus on completion and visibility) will fight a Tab
chain until focus ownership is designed per view. Test surface grows:
each control gets a key path and a mouse path case.

### Rejected options
- Status quo: buttons as MouseAreas, keys only where originally
  locked. Keeps OA4 permanently, blocks OA1's confirm, and the
  visible-controls fork would add F6 and F7 buttons in the same
  unprovable shape.
- Chords for every action instead of focusable controls. No focus ring
  work, but each new chord must clear the locked key map (exact
  modifiers, Ctrl+R inert inside picker fields, editor Ctrl+C always
  exports), chords are invisible unless labeled, and a labeled chord on
  a button the operator cannot Tab to repeats the F6 and F7
  discoverability failure in reverse.
- One global Tab chain that also runs through the editor's values as
  ordinary focus stops among buttons. Conflicts with the locked editor
  meaning of Tab (next unique name, wrap) and would let Tab escape the
  prompt into chrome mid-edit. The editor keeps its own Tab; chrome in
  search and settings takes the chain.
- Keyboard reachability only for Reset usage (the OA4 instance).
  Cheapest today, leaves repo rows, Sync now and confirm mouse-only,
  so the next mouse-only proof is a new OA item. The class is the
  problem, not the instance.

### Evidence
- better-than-training · worktree qml/SettingsBody.qml, read
  2026-10-13 · MouseArea-only actions at :179, :233, :248, :362, :386;
  no Button, no focusable control in any view (grep of the three view
  files). SearchBody and EditorBody MouseAreas all duplicate existing
  keys.
- better-than-training · archive report.md, read 2026-10-13 · OA4
  section (reset reachable only through its MouseArea, no chord, no
  focusable widget) and 7c (confirm driven by an injected debug key,
  reverted after). Two separate proofs were bent by the same gap.
- better-than-training · archive report.md live rounds,
  proofs-overlay.md rows 5 and 13 · typing, Return, Esc and Ctrl chords
  reach the focused overlay live; arrows did not move the editor cursor
  (OA2). Sets Tab and Enter as the provable substrate.
- operator · locked keys in issues/chart/varhop/forks/
  settings-and-hotkey.md and copy-and-close.md, read 2026-10-13 · the
  product's interactions are already keyboard-defined; settings being
  mouse-only is the outlier.

### Pitfalls and what removes each
- Keyboard-reachable on paper, agent-unprovable live because Tab
  delivery to the layer misbehaves. Removed by proving each control at
  component level with keyClick (runner proven, proofs row 16) and
  keeping one live smoke that Tabs to a settings control and activates
  it; if live Tab delivery fails, that is a defect found, not a proof
  skipped.
- Focus stealing: a field re-grabs focus on visibility and the Tab
  chain never starts. Removed by a done-criterion per view: from first
  focus, Tab visits every control and returns, asserted by activeFocus
  in the component test.
- Enter in a text field triggers a focused button instead of the
  field's own locked action (repo field Enter validates, search Enter
  opens). Removed by the rule's ordering: fields handle their keys
  first, as the current Keys.BeforeItem handlers do, and activation
  keys act only when a control holds focus.
- Visible-controls fork designs back and settings buttons as
  MouseAreas out of habit. Removed by carrying this fork's Taken line
  into that fork's carries, so its options are focusable controls from
  the start.

### Questions the fork does not ask
- Does "every control" include hover-only affordances and the scrim
  click-to-hide, whose key equivalents already exist (Esc)? A scope
  line (actions with no existing key must gain one; actions with a
  locked key are compliant) would stop gold-plating.
- Should activation keys be Enter, Space, or both per control kind,
  and does Space in particular collide anywhere (it types a space in
  fields, so control focus must be unambiguous)?
- The picker fork will define filtered-row keyboard selection. If it
  picks arrows, its live proof inherits the unproven arrow delivery;
  should this fork bind it to Tab and Enter now?
