# Plan: overlay-rework

Base: b210f39 (AKROGON_BASE). Debate ran; this integrates positions A/B, rebuttals and the locked design.md. Where brief and design differ, design wins. No conflict was found.

## Decisions

- D1 **Card.qml.** A new Quickshell-free `qml/Card.qml` owns view routing and its state. It also owns the fixed header, the three view loaders, key dispatch and Ctrl+Tab.
  - State: `view`, `cameFrom`, `draft`, `currentPrompt`, `prevSearch`, `lastQuery`, `selectedId`.
  - Functions: `route()`, `openSettings()`, `leaveSettings()` (today's backRequested branch), `findAnother()`, `captureForHide()`.
  - Varhop.qml keeps file I/O, processes, sync flow and usage. It feeds Card inputs and handles Card signals.
  - Why: the header and routing must be testable under qmltestrunner, which cannot load Quickshell.
- D2 **Surface.** Varhop.qml wraps Card in `BorderSurface` following the Emojis.qml recipe:
  - `menu.background`, `Border.surfaceSpec("menu", "border", ...)`, `Style.cornerRadius`
  - a `menu.scrim` backdrop
  - a card of `Style.space(560)` × `Style.space(480)`, clamped by `Style.gapsOut`
  - The `colors` snapshot and all alpha/opacity code are removed.
- D3 **Live theme objects.** Card and the views take `theme` (Commons.Color) and `tokens` (Style) as live objects. They are named `theme`/`tokens` because Item already has `palette`.
  - Text uses `tokens.font.menuFamily`. Query, header title and editor body use `heading`. Titles and button labels use `title`. Metadata and shortcut hints use `body`.
  - Row and field heights derive from `tokens.spacing` and font tokens.
  - Text roles use `menu.text` and `menu.selected*`. Muted, accent and urgent stay foundational colors. No Text uses `foreground`.
- D4 **Editor.** One `TextArea` (`objectName: "editorText"`, PlainText) shows the whole prompt with values inline.
  - Segments come from `lib/tokens.mjs`. Copy rebuilds with `lib/rebuild.mjs` from segments plus values, never from the box text.
  - A guard runs from textChanged and cursorPositionChanged through one deferred `Qt.callLater`. It accepts an edit only inside the active value range, applies it to every mirror, and otherwise restores text, cursor and selection.
  - Key paths (Backspace/Delete at edges, Ctrl+Home typing, cut and paste across a boundary) are rejected before they reach the box. A rejected cut never touches the clipboard.
  - Native undo is unreachable: Ctrl+Z/Ctrl+Shift+Z/Ctrl+Y map to per-name stacks, and the context menu's Undo/Redo are disabled.
  - Delete on a filled value empties it. Delete on an empty value unsets it, and undo restores it. Delete on an unset value adds no history.
  - API: `ranges`, `valueOf(name)`, `setValue`, `unsetValue`, `activeName`, `openPrompt()`, `captureDraft()` → `{promptId, values, activeName, cursor, anchor, histories, redos}`.
  - Highlights are `valueHighlight` items with `name` and `kind` ∈ active/filled/empty/unset, inset so adjacent values do not touch.
  - Tab onto a filled value puts the cursor at its end. Tab onto an unset value selects the whole `{{NAME}}`.
  - `persistentSelection: true`, so header focus keeps the selection.
- D5 **Picker in SettingsBody.**
  - Inputs: `repos`, `reposState` ("loading"/"failed"/"ready").
  - Outputs: `filteredRepos` (fold substring on fullName, A-Z by lowercased fullName), `pickerIndex` (-1 = none), `lookupDone(typed, fullName, repoId)` → `lookupAccepted(fullName, repoId)` only when the trimmed field text still equals `typed`.
  - The highlight goes to the exact match, else the first match, after each text change. It is keyed by repo id across refresh, and cleared when that repo is gone.
  - The field is the only Tab stop. Up and Down wrap. The list shows 8 rows, keeps the highlight in view and marks the current repo "current". Esc clears a non-empty filter, otherwise it emits backRequested.
  - Varhop sets `reposState` from the reposProc exit. repoProc's result goes through `lookupDone` instead of calling `chooseRepo` directly.
- D6 **Header and buttons.** A plain `qml/TextButton.qml` (activeFocusOnTab, Enter/Return/Space press, `label` plus a muted `shortcut` Text) is used by the header and the settings controls.
  - Header objectNames: `header`, `headerTitle`, `backButton`, `settingsButton`.
  - Search: title "Prompts", `Settings  Ctrl+,`.
  - Editor: `Back  Ctrl+P`, the prompt title (ElideLeft), `Settings  Ctrl+,`.
  - Settings: `Back  Ctrl+,`, or `Close  Ctrl+,` when `leaveSettings()` would hide. Title "Settings". Empty right side.
  - A click, header Enter and the shortcut all call the same Card function.
  - Ctrl+Tab toggles focus between body and header. In the header, Esc returns to the body. The body regains its last focus item, so caret, selection, activeName and pickerIndex are untouched.
- D7 **Serial-solo.** The component suite shares the real Wayland clipboard, and live runs share the operator's shell session. A implements alone in four waves.
- D8 **Live proof** uses only tools present at base: `test/keyboard.ts`, `omarchy-shell`, `omarchy-restart-shell`, `hyprctl`, `wl-copy`/`wl-paste`, `jq`, `cmp`, `sha256sum`, `grim`, `git`. No new proof machinery.
- D9 **Middle-click and IME commit.** Both enter the box through `insert`, which the D4 guard reverts outside the active value. `test_editor_prose_never_changes` proves that path with `f.insert(0, "MID")`. The physical middle-click and IME preedit stay on the operator checklist (criterion 8), because a synthetic primary selection and IME are not reachable from qmltestrunner.

## Read first

- `docs/reference-index.md` (3 links). `learnings/LESSONS.md` is empty, a gap with no lessons yet.
- `Varhop.qml`: colors 62-70, route() 250-269, card 769-779, keys 786-811, loaders 813-946.
- `qml/EditorBody.qml`, `qml/SearchBody.qml`, `qml/SettingsBody.qml`, `qml/FieldKeys.js`
- `lib/tokens.mjs`, `lib/rebuild.mjs`, `lib/fold.mjs`
- `/usr/share/omarchy/shell/plugins/emojis/Emojis.qml` (surface recipe), `Border`, `BorderSurface` in qs.Ui, `Style`, `Commons.Color`
- `test/keyboard.ts`, `test/clipboard.ts`, `test/views.test.ts`, `qml/tst_views.qml`, `qml/tst_card.qml`, `qml/testing/Fake*.qml`
- `/usr/share/omarchy/default/hypr/bindings/clipboard.lua:46-47` (Super+C/V sends Ctrl+C/V, or Ctrl+Shift+C/V over terminals)

## Interfaces

- `Card` inputs: `theme, tokens, library{prompts}, rows, selection, libraryMismatch, syncStatus, repos, reposState, binds, lastPull, lastError, loadErrors, copier, copyText`
- `Card` state: `view, cameFrom, draft, currentPrompt, prevSearch, lastQuery, selectedId, body` (alias to the active loader item)
- `Card` signals: `hideRequested, queryEdited(q), pullRequested, repoChosen(fullName), repoTyped(name), lookupAccepted(fullName, repoId), syncNow, resetUsage, confirmReimport`
- Views keep their signals. `colors` is replaced by `theme` and `tokens`.
- EditorBody adds D4's API. SettingsBody adds D5's API and the objectNames `repoField, repoList, repoRow<i>, repoStateLine, confirmReimportButton, syncNowButton, resetUsageButton, copyBindButton`.

## Waves (all serial, one unit each)

| Wave | Unit | Owns | Shared resource | After |
|---|---|---|---|---|
| W1 | Editor | `qml/EditorBody.qml`, `qml/FieldKeys.js` | Wayland clipboard (component suite) | none |
| W2 | Picker and view look | `qml/SettingsBody.qml`, `qml/SearchBody.qml` | Wayland clipboard | W1 |
| W3 | Card and wiring | `qml/Card.qml`, `qml/TextButton.qml`, `Varhop.qml`, `README.md` | Wayland clipboard | W2 |
| W4 | Live sweep | `<leaf>/scratch/` evidence and report | operator shell session, clipboard, uinput | W3 |

Docs:
- `README.md`: the key table (lines 48-64) gains Ctrl+Tab and the header buttons, and Esc in the picker clears the filter first.
- `docs/reference-index.md` and the AREA files are not affected.

## Criteria → proof

All component proofs run in the `test` check: `bun test test/views.test.ts`, which runs `qml/tst_views.qml` and `qml/tst_card.qml` under qmltestrunner on Wayland. Size: seconds. Rerun on any change under `qml/`, `lib/`, `Varhop.qml` or `test/`.

| # | Criterion | Proof (test → command) | Catches | Size | Rerun |
|---|---|---|---|---|---|
| 1 | Picker | `test_picker_filters_in_stable_order_with_highlight`, `test_picker_lookup_and_state_lines`, `test_picker_is_one_tab_stop_with_bounded_rows`, `test_picker_highlight_follows_repo_id_across_refresh`, `test_picker_esc_clears_filter_first` → `bun test test/views.test.ts` | no filter, reorder, wrong highlight, stale lookup applied, multi-stop Tab, Esc leaving with a filter | s | qml/SettingsBody.qml |
| 2a | Fonts and sizes, no clipping at base 24 | `test_fonts_follow_menu_family_and_size_tokens`, `test_larger_base_does_not_clip` (tst_card) | wrong family or size, clipped text | s | qml/ |
| 2b | Surface recipe, no snapshot or alpha | `Varhop.qml builds the card on the Omarchy menu surface` → `bun test test/plugin.test.ts`, plus the W4 screenshot | missing BorderSurface, tokens or scrim, a leftover colors snapshot or alpha code | s | Varhop.qml |
| 2c | Live theme roles | `test_theme_roles_bind_live` (tst_card) | snapshot colors, foreground used for text | s | qml/ |
| 3 | Editor | `test_editor_*` (15 new cases) in tst_views | prose edits, mirror drift, wrong Tab or selection, history loss, native undo, clipboard touched by a rejected cut, copy not rebuilt | s | qml/EditorBody.qml, lib/ |
| 4 | Controls | `test_header_rows_titles_and_shortcuts`, `test_settings_without_return_shows_close`, `test_editor_back_same_state_three_ways`, `test_settings_round_trip_from_editor_three_ways`, `test_search_settings_round_trip_three_ways`, `test_library_mismatch_route`, `test_ctrl_tab_round_trip_keeps_body_state`, `test_plain_tab_reaches_header_and_space_presses`, `test_esc_in_body_keeps_its_meaning` | divergent click/Enter/shortcut state, header focus loss, initial header focus, Esc meaning changed | s | qml/ |
| 5 | Keyboard equivalents | `test_settings_controls_reachable_by_tab_and_enter`, picker and Tab cases above, W4 step 8 (Reset isolation, live) | unreachable control, reset touching the other repo's usage | s + min | qml/, Varhop.qml |
| 6 | OA1, OA2, OA3, Ctrl+Tab live | W4 steps 4-7 | live behavior differing from the component run | min | any code commit |
| 7 | Final live state | W4 step 9 | install left at the leaf URL, changed entry, cache or state | min | any code commit |
| 8 | Operator checklist | content of the implementation report | missing post-merge item | s | report edit |

## Intended reds (recorded at plan.synthesis)

`bun test`: 81 pass, 3 fail.

- `tst_views.qml` → `Cannot assign to non-existent property "tokens"` (tst_views.qml:52). The views have no `theme`/`tokens` yet.
- `tst_card.qml` → `tst_card.qml:19,31: Card is not a type`.
- `Varhop.qml builds the card on the Omarchy menu surface` → `Expected to contain: "BorderSurface"`.

Per-case reds, from a scratch copy whose views only gained empty `theme`/`tokens` properties:

```text
Totals: 16 passed, 21 failed
FAIL test_editor_* (15 cases): 'the editor is one text box' returned FALSE (openEditor finds no editorText)
FAIL test_picker_esc_clears_filter_first: Esc clears a non-empty filter, Actual x, Expected ""
FAIL test_picker_filters_in_stable_order_with_highlight: Cannot call method 'map' of undefined (no filteredRepos)
FAIL test_picker_highlight_follows_repo_id_across_refresh: Cannot read property 'undefined' of undefined (no pickerIndex)
FAIL test_picker_is_one_tab_stop_with_bounded_rows: 'the picker list' returned FALSE
FAIL test_picker_lookup_and_state_lines: 'the picker has a state line' returned FALSE
FAIL test_settings_controls_reachable_by_tab_and_enter: 'confirmReimportButton shows' returned FALSE
PASS all 16 retained search, settings, chord, zero-variable and plain-text cases
```

## W4 live sweep (bounded by the readiness grants)

The grants used are the omarchy-shell session grant and the read-only gh grant. Every step records commands and results in `<leaf>/scratch/live.md`. One live run at a time. `omarchy-restart-shell` runs only while the session is unlocked. Synthetic keys are sent only while the overlay is focused (the helper checks this per press). The clipboard is saved before each check and restored after it.

1. **Preflight.** Session unlocked, `/dev/uinput` writable, installed plugin present and enabled, `hyprctl version` 0.56.2.
2. **Backup.** Check the backup folder is absent, then copy `~/.cache/varhop`, `~/.local/state/varhop` and the `ivan.varhop` entry (jq) to `<leaf>/scratch/varhop-backup`. Record sha256 of each file.
3. **Move the install.** In `~/.config/omarchy/plugins/ivan.varhop`:
   - `git remote set-url origin file:///home/ivan/.akrogon/worktrees/varhop/overlay-rework`
   - `git fetch origin overlay-rework`, then `git reset --hard FETCH_HEAD`
   - `omarchy-restart-shell`
   - Smoke test: summon, then a cropped `grim` screenshot of the card.
4. **Ctrl+Tab.** `bun test/keyboard.ts --device varhop-overlay-rework-kbd --keys "ctrl+tab space x" --read field --expect x`. Space on the focused Settings button opens settings, and `x` lands in the repo field.
5. **OA2.** Open a prompt with one variable, type `abcdef`, then `shift+left shift+left`. Hide and summon. Send `shift+left x ctrl+c`. The expected `wl-paste` bytes are the prompt rebuilt with value `abcx`, which proves both selection ends and the active end.
6. **OA3.** Focus an existing browser window, summon, then `super+v` and `super+c`. Compare the clipboard. Repeat over an existing terminal window. If no such window exists, record an operator blocker, not a pass.
7. **OA1.** With a draft open:
   - Choose `Tamdoma/varhop-prompts-b`. The warning shows. Confirm.
   - Open `second-repo.md` and compare the clipboard. The draft is gone.
   - Switch back to `Tamdoma/varhop-prompts` and compare the entry with the backup.
8. **Reset isolation.** Tab to "Reset usage for this repository", then Enter. `usage-1416196860.json` is reset. The sha256 of `usage-1416586635.json` is unchanged.
9. **Restore.**
   - Restore cache and state from the backup and put the entry back with jq (temp file then rename). Compare bytes, then delete the backup.
   - As the last step, run `git remote set-url origin file:///home/ivan/Work/omarchy-customizations/varhop`. No fetch or reset after it.

Restart boundaries:
- Each of steps 4-8 restarts alone after restoring the clipboard.
- A code commit after the sweep reruns it from step 3.
- A failure in step 9 reruns step 9 only.
- Steps 2 and 9 always pair: never run step 3 without a verified backup.

## Credentials

The design names no credential variables. `akrogon status overlay-rework` shows no `Missing:` lines. The gh keyring login is used under the read-only grant only.

## Operator checklist (for the implementation report, criterion 8)

Physical Super+V paste over a browser and over a terminal. A mouse click on a search row, a value, Back and Settings. IME preedit inside a value. A middle-click paste onto prose, which must be rejected.

## Implementation notes (2026-10-13)

- TextButton moved from W3 to W2: SettingsBody's buttons use it, so it lands with the settings look. Refines the waves table only.
- Card gained `settingsOpened` (the root refreshes the repo list on it) and `retainSelection` (passed through to SearchBody). Refines the Card interface.
- SearchBody resets the selection to the first row on every query edit. Rows can be identical across edits (cache hit), which left a stale selection. Refines the search behavior under the picker and Ctrl+Tab criteria.
- EditorBody sets the text before replacing `ranges`, and highlight geometry clamps positions to the current length. A raw keystroke reflows the text before the guard pass and logged `QTextCursor::setPosition` range warnings. Refines D-level editor highlights, with no behavior change.
- The root's repo list state (`loading`, `failed`, `ready`) stays `failed` across retries until a list arrives.
- `lib/search.mjs` keeps its rank caches in plain variables and a strong `Map`, not `WeakMap`. QV4 in Qt 6.12 segfaults in `WeakMap.get` once a key was collected, which crashed the live shell after a library replace. Refines the search cache only, with no behavior change. Reproduction: `test_search_rank_survives_replaced_libraries` in tst_views.
