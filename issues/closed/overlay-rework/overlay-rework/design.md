# Design: overlay-rework

## Binding decisions, verbatim

### picker (issues/chart/overlay-rework/forks/picker.md)
Operator 2026-10-13: `1a | 2a | 3a | 4a`.
- 1a: case- and accent-insensitive literal substring of the trimmed field on fullName. A to Z by lowercased fullName, never reordered by the query. After each text change, the highlight goes to the exact listed match if any, else the first match.
- 2a: no highlight until the operator types or presses an arrow. Enter on an empty field does nothing.
- 3a: with zero matches, a line says Enter looks up `owner/repo`. Enter runs the existing validated lookup (repoRe plus `varhop-sync repo`). The result applies only if the field still holds the submitted text. No synthetic lookup row.
- 4a: the picker is one keyboard control. Tab reaches the field, Up and Down (wrapping) and Enter reach every row, and a click uses the same `repoChosen` path. This amends proof-bar Q4 for list rows only.
- Binding (agreed, not asked):
  - a bounded ListView about 8 rows with the highlight kept in view
  - distinct loading, could-not-list and no-match lines, with the failure state taken from reposProc's exit, not list length
  - after a background refresh the highlight follows the repo ID, or clears if the repo is gone
  - a "current" marker on the selected repo
  - Esc clears a non-empty filter first

### look (issues/chart/overlay-rework/forks/look.md)
Operator 2026-10-13: `1a | 2a | 3a`.
- 1a: every text uses `Style.font.menuFamily` (alias binding) and Style.font tokens one step above today. Query, headings and editor body `heading`, titles and controls `title`, metadata and status `body`. Nothing essential below `body`. Heights derive from tokens. A component case at a larger base size shows no clipping.
- 2a: Emojis surface recipe. BorderSurface card with `menu.background` and `Border.surfaceSpec("menu","border",...)`, `Style.cornerRadius`, `menu.scrim`, `menu.text`, `menu.selected*`, `Style.spacing.*`, card `Style.space(560)` x `Style.space(480)` clamped by `Style.gapsOut`. muted, accent and urgent stay foundational. Colors and fonts are bound live, with no snapshot object. Done-criterion: under a contrasting test palette (menu.text differs from foreground), each open view adopts the new roles after a theme change. Adjacent pills get a paint-only inset.
- 3a: the card follows `menu.background` including its alpha. No varhop alpha code. A see-through look is the operator's own `[menu] background-alpha` in ~/.config/omarchy/shell.toml, outside the leaf. Successor proofs run at the theme value.
- Not taken: README blur, no_screen_share and no_anim layer-rule suggestions (C).

### editor (issues/chart/overlay-rework/forks/editor.md)
Operator 2026-10-13: `1b | 2a | 3a | 4a`.
- 1b: the prototype tests the guarded single TextEdit (M1) first, about 45 minutes. Pass needs prose fixed under typing, paste, right-click paste, right-click Undo, middle-click, selection across a boundary, Backspace and Delete at both edges, mirrors, per-name undo, Delete empty then unset, and cursor resume. IME preedit is recorded unproved (host has keyboard-hr only). A fail or timeout returns the mechanism to the operator with evidence, with no automatic switch to M2.
- 2a: highlight rectangles behind PlainText. Unset `{{NAME}}` muted, filled faint, empty a small paint-only marker, active strongest.
- 3a: clicking any occurrence edits it in place, mirrors update, Tab order stays by unique name.
- 4a: the door runs the prototype alone with the uinput keyboard and shows screenshots cropped to the test window only.
- Not answered: `effort yes` (CLAUDE_CODE_EFFORT_LEVEL in the machine harness template). Left unchanged.

### Prototype result (operator 1b, 4a), 2026-10-13
- What: scratch M1 editor, one Controls TextArea (PlainText, wrap) with edits allowed only inside the active occurrence, mirrors rewritten, per-name undo, painted highlight rectangles. tokens.mjs copied from the worktree at 0df6f48. Scratch code deleted after this record.
- Runtime: Qt 6.12.0, qmltestrunner offscreen for 23 scripted checks, `/usr/lib/qt6/bin/qml` on Hyprland 0.56.2 for the live run. Identity: user ivan, uinput device `varhop-probe-kbd` (keyboard plus buttons), cursor placed with `hyprctl dispatch 'hl.dsp.cursor.move(...)'`.
- Result: pass. 23 of 23 scripted checks passed:
  - first open selects the first `{{NAME}}`
  - typing mirrors to every occurrence
  - typing, Backspace and menu Delete across a prose boundary are rejected
  - paste inside a value is accepted, including multi-line text
  - paste and cut across a boundary are rejected
  - native undo is unreachable (`canUndo` stays false)
  - the cursor stays put when a mirror before it grows
  - per-name undo and redo work across Tab, Delete empties then unsets, and undo of the reset works
  - Enter inserts a newline in the value
  - Backspace on an unset value keeps it unset
  - typed `{{OTHER}}<i>` stays literal
  - a wrapped value paints one highlight per line
  - clicking the second occurrence edits it in place
  - an empty value is reachable by Tab
  - 50 tokens cost about 4 ms per key
  - draft restore keeps values, history and a reverse selection
