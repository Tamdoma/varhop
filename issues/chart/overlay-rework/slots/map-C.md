# Territory map, slot C (blind), varhop re-chart, 2026-10-13

Scope mapped: seed Tamdoma/varhop#1 items F1-F7, failed leaf `overlay-plugin`
OA1-OA4, and the operator's "removed" note. No repo file edited.
Paths below: worktree = `/home/ivan/.akrogon/worktrees/varhop/overlay-plugin`
(branch `overlay-plugin`, head `0df6f48`). Low-confidence items are marked [LC].

## 1. Where things stand

1. The failed leaf is not failed on a known code defect. `state.yaml` records
   phase failed at check.fix, cause blocked, fix_rounds 4, reason OA1-OA4
   (issues/open/varhop/overlay-plugin/state.yaml, failure block). The final
   B re-check asserts no new product defect and records the configured check
   at 77 pass, 0 fail on `0df6f48` (review-B.md, final evidence handoff).
2. The branch is 33 commits ahead of main and 0 behind (merge-base =
   main head `5cac0ae`). Diff vs main: 19 files, 3297 insertions, including
   all-new `Varhop.qml` (950 lines), `qml/*.qml`, `manifest.json`, tests, and
   latency edits inside merged-owned `lib/search.mjs` and `lib/import.mjs`
   (git diff --stat main...HEAD in the worktree). Main has prompt-core and
   repo-sync only, so dropping the branch drops the whole plugin, not a delta.
3. The plugin is live right now: `omarchy plugin list` shows `ivan.varhop`
   enabled, `~/.config/omarchy/plugins/ivan.varhop`, `~/.cache/varhop` and
   `~/.local/state/varhop` exist, and the bind line is at
   `~/.config/hypr/bindings.lua:12`. The leaf report's "Cleanup all PASS"
   state (implementation/report.md, final round) was undone by the
   operator's live test install. Any disposal that means "remove the plugin"
   must also uninstall this copy and choose what happens to cache, state
   and the bind line.
4. F5 (stacked fields) is structural, not a styling bug. The editor is a
   `Column` (worktree qml/EditorBody.qml:255) with a `Repeater` over
   segments (EditorBody.qml:259), one row per segment: prose `Text` at
   :272-281, the stop `TextArea` at :283-346, mirrors at :354-380. Every
   segment gets its own line by construction.
5. F1 is also structural. The repo list is a `Repeater` with
   `model: root.repos` (worktree qml/SettingsBody.qml:219-220) and the field
   only acts on Return (SettingsBody.qml:209-212). Nothing filters on text.
6. F7 is a missed lock, not a new request. settings-and-hotkey Taken says
   settings is "opened with Ctrl+, or a visible button"
   (issues/chart/varhop/forks/settings-and-hotkey.md, Settings). No button
   exists: views have no header or toolbar (worktree qml/SearchBody.qml:96-100
   starts the column with the query field; SettingsBody itself has buttons
   only for Sync now at :240-248 and Reset usage at :374-386).
7. Most review findings from the first review (B-F1 to B-F14, B-F16) were
   repaired across the 4 fix rounds (review-B.md, third review disposition).
   The remaining open item at failure was B-F15 live proof only. A restart
   from main discards those repairs and their regression tests, including
   the sync transaction order, draft ownership, per-name undo and clipboard
   preservation work.

## 2. Material forks

### D1. What "removed" means
- O1 Drop the plugin and the destination. Forecloses CHART destination.
  Removes the F1-F7 and OA1-OA4 problem class entirely. Leaves prompt-core
  and repo-sync merged on main with no consumer, plus a live installed
  plugin and bind line to remove by hand (README "Removal" in the worktree
  lists leftovers; the bind line is at bindings.lua:12). Later cost: any
  future prompt tool redoes the overlay proofs in proofs-overlay.md rows
  1-21 from scratch.
- O2 Drop only the failed leaf as a lifecycle unit, keep its branch as the
  code base for new leaf or leaves. Keeps 33 commits of repaired code.
  Risk: new leaves inherit a 950-line root (worktree Varhop.qml) whose
  proof bar already consumed 4 fix rounds.
- O3 Drop leaf and branch, re-chart a new overlay leaf from main. Clean
  brief and tests. Cost: re-implements sync wiring, draft, copier, usage
  and latency work, and re-proves everything live. This is the largest
  option, not the smallest.
