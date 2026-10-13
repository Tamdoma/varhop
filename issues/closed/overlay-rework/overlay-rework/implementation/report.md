# Implementation report: overlay-rework (slot A, serial-solo)

Base b210f39 (AKROGON_BASE and origin/main). Head 0be8ca4 after check.fix (reviewed head fa71cf0). Every criterion is proven on 0be8ca4. The first pass ended failed on an operator blocker (OA3), and the resume pass cleared it.

## Changed files

| File | Reason |
|---|---|
| Varhop.qml | One `Card` on the Omarchy menu surface (`BorderSurface`, scrim, Commons tokens). The root keeps I/O only; view state moved to Card. Repo list state persists `failed` until a list arrives. |
| qml/Card.qml (new) | Header (Back, title, Settings) above the active view. Owns routing and the draft, so click, header Enter and shortcut call one function. Ctrl+Tab moves focus between body and header. |
| qml/TextButton.qml (new) | A Tab stop button. Enter, Return and Space press it. |
| qml/EditorBody.qml | Values are edited inline in one guarded text box with undo/redo, Tab over names and rebuilt copy. Text is set before ranges, and highlight positions clamp to the length. |
| qml/SearchBody.qml | Theme and tokens. Selection resets to the first row on each query edit. |
| qml/SettingsBody.qml | Repo picker filters as you type, keeps stable order and highlight by repo id. Esc clears the filter first. All controls are reachable by Tab and Enter. |
| lib/search.mjs | Rank caches use plain variables and a strong `Map`, not `WeakMap` (QV4 crash, see Bug fix). |
| README.md | Key table: Back, Settings, undo/redo, Ctrl+Tab, header keys, Esc order. |
| qml/tst_views.qml | Reproduction tests e0081df, 09f2109, 820ef2a (Test-Change trailers). Planned cases came from 61e137a. |
| qml/tst_card.qml | Reproduction test 63a920e (Test-Change trailer). |

## Bug fix linked to its test

The live shell crashed (SIGSEGV) when ranking after the library was replaced. gdb with debuginfod showed `WeakMapPrototype::method_get` → `ESTable::get` → `Managed::isEqualTo` with a null vtable: QV4 (Qt 6.12) reads a collected WeakMap key. The same crash also hit the base install at 13:27.

- Test: `test_search_rank_survives_replaced_libraries` (qml/tst_views.qml), committed alone in e0081df with a Test-Change trailer.
- Fail before: on 323d3f2 qmltestrunner died with SIGSEGV in that case.
- Pass after: on fa71cf0 tst_views shows 38 passed.

## Commands and results