- Live run with real input: typing, Tab, Shift+Tab and Ctrl+Z (sent as the key the hr layout maps to Z) worked. Ctrl+V with a two-line clipboard filled the value. Ctrl+Home then a letter was rejected. A selection across a boundary then a letter was rejected. A middle-click paste of primary `MID` on prose was rejected. The right-click menu shows Undo and Redo disabled. Screenshot: forks/editor-prototype.png (prototype window only).
- Binding for the leaf: `cursorPositionChanged` fires before the `text` property updates. So the guard must handle both signals through one deferred `Qt.callLater` sync that compares text to the expected display. Reading text inside the cursor handler re-selects stale ranges and corrupts typing (observed, then fixed). An active unset value stays wholly selected so typing replaces `{{NAME}}`. Activation uses inclusive bounds, so one-character and empty values are clickable.
- Cleanup: clipboard and primary selection saved before and restored after, verified byte-equal with `cmp`. Prototype window closed. Scratch folder removed.
- Limits:
  - IME preedit is unproved (host has keyboard-hr only).
  - A rejected edit may show for one frame before it is reverted. No flash was seen in stills, and this was not measured per frame.
  - Menu Cut, Paste and Delete were proved through the methods the menu actions call, not by clicking menu items.
  - Adjacent values (`{{A}}{{B}}`) render as touching pills, which is a look-fork concern.
  - This does not prove the final build. The proof-bar final-build criteria still apply.

### controls (issues/chart/overlay-rework/forks/controls.md)
Operator 2026-10-13: `1a | 2a | 3a | 4a`.
- 1a: Ctrl+Tab moves focus from the view body to the header in every view. In search and settings, plain Tab also reaches the header in the normal focus order. In the header, Tab and Shift+Tab move between visible buttons, and Enter, Return or Space presses one. Esc or Ctrl+Tab in the header returns focus to the body with caret, selection, active variable and picker highlight untouched, and does not hide. The editor's variable Tab cycle is unchanged. The live keyboard proof must show Ctrl+Tab reaching the overlay. Hyprland binds Ctrl+Tab only inside the capture submap (/usr/share/omarchy/default/hypr/bindings/utilities.lua:64).
- 2a: inside settings the header's right side is empty. There is no Settings button there, and the title says "Settings".
- 3a: the settings left button says "Back" when a return view exists and "Close" when the existing backRequested branch hides (no cameFrom and no selection, Varhop.qml:923-932). Its label follows that same condition.
- 4a: a middle title names the view: "Prompts" in search, the prompt title in the editor (PlainText, elided first when space is short), "Settings" in settings. The editor button says "Back".
- Locked from the Findings: one fixed header row at the top of the card, outside the view loaders. Text buttons show their shortcut in muted text ("Back  Ctrl+P", "Settings  Ctrl+,"). A glyph is optional and never alone. Search has no Back. Editor Back runs the Ctrl+P findAnother path with the draft kept. Settings in search and editor runs the Ctrl+, path, capturing the draft first. Esc in the body keeps its current meaning. One root function per action serves click, focused-button Enter and shortcut, and a component case compares their results, including the settings-to-editor round trip and the library-mismatch route. Nothing gives a header button the initial focus. A view change driven by the root returns focus to the new view's body. Header stays navigation only, with no Sync button.
- Not decided here, implementer's choice within the look tokens: whether to use qs.Ui Button at the root (C's suggestion) or a plain button with the same focus tokens.