- O4 Recover the same leaf (akrogon allows it, section 6). Only works if
  the F-items fit the existing brief. F1, F6, F7 plausibly fit F5 does not:
  brief criterion 5 only fixes behavior ("Tab walks unique names, values
  mirror", brief.md:45 in the leaf folder), and the frozen tests encode
  the stacked shape (section 3). Recovery into check.fix would only
  re-run OA proof for an editor the operator already rejected.
This fork must be answered first. Every split in section 7 assumes O2 or O4
unless stated.

### D2. Inline editor mechanism (F5)
The chart never locked a mechanism: variable-editing Taken ends "Editor
mechanism left to leaf design" (forks/variable-editing.md, Taken). Options:
- O1 Flow of pieces. Keep one `TextArea` per unique name, lay prose chunks
  and fields in a wrapping flow instead of a Column. Reuses per-name undo
  (EditorBody.qml:49-92), FieldKeys paste, draft capture (:192-204) and
  mirror logic. Breaks later where prompts are not prose: code fences,
  tables and hard newlines reflow, leading spaces collapse, a multiline
  value breaks the line it sits in, and empty fields need a fake width.
  The prompt looks approximately inline, not identical.
- O2 One flowing `TextEdit` for the whole prompt, values edited in place,
  prose protected by a key guard and an onTextChanged verifier. This was
  mechanism C in variable-editing Findings. True inline shape, true
  cursor. Costs: offsets shift as values change length, editing one
  occurrence must rewrite its mirrors inside the same document, Qt's
  native undo is document-wide (locked requirement is per-variable,
  brief.md criterion 5c), IME preedit text sits inside the guarded
  document, and per-range styling in a PlainText `TextEdit` is not
  available from QML, so telling a value apart from prose needs RichText,
  which fights criterion 9 (hostile strings render literally, brief.md:9).
  [LC] whether a C++ text object or `TextEdit` private API avoids this.
- O3 Read-only flowing text plus one floating editor for the active value.
  Prose and mirrors render as one `Text`; clicking or Tabbing opens a
  small field over the active token. Keeps copy rebuild and per-name
  state. Costs: hit-testing a token in wrapped text, positioning over
  multiline values, scroll tracking, and the field covering the words
  around it while typing.
- O4 Whole-body editable with tokens as stops. Simplest true inline text.
  Directly reopens locked Q1 "values only, prose fixed"
  (forks/variable-editing.md, Taken Q1) and Q4 "copy rebuilt from parsed
  source segments" (Taken Q4), because copy would read the edited
  document or need a re-parse that treats typed `{{OTHER}}` as a token.
O2 and O4 are not repairs, they are a new editor. O1 is a layout change
inside the existing editor.

### D3. Which locks F5 reopens (exact list)
F5 contradicts only the rendered shape. It reopens nothing in the chart by
itself, because the mechanism was left open. What it does reopen:
- Plan D5 of the failed leaf: "one TextEdit per unique name, remaining
  occurrences read-only mirrors" (plan.md, Decisions D5) as separately
  laid-out rows. This is a leaf plan decision, not a chart lock.
- The frozen component tests. `state.yaml` freezes `qml/tst_views.qml`,
  and that file finds fields by objectName `value<i>` and mirrors by
  `mirror<j>` (worktree qml/tst_views.qml:184-201, :376-411). Any inline
  shape that renames or merges those items breaks frozen tests and needs
  frozen citations or a new leaf with new tests.
- Conditional, only under D2-O2 or D2-O4: brief criteria 5b (typing in
  prose leaves prose unchanged), 5c (per-variable undo including the
  Delete reset), 5d (mirror click activates), 5f (exact cursor and
  selection resume) all change meaning. Their chart sources are
  variable-editing Taken Q1, Q3 and the Findings proof list. Under D2-O1
  or D2-O3 these locks stand and only need re-proof.
- Not reopened by F5: Q2 (one stop per unique name, wrap, first stop
  selected), Q4 grammar and rebuild (`lib/tokens.mjs:11-34`,
  `lib/rebuild.mjs:1-19` on main are untouched by any layout), Delete
  empty then unset, Enter is newline, unset copies as `{{NAME}}`.

### D4. Theme and font wiring (F2, F3)
Facts first. No text in any view sets `font.family`, and every size is a
hard-coded `font.pixelSize` between 10 and 16 (worktree
qml/SettingsBody.qml:122, :198, :230, :359; qml/SearchBody.qml:109, :200,
:208; qml/EditorBody.qml:279, :395). First-party overlays bind
`fontFamily: Style.font.menuFamily` and token sizes
(/usr/share/omarchy/shell/plugins/emojis/Emojis.qml:35, :253-254, :331-332;
Commons/Style.qml:323-335 defines the tokens).
Colors are a snapshot. The root builds one object from `Commons.Color`
(worktree Varhop.qml:63-71), then assigns it with plain `item.colors =
root.colors` (Varhop.qml:821, :863, :898), while sibling properties use
`Qt.binding` (Varhop.qml:819-820). Views fall back to hex (EditorBody.qml:31-34)
and those fallbacks equal the un-themed defaults in
/usr/share/omarchy/shell/Commons/Color.qml:20-24. The card and scrim are the
exception: direct bindings (Varhop.qml:761, :775). [LC] whether the root
object literal re-evaluates when `Commons.Color` finishes loading the theme
or when the theme switches, the view assignments would still be stale for
an already-loaded view. The seed did not verify which values render.
Options:
- O1 Root passes font family, sizes and colors as bound properties
  (`Qt.binding`) read from `Style.font` and `Commons.Color.menu`. Keeps the
  brief rule that views import no Quickshell module so `qmltestrunner`
  can load them (brief.md:5 in the leaf folder, plan D2). Note the root
  currently uses foundational `Commons.Color.foreground` (Varhop.qml:64)
  where first-party menu surfaces use `Commons.Color.menu.text`
  (Emojis.qml:28). In the current theme both are `#E8DFC9`
  (current/theme/colors.toml foreground, current/theme/shell.toml
  [menu] text), so this alone does not explain F3 today, but a theme can
  set them apart.
- O2 Views import `qs.Commons` themselves, like first-party code does in
  its root files (Emojis.qml:5-6). Fewer moving parts live, but
  `qmltestrunner` then needs the qs import path, and the frozen view
  tests were written for plain QtQuick components. This removes the
  component-test property the whole test design rests on.
Size sub-fork: at the operator's current settings the tokens barely differ
from the hard-coded sizes. `[font] base-size = 12` in both
~/.config/omarchy/shell.toml and the current theme shell.toml, giving
body 12, title 14, heading 16 (Style.qml:331-334). The editor already
renders at 14 and the query field at 16. So "use Style tokens" makes
sizes follow Omarchy but not bigger. F2 "too small" needs either larger
token choices per surface (heading where body is expected), a bigger
operator base-size (global, affects the whole shell), or the wrong-family
rendering is what actually reads as small. [LC] on the cause without a
screenshot measurement. Fixed pixel heights (search rows 44 at
SearchBody.qml:190, repo rows 26 at SettingsBody.qml:224, card 560x480 at
Varhop.qml:771-772) will clip whatever larger font is chosen until they
derive from font tokens the way first-party rows do (Clipboard.qml:40).

### D5. Transparency (F4)
The card already uses the same token as first-party menu cards:
`Commons.Color.menu.background` (worktree Varhop.qml:775;
Emojis.qml:27, Clipboard.qml:26). That token composes
`menu.background` with `menu.background-alpha`, fallback alpha 1.0
(Commons/Color.qml:101). The operator's current theme sets
`background-alpha = 1.0` in [menu] (current/theme/shell.toml), while
[launcher] is 0.95 and [lock] is 0.8. So an opaque card is what this theme
asks every [menu] surface to be. Options:
- O1 Accept the token. F4 closes as "matches Clipboard and Emojis". The
  operator can lower [menu] alpha in user shell.toml, which changes all
  menu surfaces, not only varhop.
- O2 Multiply varhop's own alpha on top of the token. Gives varhop-only
  transparency now. Breaks later: a theme that sets [menu] alpha 0.9 gets
  double-applied alpha, and varhop stops matching sibling overlays, which
  is the complaint in F3.
- O3 Use a different surface's tokens ([popups] or [launcher] has no
  `Commons.Color` object; grep finds no launcher object in Color.qml).
  Mislabels the surface for theme authors. [LC]