| Command | Commit | Result | Wall |
|---|---|---|---|
| `test` check (`akrogon run-check --name test ...`) | 323d3f2 | 84 pass | 3.6 s |
| `bun test` | fa71cf0 | 84 pass, 0 fail | 3.84 s |
| `test` check, first pass | fa71cf0 | not run: queued 21 min on the global akrogon run.lock (another session's test_changed, pid 383661), then stopped by A | >21 min wait |
| `test` check, resume pass, run 1 | fa71cf0 | killed while queued (log deleted by another process's temp cleanup), no check_end | 66 min queued |
| `test` check, resume pass, run 2 | fa71cf0 | red: 83 pass, 1 fail. `VarhopCard::test_theme_roles_bind_live`, `lastQuery` "d" vs "de" (tst_card.qml:98, second keyClick lost). Log check-test-1791901205363-3663161.log | 15 min queued, 9.0 s run |
| `test` check, retry (same command, args, cwd) | fa71cf0 | green: 84 pass, 0 fail. Log check-test-1791910073795-1067274.log. Marked `inconsistent`, no base run. Record: compare-test.yaml | 137 min queued, 45.8 s run |
| Break check: Card header handler removed | before 323d3f2 | 2 tst_card cases red | s |
| Live step 4, Ctrl+Tab (`bun test/keyboard.ts ... --keys "ctrl+tab space x" --read field --expect x`) | fa71cf0 | `{"result":"pass","observed":"x"}` | s |
| Live step 5, OA2 | fa71cf0 | pass, clipboard `Summarize the text below in three bullets for abcx.\n\n{{TEXT}}\n` | s |
| Live step 6, OA3, first pass | fa71cf0 | not valid: operator typing contaminated the runs | min |
| Live step 6, OA3: direct `ctrl+v ctrl+c` in a value | fa71cf0 | pass, `...for PASTEDV.\n\n{{TEXT}}\n` | s |
| Live step 6, OA3 over foot 0x55dbf25e5dd0 (terminal tag): `ctrl+a backspace s u m m enter super+v super+c` | fa71cf0 | pass, same bytes | s |
| Live step 6, OA3 over Chrome 0x55dbf2320c60 (browser tag): same keys | fa71cf0 | pass, same bytes | s |
| Live step 7, OA1: draft, choose varhop-prompts-b, warning, confirm, open second-repo.md, `x ctrl+c` | fa71cf0 | pass, `This prompt comes from x.\n`. Draft gone on summon. Entry equal to backup after switching back | s |
| Live step 8, reset isolation by Tab and Enter | fa71cf0 | pass. usage-1416196860 reset to `{"version":1,"entries":{}}`. usage-1416586635 sha256 b02459e2... unchanged | s |
| Live step 9, restore | fa71cf0 | pass. `diff -r` of cache and state against the backup equal, shell.json sha256 dfa6df0d... equal. Shell restarted, smoke ok. Backup deleted. Origin set back to `file:///home/ivan/Work/omarchy-customizations/varhop` as the last step | s |

The live step log is in `../scratch/live.md`. The screenshots are `w4-card-search.png` (criterion 2b smoke) `w4-oa2-editor.png` and `w4-oa1-draft-gone.png`, cropped to the card.

## Criteria

| # | Status | Evidence |
|---|---|---|
| 1 Picker | proven | tst_views picker cases in the `test` check |
| 2a, 2c | proven | tst_card cases in the `test` check |
| 2b | proven | `test/plugin.test.ts` surface case and w4-card-search.png |
| 3 Editor | proven | 15 `test_editor_*` cases |
| 4 Controls | proven | tst_card header and round-trip cases |
| 5 Keyboard | proven | settings Tab/Enter case and live step 8 |
| 6 Live | proven | live steps 4-7 |
| 7 Final live state | proven | live step 9 |
| 8 Operator checklist | below | |

## Refresh

Fetch origin and rebase onto origin/main at head 323d3f2: no movement (base b210f39, origin/main b210f39). Resume pass at head fa71cf0: `git fetch origin` gave origin/main b210f39, merge-base b210f39. The branch did not move (base b210f39, head fa71cf0). AKROGON_BASE is b210f39.

## First-pass blocker (resolved)

The first pass ended with `akrogon phase overlay-rework failed`. The operator's typing landed in the summoned overlay (stray "prije" and "dfsfs" in values), and the focus dispatch did not take. The operator left the session idle and re-prompted. On the resume pass, focus took, the direct and bind pastes both worked, and steps 6-9 passed. One first-pass run timed out (wl-copy held the stdout pipe) and skipped its clipboard restore. The clipboard was restored by hand to the newest Omarchy history image (14:21:01, sha256 d820d283...).

## Limitations

- `test_theme_roles_bind_live` failed once and passed on the same head. Its `toEditor` helper uses `keyClick` into a real Wayland window, and a focus change in the operator's active session can drop a key. Same head, no code change between runs. Recorded as `inconsistent` in compare-test.yaml.
- The primary selection (select-to-paste) was not restored twice in check.fix: after check run 1 timed out, and after one live `esc` run. Its earlier value is unknown and cannot be put back.
- The live sweep uses the uinput keyboard. A physical keyboard and mouse stay on the operator checklist.

## check.fix repair (2026-10-13)

Prior reviewed base b210f39, head fa71cf0. Handed-off base b210f39, head 0be8ca4. Refresh before reading findings and after the repair commits: `git fetch origin` gave origin/main b210f39, already an ancestor of HEAD. The branch did not move.

| Finding | Reproduction (red on head before fix) | Fix | Fail before | Pass after |
|---|---|---|---|---|
| B/F1 plain Tab into the header then Esc/Ctrl+Tab lost the input | 63a920e `test_plain_tab_to_header_then_esc_returns_to_input` (tst_card) | 6f2d5fc: Card.qml records the last focused item inside the body on every focus change, so any path into the header returns to it | fix-bf1-red.log, on fa71cf0: 'Esc returns to the query field' FALSE | fix-bf1-green.log: tst_card 15 passed |
| B/F2 Shift+Delete cut rejected prose to the clipboard | 09f2109 `test_editor_rejected_shift_delete_keeps_clipboard` (tst_views) | 9ebfa5d: EditorBody.qml routes `StandardKey.Cut` (Shift+Delete) to the guarded `cut()` | fix-bf2-red.log, on 6f2d5fc: X is "A value b", not "SENTINEL" | fix-bf2-green.log: tst_views 39 passed |
| A/F1 settings Tab focus landed below the card | 820ef2a `test_settings_tab_scrolls_focused_control_into_view` (tst_views) | 0be8ca4: SettingsBody.qml moves the Flickable's contentY so the focused control is fully visible | fix-af1-red.log, on 9ebfa5d: resetUsageButton top 426 + 28 > 420 | fix-af1-green.log: tst_views 40 passed, tst_card 15 passed |

| Command | Commit | Result | Wall |
|---|---|---|---|
| `test` check, run 1 | 0be8ca4 | red: 83 pass, 1 fail. tst_card.qml under qmltestrunner stalled after `test_search_settings_round_trip_three_ways` and hit bun's 60 s timeout (84.3 s). Host load average 161-198. Log check-test-1791910979448-939082.log | 2 min queued, 135 s run |
| direct tst_card, 3 runs (diagnosis) | 0be8ca4 | 15/15 each, about 2 s each, at load 177 | s |
| `test` check, retry (same command, args, cwd) | 0be8ca4 | green: 84 pass, 0 fail. Log check-test-1791918676207-1477448.log. Marked `inconsistent`, no base run. Record: compare-test-0be8ca4.yaml | 127 min queued, 4.1 s run |
| Live steps 2-9 (scratch/live.md, check.fix pass) | 0be8ca4 | pass: Ctrl+Tab, B/F1 plain Tab round trip, OA2, B/F2 Shift+Delete keeps the clipboard, OA3 over foot and Chrome, OA1, reset isolation with A/F1 scroll, restore. Origin set back last | about 25 min incl. 8.5 min idle wait |

The first three OA2 attempts were not valid. The operator was active and the overlay hid mid-run. The sweep waited for 120 s with no cursor or window change, then ran. One primary-selection restore after an `esc` run failed its byte compare. The regular clipboard restores all passed. README unaffected: the key table already describes the repaired behavior.

## Operator checklist (criterion 8, post-merge on the installed build)

1. Physical Super+V paste over a browser and over a terminal.
2. A mouse click on a search row, a value, Back and Settings.
3. IME preedit inside a value.
4. A middle-click paste onto prose, which must be rejected.