### proof-bar (issues/chart/overlay-rework/forks/proof-bar.md)
2026-10-13 operator: `1a | 2a | 3a | 4a`
- Q1 1a: OA2 (exact cursor/selection resume) and OA3 (physical Super+V/Super+C over browser and terminal) move to a one-time post-merge operator checklist on the installed merged build; their behavior is proven before merge at component level; a physical failure is filed as a seed. Foreclosed: pre-merge attended session (B's preference, recorded in Findings).
- Q2 2a: door runs the uinput keyboard probe now (Left, Shift+Left, Ctrl+V into the focused overlay); a pass promotes OA2/OA3 back to agent criteria on the final build. Result recorded below.
- Q3 3a: Tamdoma/varhop-prompts-b (id 1416586635) is a read-only, retained target in the successor grant until the successor merges; switch-success with draft discard stays an agent criterion; run ends switched back to Tamdoma/varhop-prompts with selection intact.
- Q4 4a: every mouse action is also reachable by Tab and activated by Enter (arrows optional), through the same action path; the editor's Tab cycle over variables is unchanged; reset isolation becomes an agent criterion via the keyboard route; a mouse spot-check rides the post-merge checklist.

### Probe 2a result (2026-10-13 10:25 CEST)
- Command: python3 + python-evdev `UInput` keyboard named `varhop-probe-kbd` (keys A B C X V LEFT LEFTSHIFT LEFTCTRL ESC), 1.5 s registration wait; `printf VHPROBE | wl-copy`; `omarchy-shell shell summon ivan.varhop`; sent a, b, c, Left, Shift+Left, x, Ctrl+V; `grim` screenshot; sent Esc, Esc.
- Identity: local user ivan, /dev/uinput via ACL `user:ivan:rw-`; no install, no sudo. Versions: Quickshell 0.3.2, Qt 6.12.0, plugin ivan.varhop at 0df6f48 (installed copy).
- Result: the search field read `axVHPROBEc`: Left moved the caret, Shift+Left selected `b`, `x` replaced the selection, Ctrl+V inserted the clipboard text. After Esc, Esc, `hyprctl layers` showed no varhop layer (hidden). PASS: a uinput keyboard delivers arrows, shift-selection and paste to the overlay layer surface on this host.
- Cleanup: virtual device closed; screenshot deleted (it showed other windows); clipboard cleared with `wl-copy --clear`. The pre-probe clipboard held no image/png at probe time (the 10:22 Quickshell crash had already emptied it), so there was nothing to restore. Deviation: the script restored an empty image/png offer before the clear.
- Limits: tested the search field of the current build, not the redesigned editor; did not test hide/summon cursor restore, Super+V/Super+C binds, or pointer clicks.
- Effect on Taken (operator 2a): OA2 (exact resume) and OA3 (Super+V/Super+C through the Hyprland binds) return to agent done-criteria on the final build, driven by a uinput keyboard. A physical-paste and mouse spot-check stays on the post-merge checklist.

### Handoff proofs (2026-10-13 12:01 CEST)
- Second repo read. Command: `env -u GH_TOKEN -u GITHUB_TOKEN git -c credential.helper= -c "credential.helper=!gh auth git-credential" clone --depth 1 https://github.com/Tamdoma/varhop-prompts-b.git`. Identity: gh keyring login ivanjuras. Versions: gh 2.102.0, git 2.56.0. Result: exit 0, head 5a334fa "Add starter prompt", files README.md and prompts/testing/second-repo.md. `gh api repos/Tamdoma/varhop-prompts-b` gives id 1416586635, private, default branch main, not archived. Cleanup: scratch clone deleted. Limits: does not prove varhop-sync's two-slot switch with a draft open, which stays a leaf criterion.
- Repoint of a plugin clone. Command on a scratch `git clone` of ~/.config/omarchy/plugins/ivan.varhop: `git remote set-url origin file:///home/ivan/.akrogon/worktrees/varhop/overlay-plugin; git fetch origin overlay-plugin; git reset --hard FETCH_HEAD`. Identity: local user ivan. Result: scratch HEAD 0df6f48, origin is the new URL. The installed clone's origin and clean status are unchanged. Cleanup: scratch deleted. Limits: a non-fast-forward target (rebased main) was not exercised. The shell only loads new code after omarchy-restart-shell (archive readiness proof rows 18-19).

### split (issues/chart/overlay-rework/forks/split.md)
## Taken
Operator 2026-10-13: `1b | 2a`.
- 1b: two leaves under issues/open/varhop/ISSUE.md.
  - `overlay-plugin` adopts the branch and worktree at 0df6f48 (disposal 4a) and lands it on main behavior-unchanged. It also commits a reusable uinput keyboard helper inside the plugin repo, proven by an observable expected input result passing and a deliberate break failing, with cleanup both ways. It runs an install-and-summon smoke that drives keys into the overlay. It carries the criterion-to-evidence table. It does not list Tamdoma/varhop#1 in sources. Its end state is the installed copy repointed at a main-tracking source, enabled, with the selection intact.
  - `overlay-rework` does editor, look, picker, controls and the proof-bar final-build criteria, and owns the final live sweep and the post-merge operator checklist. It lists Tamdoma/varhop#1 in sources and has blocked-by: [overlay-plugin].
  - This amends the disposal carry: the seed source moves from the successor to overlay-rework, approved by the operator.
- 2a: if overlay-plugin's checks fail on untouched code, it makes the smallest repair needed to land and records it. Any F1-F7 behavior stays out of its scope.
- C's open questions are settled by default. The leaf slug is `overlay-rework`, which matches the chart and is free in issues/. ISSUE.md gets a line for each leaf.

### disposal (issues/chart/overlay-rework/forks/disposal.md)
2026-10-13 operator: `1a | 2a | 3a | 4a`
- Q1 1a: retire the failed leaf, a successor leaf continues on the existing code (0df6f48). Foreclosed: recover in place, rebuild from main, drop the overlay.
- Q2 2a: move the whole leaf folder (tracked and untracked) to issues/chart/overlay-rework/archive/overlay-plugin/, verify the copy, confirm with `akrogon status`, close the old tab wK:t7. Foreclosed: delete.
- Q3 3a: keep the installed plugin until the successor lands, then update in place keeping the shell.json selection. Foreclosed: uninstall now.
- Q4 4a: successor reuses slug `overlay-plugin` and adopts the existing worktree and branch, so the installed clone's origin keeps working. Foreclosed: new slug.
Binding carries: successor first checks worktree HEAD 0df6f48 and clean; successor brief carries a criterion-to-evidence table; live runs read the deployed revision and restart the shell; pre-existing cache/state are not fixtures; final live state is installed, enabled at the merged head, selection intact; successor lives under issues/open/varhop/ and lists Tamdoma/varhop#1 in sources.

### Original chart decisions (issues/chart/varhop/forks/*.md, as copied into the archived design issues/chart/overlay-rework/archive/overlay-plugin/design.md)

### form-factor (issues/chart/varhop/forks/form-factor.md)
#### Taken
2026-10-12 operator: `1a | Note: also check why these overlays appear below everything on my Omarchy system and fix it if it's a small fix. This is after the update, and it's irritationg me. Even the super + space is showing below these windows most of the time.`

Taken: Omarchy shell overlay plugin, installed with `omarchy plugin add` and updated with `omarchy plugin update`. Foreclosed: standalone Qt app, PKGBUILD-first distribution, mise.

Carry: the operator reports existing Omarchy overlays (including Super+Space) render below windows since the last update. A varhop overlay depends on the same layering, so the cause is investigated and fixed here if small (a system-level side task outside the varhop leaves).

Finding (A, 2026-10-12, inspected on the operator's machine): first open of a shell overlay after the focused monitor changes lands on the Bottom layer (below windows); later opens on the same monitor land on Overlay. Reproduced with Super+Space via wtype on HDMI-A-1, DP-1, DP-2 (hyprctl layers: `level1 1600x1000` on first open per monitor, `level3` after). Cause: /usr/share/omarchy/shell/Ui/OverlayWindow.qml parks closed overlays on WlrLayer.Bottom and raises them on open while also switching `screen`. Upstream basecamp/omarchy commit 0a55a3c5 (2026-10-07, "Keep overlays sharp without parked surfaces") rewrites OverlayWindow.qml and adds overlay-monitor-test.sh; installed Omarchy f45461a is 111 commits behind it. Carry: a varhop overlay uses the same OverlayWindow, so the varhop shell leaf proves first-open layer on every monitor.

Finding (A, 2026-10-12): Qt 6.12 added a QtQuick `Color` type that shadows Omarchy's unqualified `Color` palette singleton; this is why the operator rolled back Qt on 2026-10-08 (session ~/.claude/projects/-home-ivan-Work/b899c323-d220-4eab-84ad-d93d4cf4df88.jsonl, rollback hold = `IgnorePkg` in /etc/pacman.conf line 4). Upstream: basecamp/omarchy #14553 (2026-10-08) qualifies palette references as `Commons.Color` and documents that third-party plugins need the explicit namespace; #14845 (2026-10-10) forces QtQuick imports to 6.11 in omarchy-pkgs. Carry: the varhop plugin imports `qs.Commons as Commons` and uses `Commons.Color`, and its proof runs on the operator's pinned Qt 6.11.2.

Update (A, 2026-10-12, after the operator's system update; raised by C2 slots/review-C2.md F1): installed omarchy-dev r6912.gdefbf90 already has the rewritten OverlayWindow.qml (fresh surface per open, no parked Bottom layer, :6-9) and Qt 6.12.0-2 with quickshell 0.3.2-4; `IgnorePkg` is gone. A re-tested Super+Space on HDMI-A-1, DP-1, DP-2: level 3 on each. Carries now: varhop uses `Commons.Color`; its leaf re-verifies first-open layer per monitor on current Omarchy/Qt 6.12 (not 6.11.2).

### copy-and-close (issues/chart/varhop/forks/copy-and-close.md)
#### Taken

2026-10-12 operator: `1a`
- Esc in search: first Esc clears a non-empty query, Esc on an empty query hides (first-party habit; foreclosed: hide and keep the query).
- All Settled items in Findings stand as presented and not objected: wl-copy over stdin with exit-0 close, no auto-paste, history capture accepted, empty output valid, unset copied as `{{NAME}}` with a count, editor Ctrl+C and Ctrl+Shift+C always copy the whole prompt, editor Esc hides with the draft kept, "Find another prompt" binding owed to settings-and-hotkey, draft in memory only (survives hide and theme change, not plugin reload/update or shell restart).

### variable-editing (issues/chart/varhop/forks/variable-editing.md)
#### Taken

2026-10-12 operator: `1a | 2a | 3a`
- Q1 values only, prose fixed (settled by all slots, presented and not objected).
- Q2 one stop per unique name, first-appearance order, mirrors, Tab/Shift+Tab wrap, first stop selected on open, no final stop.
- Q3 filled values show without braces and stay revisitable; Delete on a selected value makes it empty; Delete again on an empty value restores unset `{{NAME}}` (operator 1a; foreclosed: separate Reset action). Hide and resume keeps the exact cursor and selection (operator 2a; foreclosed: reselect on show). Enter inserts a newline, Tab is the only navigation key. Per-variable semantic undo/redo including reset.
- Q4 copy rebuilt from parsed source segments plus values; grammar `{{[A-Z0-9_]+}}`, `{{{NAME}}}` = `{` + token + `}`, tokens in code fences count, backslash removed only before a valid token, pasted `{{OTHER}}` literal. Pasted values may be normalized by Qt (CRLF/U+2028/U+2029 to LF, NBSP to space); accepted for v1 (operator 3a; foreclosed: exact value-input path).
- Editor mechanism left to leaf design with the shared proof list in Findings.

### search (issues/chart/varhop/forks/search.md)
#### Taken

2026-10-12 operator: `1a | 2a`
- D-a 1a: body searched as a folded substring at the lowest weight; terms of 3+ characters only; runs only when structured matches are few; body-only rows show a one-line snippet around the first matched term (foreclosed: metadata-only search). Long-body performance is part of the latency proof.
- D-b 2a: decayed frecency of successful whole-prompt copies per prompt id, stored in a repo-id-scoped state-dir file (never shell.json), applied only after text relevance; empty query shows up to 10 most recently copied prompts first, then the library by category. Storage errors are shown, never silently reset (foreclosed: no usage store).
- All Settled items in Findings stand as presented and not objected.

### settings-and-hotkey (issues/chart/varhop/forks/settings-and-hotkey.md)
#### Taken (2026-10-13)
Operator answer: `1a | 2a | 3a | 4a`. Defaults presented and not objected to are recorded below as taken. Sources: slots/settings-and-hotkey-{A,B,C,merged,rebuttal-B,rebuttal-C}.md.

Hotkey
- varhop never writes Hyprland config and never reloads Hyprland.
- The user pastes one line into ~/.config/hypr/bindings.lua: `o.bind("SUPER + ALT + P", "Varhop prompts", { panel = "ivan.varhop" })`. SUPER+ALT+P was free on this machine on 2026-10-13. It is a suggestion, not an installed default.
- Settings has a chord field, the rendered line and a copy button. The chord field accepts only a validated modifier-plus-key vocabulary and never interpolates free text into Lua. It is not persisted.
- Conflict check: query the live binds (parser is a leaf detail; `hyprctl binds -j` can emit invalid JSON, omarchy-menu-keybindings:300-303). Warn with the existing description and submap. A known collision means the line is not shown as ready. If the layout, keycode or catch-all check is incomplete, say so instead of "free". varhop never generates `o.rebind`.
- varhop does not claim to know its current binding, because Lua binds report `__lua`.
- `omarchy-shell shell summon ivan.varhop` is the documented no-bind fallback, inside the pending third-party overlay proof.

Settings
- Settings is a view inside the overlay, opened with Ctrl+, or a visible button.
- It holds: gh status plus the fix, the repo picker, Sync now, the last successful pull, the last error, load errors, the hotkey section, and "Reset usage for this repository" (the current repo id only). Nothing else.
- Saves go through `updateEntryInline` with the full object. False can mean unchanged, and true is not a durability acknowledgement, so the save proof reads it back.
- Summon routing: an existing draft resumes first. With no repo selected, varhop opens settings at the picker. Otherwise it opens search.
- Esc in settings returns to the view settings was opened from. With no earlier view (first run), Esc hides (1a).

Keys
- Ctrl+P in the editor = Find another prompt. It returns to the previous query and selection, and the draft is kept.
- Ctrl+Shift+P in search or settings = Resume draft. It does nothing without a draft. The pinned row shows the chord.
- Ctrl+R pulls in every view, including the editor, and never changes the draft. It is inert inside the picker's text fields. Only one import or pull runs at a time.
- Ctrl+, toggles settings.
- Keys match exact modifier state.
- In search and settings fields, Ctrl+V and Ctrl+Shift+V paste natively, and both copy variants copy the text selection without triggering the editor's export.

Lifecycle
- No automatic cleanup. Remove disables the plugin before deleting it, so varhop never runs at uninstall.
- The README lists the leftovers and the paths to delete by hand: the bind line (a no-op after removal), ~/.cache/varhop, and the usage state (3a).
- Disable and remove delete the whole shell.json entry, including the repo selection (PluginRegistry.qml:541,557).
- After re-enable, the user picks from the normal empty picker. varhop never infers a repo from the cache (2a).
- Changing the repo while a draft exists warns that a successful switch discards the draft. A failed or cancelled import keeps it. Library, draft, markers and usage always share one repo identity (4a).
- Customizable in v1: the global chord, the repo, and the inherited Omarchy theme.
- There is no second chord into settings.

Proof items for the leaf
- Ctrl+, keysym on the hr layout.
- Every owed chord typed into every focusable field.
- Super+C/V over a browser and a terminal with varhop focused.
- Disable/enable wipes and recreates the entry. Update keeps the selection. Remove leaves the listed files.
- Settings save with read-back.

### sync-and-auth (issues/chart/varhop/forks/sync-and-auth.md)
#### Taken

2026-10-12 operator: `1a | 2 - manual pull, no automatic | 3a | 4a`
- Q1 1a: shallow working clone under `~/.cache/varhop/`, read from disk, with C2's two amendments: `$GIT_DIR/info/attributes` neutralizes checkout transforms on `prompts/**` (proof: CRLF-attributes fixture reads byte-identical to blobs), and two clone slots, refresh the inactive one and switch only after fetch, checkout, read and index succeed (foreclosed: bare clone + cat-file).
- Q2 operator choice, not an offered option: no automatic refresh at all. The first clone runs when a repo is chosen; afterwards the library changes only on a manual pull (Ctrl+R in the overlay, "Sync now" in settings). The footer shows when the copy was last updated. Foreclosed: refresh on summon, cooldowns, timers. The cooldown-timestamp state item is moot.
- Q3 3a: the old library stays until the new repo imports; selection is saved last; a generation number tags every async completion (foreclosed: delete then clone).
- Q4 4a: the gh login name plus numeric account id and repo id are stored with the selection; a mismatch asks to reconfirm the repo through the Q3 path; processes run under `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO` (foreclosed: cache keyed per account/repo id).
- Also binding from Findings: reuse the stored `gh` login with the command-scoped helper, no stored credential, prompts disabled, per-operation timeouts; `/user/repos` picker plus a strictly validated typed `owner/repo`; selection in shell.json via `updateEntryInline` (full object), volatile state elsewhere; empty repo and missing `prompts/` are named states.

### front-matter (issues/chart/varhop/forks/front-matter.md)
#### Taken (2026-10-13)
Operator answer: `1a | 2a | 3a`. The defaults presented were not objected to and are recorded as taken. Sources: slots/front-matter-{A,B,C,merged,rebuttal-B,rebuttal-C}.md.

Boundary (1a, B's rule)
- A header exists when line 1 is exactly `---` (after one optional BOM, with CRLF accepted) and a later line is exactly `---`. The header ends at the first such line, which may be at EOF.
- Validity never moves the boundary. A malformed header shows errors, and the body is everything after the close.
- An empty header (`---` then `---`) is valid. It is the documented escape for a prompt that must start with `---`.
- With no close, the whole file is body and an "unclosed front matter" error is shown.
- A leading blank line or space means there is no header.

Values (2a, A/C subset)
- `title` and `description` are single-line scalars. They can be plain (trimmed, with a ` #` comment stripped, and `: ` inside a value unsupported, so quote it), single-quoted (`''` escape), or double-quoted (`\\ \" \n \r \t \uXXXX`).
- Empty values, `~` and `null` mean absent.
- `tags` accepts a flow list `[a, "b c"]` (quote-aware), block `- item` lines (indented or not), or one scalar as a single tag. Duplicate tags are dropped.
- Block scalars, flow maps, anchors and aliases, multiline quotes and nested maps on a known key are unsupported.
- Unknown keys and their lines are skipped silently.

Errors (3a)
- An unsupported or malformed known key is ignored with a file and line error. The other keys stay.
- For a duplicate known key, the first wins and the second gets an error.

Body bytes
- The body is sliced by offset after the closing line's line break. Nothing is trimmed. Line endings and the final newline are preserved.
- One leading BOM is stripped from every file (default).
- Invalid UTF-8 is a file error, validated at the raw-data boundary (FileView data vs text, proof owed). Replacement-character decoding is never called verbatim.

Fixtures: a thematic break, then prose, then a break (the prose becomes an error and the body after the second break, per 1a); a YAML example body; an unclosed `---`; a title with `: ` and `#`; `description: |`; BOM plus a CRLF header with leading blank lines and no final newline; a BOM without a header; the empty-header escape; a duplicate title; mixed-type tags; indentless block tags; an invalid UTF-8 file.

### Amendments by this chart
- Original editor decisions (variable-editing) are replaced where the editor fork says so: values are edited inline in one guarded text box, not in a separate field. Per-name undo, mirrors, Delete-reset and Tab over unique names stay.
- Picker 4a amends proof-bar Q4 for list rows only: the picker is one Tab control.
- Controls 1a adds Ctrl+Tab as the focus key to the header. The editor's Tab cycle is unchanged.
- Split 1b moves Tamdoma/varhop#1 from the successor to this leaf.

### Owner amendment
- Operator 2026-10-13 `1a` (forks/split.md): this leaf lives under issues/open/overlay-rework/, not issues/open/varhop/, because akrogon closed the varhop owner after its last leaves merged.

### Excluded binding decisions
- prompt-core owns the parsing, grammar, rebuild, scoring and frecency math. repo-sync owns git, gh, the clone slots and the bundle format.
- Landing the base code and building the uinput helper belong to overlay-plugin.

## Standing design

/home/ivan/.claude/skills/chart-issues/assets/standing-design.md

- Live runs use only existing machinery: overlay-plugin's uinput helper on main, git, omarchy-restart-shell, omarchy-shell summon/hide/toggle, hyprctl layers and dispatch, grim, wl-copy/wl-paste and the journal. Component checks use qmltestrunner on the Wayland platform inside the blocking `test` check. No new runner.
- Shared resource forcing serial order: the operator's one omarchy-shell session, its keyboard focus and its clipboard.
- Real GitHub reads use the stored gh login against Tamdoma/varhop-prompts and Tamdoma/varhop-prompts-b (read-only).
- The installed copy and the operator's ~/.cache/varhop and ~/.local/state/varhop are the operator's retained install, not fixtures. The leaf moves the installed copy in place and never removes it. It backs cache and state up before a writing check and restores them byte-identical after, on success and failure.
- Each new behavior shows one deliberate break turning its test red.
- The uinput helper's interface (overlay-plugin design): key sequence plus read-back mode `field`, `clipboard` or `none`. Editor live checks never use `field` mode, because Ctrl+C in the editor exports the prompt and hides the overlay (EditorBody.qml:208-221, Varhop.qml:716-720). They set cursor and selection, run the tested action, and compare the exported clipboard. No new proof machinery is built here. (B,C)
- After this leaf's last live step the installed clone's origin is `file:///home/ivan/Work/omarchy-customizations/varhop`, with no fetch or reset after that change. The door moves it to merged main after the merge. (B,C)

## Leaf architecture

Owned: the views (search, editor, settings), the root card and its header, the picker, the README key table, and the live and component proofs listed in the brief.
- Header: one root-owned row above the loaders, one root function per action (back, settings, close) shared by click, focused-button Enter and shortcut. Whether to use qs.Ui Button at the root or a plain button with the same focus tokens is the plan's choice. Views stay free of Quickshell imports so qmltestrunner can load them.
- Editor: one PlainText TextArea, with a range map from lib/tokens.mjs segments and a guard that routes both textChanged and cursorPositionChanged through one deferred Qt.callLater sync (editor prototype binding). Highlights are rectangles behind the text from positionToRectangle. Adjacent values get a paint-only inset.
- Look: bind Style and Commons.Color roles live, with no snapshot object (today's Varhop.qml:62-70 snapshot is removed).
- Picker: filtering uses prompt-core `fold` for accent folding. The repo list comes from the existing reposProc and its exit state.

Base code, consumed from overlay-plugin on main (original leaf architecture):
Owned paths: manifest.json, *.qml views, the README, and the usage-state I/O at ~/.local/state/varhop/usage-<repoId>.json (written temp+rename, parsed with prompt-core `parseUsage`, errors visible).
Consumes from prompt-core: importLibrary, rebuild, rank, fold, parseUsage, recordCopy, resetUsage and the exported constants, exactly as typed in prompt-core's design.
Consumes from repo-sync: `bin/varhop-sync status | repos | repo | sync` and `~/.cache/varhop/library.json`, exactly as pinned in repo-sync's design. (A,B,C)
- Plugin id: ivan.varhop. Kinds: [overlay]. keepLoaded: true. It uses OverlayWindow and qs.Commons as Commons (Commons.Color).
- Reading its own selection: the shell injects no settings into an overlay (shell.qml:1396-1409), so the plugin reads `~/.config/omarchy/shell.json` with a watched `FileView` and takes the `plugins[]` entry whose id is `ivan.varhop`. It writes through `shell.updateEntryInline` with the full object and confirms by re-reading the file. (A,C)
- Load order at plugin load: read the selection, then read `library.json`. The library is accepted only when its repoId equals the saved repoId. Otherwise settings shows the mismatch. (A,B,C)
- Sync acceptance, one at a time: each sync gets a generation number passed as `--generation`, and a completion whose generation is not the latest is ignored and never accepted. On exit 0 the plugin reads `staged-<n>.json` and imports it. On a repo change it then saves the selection with read-back. Only after both succeed does it run `varhop-sync accept <cache> <n>` and swap the in-memory library. A failed sync, import, save or accept keeps the previous in-memory library, selection and `library.json`, and shows the error. (A,B,C)
- Repeat syncs of a saved repo pass `--expect-account` and `--expect-repo`. On `identity-mismatch` the plugin shows a reconfirm prompt with the actual ids. Confirming runs the repo-change path. (A,B,C)
- Every Text that shows repository or error strings sets `textFormat: Text.PlainText`. Notifications and tooltips receive escaped text. (A,B)
- Latency instrumentation: the plugin logs one structured debug line per search with the key-event time and the frame time after the model update. The live check computes p95 from the journal. The target is p95 ≤ 50 ms (operator 2a).
- Super+C/V: the editor, the search field and every settings text field handle Ctrl+C/V and Ctrl+Shift+C/V themselves, because Qt's TextInput does not paste on Ctrl+Shift+V (proofs-overlay.md row 13). (A,B)
- Copy runs in `Copier.qml`, which imports only Quickshell.Io and QtQuick and takes its command as a property (default `wl-copy --type text/plain;charset=utf-8`) and a timeout. It reports success only on exit 0. A non-zero exit, a timeout, or `running` turning false with no `exited` (a failed start, proofs-overlay.md row 21) is a failure. (A,B)
- Live-run fixtures follow readiness.yaml: absence is checked before creation, and only recorded paths are deleted.
- Operator check after merge, not a done-criterion (operator 4a, proofs-overlay.md rows 16-17). The leaf writes these steps into its completion notes:
  1. Select a word in a browser. Open a prompt with a variable, Tab to the value, middle-click in the value. The word lands in the value and the prose is unchanged. Middle-click on the prose changes nothing.
  2. In a value, type an accented letter with a dead key (on hr: AltGr+9 then e, giving é). The letter lands in the value.
  3. If an IME with preedit is installed, type a composing word in a value and press Ctrl+C before committing. The clipboard holds the committed word.
- Held disagreement (B recheck F4, A): B asks for a live selection-save failure case. No safe injection exists: the shell writes shell.json itself, and blocking that write would touch the operator's whole shell config. The save-failure path is fixed by the order above (accept runs only after a confirmed read-back), and the sync-failure case is proven live.