First prove what renders: a grim screenshot pixel sample of varhop next to
Emojis on the same theme decides whether F3 and F4 are one bug (snapshot
fallbacks) or two (token choice). Nothing in the seed verified rendered
values.

### D6. Picker filtering (F1)
No lock forbids filtering. sync-and-auth Taken requires a "/user/repos
picker plus a strictly validated typed owner/repo" (forks/sync-and-auth.md,
Findings binding line). Questions that change the outcome:
- Filter rule: plain substring, or the same folded matching as search?
  Repo names are ASCII, so folding buys little here, but two different
  filter feels in one plugin is its own cost.
- Enter semantics while filtered: select the top filtered row, or keep
  today's "exact typed owner/repo goes to `varhop-sync repo`"
  (SettingsBody.qml:209-212, Varhop.qml repoTyped handler)? The typed path
  is the only way to reach a repo missing from the list. The list comes
  from `/user/repos?per_page=100 --paginate` (bin/varhop-sync:86-89 on
  main) [LC] whether that covers org and collaborator repos the operator
  does not own; if it does not, hiding the typed path behind "no results"
  breaks first-run for those repos.
- Keyboard: rows today are mouse-only (`MouseArea` at
  SettingsBody.qml:233). Filtered lists invite Up, Down and Enter, none of
  which exist in the picker. Adding them is new key surface inside a view
  where Ctrl+R is locked inert (settings-and-hotkey Taken, Keys).
- Empty filter result must still show the typed path as available, or the
  operator reads it as "repo does not exist".

### D7. Visible navigation (F6, F7)
Locked behavior that a button must not contradict:
- Esc in the editor hides and keeps the draft. It is never "back"
  (forks/copy-and-close.md, Findings settled; Taken 1a). Editor code
  follows it: Esc emits hideRequested (EditorBody.qml:222-224), Ctrl+P
  emits findAnother (:225-227).
- Ctrl+P from the editor returns to the previous query and selection with
  the draft kept (settings-and-hotkey Taken, Keys; wired at
  Varhop.qml:871-883).
- Settings opens with Ctrl+, or a visible button (section 1, fact 6), and
  Esc returns to the view it came from.
So the fork is placement and labeling, not behavior:
- O1 One header row shared by all three views: back button (does exactly
  Ctrl+P in the editor, Esc-return in settings, hidden or disabled in
  search), settings button (does exactly Ctrl+,), plus key hints. One
  place to learn. Cost: views are separate Loaders destroyed on switch
  (Varhop.qml:817, :860, :896 `active: root.view === ...`), so the header
  belongs in the root card, not in a view, and the draft capture that
  Ctrl+, performs (Varhop.qml:802-803) must run for the button path too.
- O2 Per-view buttons. Settings button in search only, back button in the
  editor only. Less root surgery. Cost: two places to keep consistent,
  and settings reached from the editor still needs the capture at
  Varhop.qml:802-803.
- O3 Hint text only (footer listing Ctrl+P and Ctrl+,). Cheapest. Does
  not satisfy the visible-button lock for settings, and a hint is not a
  mouse target. Note mouse targets here have a proof cost: synthetic
  clicks do not reach layer surfaces on this host (report OA4 section),
  so every mouse-only control added is a control agents cannot prove.
  A focusable control that also takes Enter or Space is provable [LC].

### D8. The proof bar itself
This leaf died on proof, not code (fact 1). The brief requires roughly 40
live outcomes on the operator's one shell, keyboard and clipboard
(brief.md:1-10 in the leaf folder; plan.md proof map 1a-10). Four fix
rounds were mostly live-proof rounds. Before any new code, decide:
- O1 Keep the bar. Then OA1-OA4 are done-criteria and someone must do
  them physically, on the final build, per editor redesign. Expect the
  same failure mode if the operator is not scheduled for it.
- O2 Split the bar: agent-provable outcomes stay done-criteria,
  physical-only outcomes move to the post-merge operator check list.
  Precedent exists: middle-click, dead-key and IME preedit already moved
  that way (variable-editing Handoff amendment 4a, design.md operator
  check list). OA2 and OA3 are the same class as those three (arrows and
  synthetic paste do not reach layer surfaces, proofs-overlay.md rows
  16-17 and the final report).
- O3 Replace specific live proofs with component proofs plus one short
  live smoke (summon, search, open, type, copy, wl-paste compare). The
  component suite already covers paste chords, undo and copy failure
  under real Wayland (proofs-overlay.md row 16).
Whatever is chosen, search latency (brief 4g, p95 50 ms at 5000 prompts)
is agent-provable and was met only by editing prompt-core files from the
overlay leaf (plan D16a). A re-charted leaf set should say up front
whether overlay work may touch `lib/*.mjs` again.

## 3. Practitioner questions (QML, Quickshell, Omarchy plugin)

- Q1. Can a third-party plugin read `Style.font` and `Commons.Color.menu`
  tokens at root and bind them into Quickshell-free child views without
  the values going stale on a theme switch, given runtime theme switches
  push through shell IPC (Commons/Color.qml comment above colorsFile,
  "Startup load only. Runtime theme switches push the payload explicitly
  through shell IPC")? Does `shellValues` reassignment re-notify plain
  JS-object properties like the one at Varhop.qml:63-71?
- Q2. Is `qs.Commons` importable from plugin sub-files under `qml/`, or
  only from the entry file the shell loads? First-party plugins keep
  everything in one file (Emojis.qml). If sub-files can import it, can
  `qmltestrunner` be given the same import path so component tests stay
  possible?
- Q3. For inline editing: does Qt 6.12 `TextEdit` expose per-range
  character formatting from QML without RichText? If not, how do other
  Quickshell or QtQuick editors mark token ranges in plain text?
- Q4. In a `Flow` layout, how are hard newlines, leading indentation and
  code fences preserved? Prose segments today are whole strings between
  tokens (lib/tokens.mjs:11-34), so a flow needs word-level splitting in
  the view. Who owns that split, and does it change copy? (Copy is safe:
  rebuild runs from segments, EditorBody.qml:187-190.)
- Q5. OverlayWindow maps a fresh surface per open and gates content on
  scale readiness (/usr/share/omarchy/shell/Ui/OverlayWindow.qml:29-32).
  Does a larger card or a Flow editor change first-frame layout cost
  enough to matter for the key-to-frame budget?
- Q6. Qt 6.12 added a QtQuick `Color` type that shadows the palette
  singleton (design.md form-factor finding). Any new QML must keep
  `Commons.Color` qualified. Does the same shadowing affect `Style` now
  or in announced Qt versions? [LC]
- Q7. New plugin code reaches the running shell only via
  `omarchy-restart-shell` (proofs-overlay.md rows 14 and 19). What is the
  cheapest safe loop for visual iteration (fonts, wrapping) that does not
  require a full restart per screenshot, given `qmltestrunner` renders
  the same views off-shell?
- Q8. The report notes `omarchy plugin add` clones a backup path, not the
  worktree, so the deployed copy must be re-synced by hand after add and
  remove cycles (implementation/report.md, addendum 2 caveat). Is there
  an install route that tracks a branch worktree directly, given
  symlinks are rejected (proofs-overlay.md row 1)?

## 4. Lifetime pitfalls

- R1. Omarchy shell API drift. The plugin depends on `Commons.Color`
  token names, `Style.font` tokens, OverlayWindow, and
  `shell.updateEntryInline`. The Qt 6.12 `Color` shadowing already broke
  unqualified plugins once (design.md). Removed by: use only qualified
  first-party tokens, and keep `omarchy-plugin-validate` plus a summon
  smoke in the check.
- R2. Stale theme snapshot returns. Any plain assignment of theme values
  (Varhop.qml:821) freezes them per loaded view. Removed by: bind, never
  assign, every theme-derived property, and prove it by switching theme
  while the overlay is open.
- R3. Font scale clips fixed geometry. Card 560x480 (Varhop.qml:771-772),
  row heights 44 and 26, field heights 34 and 36 (SettingsBody.qml:192,
  SearchBody.qml:100). An operator base-size raise breaks layout.
  Removed by: derive heights and card size from `Style.font` and
  `Style.spacing`, as Clipboard.qml:40 does.
- R4. Editor shape vs arbitrary prompts. Bodies are arbitrary Markdown
  copied verbatim (repo-format). Any layout that reflows text will
  misrender some prompt. Removed only by a true single-text editor
  (D2-O2 or O4); a flow (D2-O1) keeps this risk permanently and needs a
  stated tolerance.
- R5. Test shape lock-in. Frozen tests address `value<i>` and
  `mirror<j>` items (tst_views.qml:184-201). Every future editor change
  pays for that addressing scheme. Removed by: test through signals and
  the values map, not the visual tree, in any new leaf.
- R6. Live proof depends on the operator's hands and one shell session.
  Proofs-overlay rows 13-17 and the final report show arrows, middle
  click, dead keys and synthetic layer clicks are not agent-deliverable.
  Removed by: D8-O2 or O3, and by making every mouse action also
  keyboard-reachable.
- R7. Search latency couples leaves. Meeting 50 ms at 5000 prompts
  required caches in `lib/search.mjs` and a body mask in
  `lib/import.mjs`, owned by merged prompt-core (plan D16a, diff stat in
  fact 2). Dropping the branch (D1-O3) silently drops that fix and the
  budget fails again at 2000 prompts (implementation/report.md latency
  repair section measured 115 ms before the fix).
- R8. Deployed copy drift. The installed plugin is a clone, not the
  worktree (Q8). A "removed" decision that only deletes the branch
  leaves a working old plugin installed and bound to Super+Alt+P.
  Removed by: an explicit uninstall or update step in whichever leaf
  closes this out.
- R9. Repo list growth. The picker renders every repo as a `Repeater`
  row (SettingsBody.qml:219-235) from a paginated `/user/repos`
  (bin/varhop-sync:87). Hundreds of repos were fine when unfiltered only
  because nobody scrolled. Filtering without a virtualized list still
  builds all delegates. Removed by: ListView, the same fix search
  needed (SearchBody.qml:153-156 comment).

## 5. Failed-leaf disposal, with akrogon evidence

What the command actually offers (source read at
/home/ivan/Work/infra/akrogon/src/, since `akrogon --help` only prints the
verb list at akrogon.ts:187):
- No abandon, remove or delete verb exists. Verbs: install, init, config,
  preflight, phase, next, pull, close, park, unpark, pause, unpause,
  sync, status, timing, run-check, base-run, guard (akrogon.ts:187).
- `close` closes a GitHub source issue with a "delivered by" comment
  (pull.ts:204-207); it does not close a leaf. This leaf's `sources` list
  is empty (state.yaml), and seed Tamdoma/varhop#1 is still open on
  GitHub. Closing #1 before delivery would be wrong.
- Recovery exists: from `failed`, every non-terminal phase is a legal
  next move (routing.ts:37-49), but a seat cannot do it. "Leaf is failed.
  A seat cannot resume it. Operator recovery omits --slot after the
  blocker is resolved." (phase.ts:351-353). X1 below is this path.
- `park` moves a whole issue folder from issues/open to issues/parked
  (park.ts:9-11). Here that folder is `varhop`, which also contains the
  merged prompt-core and repo-sync leaves (issues/open/varhop/ holds all
  three). Park also refuses an issue with a running leaf (park.ts:55-58),
  where running means a tab or worktree is recorded (park.ts:23-27).
  This leaf records both (state.yaml tab and worktree). So park cannot
  isolate overlay-plugin and cannot run until the worktree and tab go.
- A failed leaf's worktree is removed by reconcile when no live pane is
  inside it (reconcile.ts:306-317), which also clears the worktree field.
  [LC] the git branch itself is a normal branch (`overlay-plugin` in the
  repo) and survives worktree removal; nothing in the read source deletes
  branches.
- `next` on a picked failed leaf throws "needs phase recovery"
  (next.ts:738-748). Leaving it failed does not block unrelated new
  leaves: only leaves that name it in blocked-by would wait (turn.ts and
  park.ts stranded logic read blocked-by lists). New leaves blocked by
  prompt-core and repo-sync, both merged, are free to run.
Disposal options:
- X1 Recover in place. Operator runs `akrogon phase overlay-plugin
  <phase>` with no `--slot`. Sensible targets: check.fix (only finishes
  OA proof on the rejected editor, not recommended alone), implement or a
  plan phase if the leaf's brief and plan may be re-cut inside the leaf.
  Frozen tests stay frozen, so F5 work inside this leaf needs frozen
  citations for tst_views.qml changes. Cheapest in process, most
  constrained in scope.
- X2 Supersede. Leave the leaf failed as the record, chart new leaf or
  leaves blocked by prompt-core and repo-sync, and base their branch on
  `overlay-plugin` `0df6f48` (or cherry-pick from it) so the repairs in
  fact 7 are kept. The failed leaf then holds no future; its worktree
  will be reconciled away once no pane uses it. The new leaves get fresh
  briefs, fresh frozen tests and a proof bar set by D8.
- X3 Abandon fully (D1-O1 or O3). No akrogon verb does this. It is manual
  operator work: delete the branch and worktree by git, move or delete
  the leaf folder outside the tool's model [LC: whether a later `next`
  or `status` tolerates a hand-moved folder is unproven], uninstall the
  live plugin (fact 3), and decide the GitHub seed. Highest evidence
  loss: review-B.md and the report are inside the leaf folder.

## 6. Proposed split (assumes D1-O2, proof bar per D8-O2)

One leaf again is possible but repeats the shape that failed: the shared
resource (one shell, one clipboard) serializes live proof anyway (plan.md,
shared test resource note). Splitting by independent code surface:

- L1 Theme, fonts and navigation chrome. Bound Style and Color wiring
  (D4-O1), token-derived geometry (R3), header with back and settings
  buttons (D7-O1), transparency decision D5. Files: Varhop.qml card and
  header area, font and size lines in all three views. Covers F2, F3,
  F4, F6, F7. No editor internals, no settings logic.
- L2 Picker filter. Filtered, virtualized repo list in SettingsBody,
  typed path preserved (D6). Covers F1. No dependency on L1 code, but
  both touch SettingsBody.qml and Varhop.qml wiring, so parallel
  branches will conflict in those files [LC on conflict size]. Sequence
  L2 after L1, or accept a merge.
- L3 Inline editor. The D2 mechanism choice, EditorBody rewrite, new
  component tests addressed by values not visuals (R5). Covers F5.
  Depends on L1 for font tokens inside the editor, not for logic. This
  is the only leaf that can reopen chart locks (D3), so its brief must
  name the chosen D2 option.
- L4 Proof close-out, only if D8-O1 keeps the full bar. Runs the OA
  items on the merged result. Blocked by L1, L2, L3.
Parallel vs dependent: L1 and L3 are independent in logic and overlap
only on font lines inside EditorBody. L2 overlaps L1 in SettingsBody.
Under D1-O3 (restart from main) add L0, a straight re-land of
`overlay-plugin` `0df6f48` minus the editor layout, which is most of the
branch; at that point O3 has no advantage over X2.

OA items under changed done-criteria:
- OA1 (second repo): needed only while brief 7c and 8 require a real
  successful switch and reset isolation against a second repo's usage
  file. The blocker is the readiness grant naming one repo, not GitHub
  access (review-B.md OA1). Options that remove it: authorize any
  existing second repo read-only (operator words, no creation), or move
  7c success to post-merge operator check. A local fake is not available:
  bin/varhop-sync:144 hardcodes `https://github.com/$REPO_ARG.git`.
- OA2 (exact cursor and selection resume): invalidated by any D2 change,
  must be redone on the new editor or not at all. Under D2-O2 the draft
  cursor becomes a document offset, a different claim from the current
  per-field cursor (EditorBody.qml:192-204). Under D8-O2 it joins the
  existing post-merge physical list.
- OA3 (physical paste over browser and terminal): editor half
  invalidated by D2, search half survives. Component paste proof already
  exists under real Wayland (proofs-overlay.md row 16). Needed only if
  brief 6b stays a live done-criterion.
- OA4 (physical reset-button click): removable without lowering the bar.
  It exists because reset is a `MouseArea` only (SettingsBody.qml:374-386)
  and synthetic clicks do not reach layer surfaces. A keyboard-reachable
  reset (focusable control or a chord) makes brief 8 agent-provable
  [LC]. Same applies to repo rows and Sync now. L1 or L2 should carry
  this, since both add controls.

## Bottom line

D1 and D8 decide everything else. The code at `0df6f48` passed its tests
and most live outcomes; the leaf failed on four physical proofs, and the
seed then rejected the editor shape those proofs would have certified.
Re-proving OA1-OA4 on the stacked editor spends operator time on a design
already refused. The cheapest coherent route is X2 (keep the branch, new
leaf or leaves), D8-O2 (physical proofs become post-merge checks, as
middle-click and dead-key already are), L1 then L3, with L2 folded into
either. F3 and F4 need one rendered-pixel comparison against Emojis
before any theming leaf is briefed, because the card token already
matches first-party and the current theme asks [menu] to be opaque.
