# Implementation report: overlay-plugin

Backup fixture (readiness grant 2, fixture 1): /tmp/akr-1000/5c3c/7c0e9f04/overlay-plugin-live/varhop-backup, recorded before creation.

Serial-solo run, implemented by A. Base `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed` (no refresh needed, `origin/main` = base after `git fetch origin`). Adopted head `0df6f48` (clean, verified). Final head `b210f39da935cb944cd51cf2fe2501c657a276a2` (check.fix round 1, below). Implement-pass head was `f66ddad` (content) / `fc11a85` (trailer).

## Changed files

- `test/keyboard.test.ts` (`1ec6a6d`, plan.synthesis): planned red test for the helper.
- `test/keyboard.ts` (`b61823b`, `f66ddad`, `97f83e7`, `b210f39`): the uinput keyboard helper (plan D2-D5).
- `test/keyboard.test.ts` (`8aebd1e`, `90e7331`): check.fix reproductions for review F2 and F1.
- `docs/reference-index.md` (`b61823b`): one line pointing to the helper (plan D11).

No product file changed. Repairs under split 2a: none. The `test` check passed on untouched 0df6f48 (77 pass, plan Preflight).

In-branch fix: `b61823b` failed the configured check (`implementation/check-test-1791889519480-641668.log`, `hyprctl devices exited 1`). Cause was in this diff: `run-check` scrubs the environment, so `hyprctl` had no `HYPRLAND_INSTANCE_SIGNATURE` or `XDG_RUNTIME_DIR`. `f66ddad` runs `hyprctl -i 0` with `waylandEnv()` (existing helper), marked `ponytail:` for the multi-instance ceiling.

## Helper contract (for overlay-rework)

- Command: `bun test/keyboard.ts --device varhop-<leaf>-kbd --keys "<sequence>" --read field|clipboard|none [--expect "<text>"]`.
- Module: `parseSequence(text): KeyEvent[]`, `withKeyboard(name, run)`, `type KeyEvent = {code, value: 0 | 1}`.
- Sequence: space-separated tokens, chords joined by `+`, pressed left to right and released right to left. Names: `a`-`z`, `0`-`9`, `left right up down home end tab enter esc backspace delete space comma period minus slash`, modifiers `ctrl shift alt super`. Unknown names throw.
- Key codes, not characters: on the hr layout KEY_Y types z and KEY_Z types y.
- Refuses to send keys unless `hyprctl layers` shows namespace `varhop`, checked before the device is created and again right before every key press. When the layer is gone mid-sequence it releases held keys and sends no further press. `--device` must start with `varhop-`.
- `field` appends `ctrl+a ctrl+c` and compares the clipboard. `clipboard` compares the clipboard the sequence left. `none` compares nothing. Reads poll up to 2 s for the expected text.
- Clipboard and primary are saved before and restored after with byte compare (`withClipboardRestored`, one MIME type per selection, text preferred), on both outcomes. The device is destroyed and closed in `finally`.
- Output: `{"result":"pass","observed":...}` exit 0, or `{"result":"fail","expected":...,"observed":...}` exit 1. Usage or environment errors exit 2 with the message on stderr and no result line (plan D5).
- Language: TypeScript on bun with `bun:ffi` libc `ioctl`. No new dependency, so `package.json` is unchanged (plan D2).

## Proofs (implement pass at `f66ddad`, rerun at the final head in check.fix round 1)

| Criterion | Command | Commit | Result |
|---|---|---|---|
| 1 | configured `test` check (`akrogon run-check --name 'test' ...`) | `f66ddad` | 80 pass, 0 fail, 2.7 s wall |
| 3 | `omarchy-plugin-validate <worktree>`; installed clone `remote set-url origin file:///home/ivan/.akrogon/worktrees/varhop/overlay-plugin`, `fetch origin overlay-plugin`, `reset --hard f66ddad`; `omarchy-restart-shell`; `omarchy-shell shell summon ivan.varhop`; `hyprctl layers -j`; `journalctl --user --since 13:06` | `f66ddad` | validate exit 0. Installed HEAD `f66ddad`. Restart exit 0. Summon `ok`, layer `varhop` 1600x1000. Journal: no error lines for the plugin. Only `quickshell.qmlscanner` WARN "Module path ... is outside of the config folder" (same warnings archive review-B.md:16 recorded). `ivan.varhop` entry `cmp` equal to the pre-run copy, shell.json sha256 `dfa6df0d…` unchanged. ~1 min wall |
| 4 | `bun test/keyboard.ts --device varhop-overlay-plugin-kbd --keys "ctrl+a backspace v h m a r k left shift+left x" --read field --expect vhmaxk` | `f66ddad` | `{"result":"pass","observed":"vhmaxk"}`, exit 0 (`live-L2-pass.log`). A first attempt refused with "No varhop layer is shown" because the overlay had been hidden after summon (four foreign `varhop-search` key events at 13:06:39). Re-summoned and passed (`live-L2-refused-hidden.log`) |
| 5 | same command without the `m` token | `f66ddad` | `{"result":"fail","expected":"vhmaxk","observed":"vhaxk"}`, exit 1 (`live-L3-break.log`). Then `grep -c varhop- /proc/bus/input/devices` = 0. Clipboard (`image/png`, 378641 bytes) and primary (`text/plain;charset=utf-8`, 64 bytes) `cmp` equal to copies saved before L2 |
| 6 | installed clone `remote set-url origin file:///home/ivan/Work/omarchy-customizations/varhop`, no fetch or reset after; `git rev-parse HEAD`; `omarchy plugin list`; entry `cmp`; `sha256sum -c`; `diff -r --no-dereference` and mode lists of cache and state against the backup; `rm -rf` backup | `f66ddad` | origin set, HEAD `f66ddad`, clean. `ivan.varhop enabled third-party overlay`. Entry equal, shell.json OK. Cache and state byte- and mode-equal to the backup (nothing written, no restore needed). Backup absent |
| 2 | table below | `0df6f48` and `f66ddad` | every archived bullet listed |

## Criterion-to-evidence table (archived brief, issues/chart/overlay-rework/archive/overlay-plugin/brief.md)

AR = `issues/chart/overlay-rework/archive/overlay-plugin/implementation/report.md`. RB = archive `review-B.md`. TV = `qml/tst_views.qml` run by `test/views.test.ts` inside the `test` check, green at `b210f39`. Product code is identical between `0df6f48` and `b210f39` (the diff touches only `test/` and `docs/`), so no archived evidence is invalidated. B's final re-check (RB:425-436) held open only 5f, 6b, 6a all-empty, 7c success and 8 reset, and accepted the rest.

| Row | Criterion | Evidence |
|---|---|---|
| 1a | validate passes | this leaf L1, `b210f39` |
| 1b | install, summon at level 3 on first open per monitor | AR:27-28 (HDMI-A-1, DP-1, DP-2), `0df6f48` line of work |
| 1c | `Commons.Color`, no QML errors | `Varhop.qml` 11 `Commons.Color` uses, no bare `Color.`. Journal clean at L1, `b210f39` |
| 1d | update keeps entry byte-identical, restart runs new code | AR:30, AR:41, AR:84. This leaf L1 (fetch/reset plus restart, entry and sha256 equal), `b210f39` |
| 2a | no selection opens picker, Esc hides | AR:157 (bare entry routes to picker). RB:425-436 accepted |
| 2b | picker choice syncs and saves selection after import | AR:35, AR:53. RB:220 (F1 resolved) |
| 2c | typed repo selects, malformed refused | AR:35. `test/sync.test.ts` "argument validation" cases |
| 2d | restart keeps `library.json` sha256 and `fetchedAt` | this leaf L1+L4: restart and summon, then `library.json` byte-equal to the pre-restart backup, `b210f39` |
| 2e | mismatched `library.json` not loaded, settings names it | AR:117, RB:315 |
| 2f | killed sync keeps library and selection | AR:119 |
| 2g | identity-mismatch reconfirm, nothing saved | AR:118 |
| 3a | Ctrl+, toggles, Esc returns | AR:34, AR:83 |
| 3b | gh login, scopes and last pull shown | AR:34 (settings views live). RB:425-436 accepted |
| 3c | logged-out fix, failed pull, merged load errors (component) | TV `test_settings_logged_out_shows_fix`, `test_settings_failed_pull_and_merged_errors` |
| 3d | settings field paste and copy chords | TV `test_settings_field_paste_copy_chords`. RB:425-436 accepted |
| 3e | chord field warns, ready line, refuses characters | TV `test_chord_field_states`, `test_chord_suggested_syntax_and_character_rejection`. RB:224 (F12) |
| 4a | typing picks top, Up/Down wrap, Enter opens editor | AR:34, AR:36, AR:83 |
| 4b | row details, Draft marker, snippet | TV `test_search_rows_show_details`. AR:38 |
| 4c | pinned Resume row, clicks (component) | TV `test_search_resume_row_and_result_click`. AR:38 |
| 4d | selection kept by id across Ctrl+R | AR:120. TV `test_search_refresh_retains_selection` |
| 4e | Esc clears, then hides | TV `test_search_esc_clear_then_hide`. AR:34 |
| 4f | search field paste and copy chords | TV `test_search_field_paste_copy_chords`. This leaf L2: `ctrl+a ctrl+c` in the live search field copied the field text |
| 4g | latency p95 ≤ 50 ms at 500/2000/5000 | AR:70-74 |
| 5a | Tab wrap, mirrors, zero-variable copies | TV `test_editor_tab_wrap_and_mirror`, `test_editor_zero_variable_calls_copier`. AR:180-186 |
| 5b | prose fixed, newline in value, multiline copies | TV `test_editor_paste_multiline_and_mirror_click`. AR:36 |
| 5c | Delete empties then restores, per-variable undo/redo | AR:83. TV `test_editor_delete_reset_and_undo`, `test_editor_undo_redo_stays_with_the_active_variable` |
| 5d | value paste literal, right-click, mirror click (component part) | TV `test_editor_paste_multiline_and_mirror_click`, `test_editor_right_click_paste` |
| 5e | `č` via fcitx5 lands, commit before copy | AR:159 |
| 5f | exact cursor and selection resume | owned by overlay-rework (value resume only: AR:160) |
| 6a | exact rebuilt copy, unset `{{NAME}}` with count, all-empty | AR:36, AR:156, AR:142, AR:180-186 (zero bytes) |
| 6b | Super+C/V key-state over browser and terminal | owned by overlay-rework |
| 6c | Copier failures (false, missing, timeout), failure keeps draft | `test/copier.test.ts`, TV `test_editor_copy_failure_keeps_draft`, AR:39 |
| 7a | Ctrl+P returns, Ctrl+Shift+P resumes | AR:38, AR:120 |
| 7b | Ctrl+R pulls in every view, draft kept, inert in picker | AR:40. RB:425-436 accepted |
| 7c | repo switch with draft: warn, failed switch keeps draft | failure path: AR:121. Success path: owned by overlay-rework |
| 8a | copy moves prompt to recent list | AR:36, AR:83 |
| 8b | Reset usage clears only this repo (reset-button click) | owned by overlay-rework |
| 8c | usage write failure and malformed file shown, never reset | AR:143, AR:158, AR:122 |
| 9 | plain text, no request | TV `test_plain_text_format` |
| 10a | disable then enable leads to picker | AR:133, AR:157 |
| 10b | remove leaves only README-listed paths | AR:133, AR:157 |

## Grants, fixtures and cleanup

- Grant 2 (local omarchy-shell, operator 2026-10-13). Operations used: `omarchy-plugin-validate`, installed-clone set-url, fetch, reset and the final set-url, `omarchy-restart-shell` (session unlocked), `omarchy-shell shell summon/hide`, `hyprctl layers/devices`, uinput helper, `wl-paste`, `journalctl --user`. No edits to `~/.config/hypr`, other plugins or other shell.json entries.
- Fixture 1 backup: created after its path was recorded, compared, deleted, absence verified.
- Fixture 2 virtual keyboard `varhop-overlay-plugin-kbd` (plus `varhop-keyboard-test-kbd` inside the `test` check): `grep -c varhop- /proc/bus/input/devices` = 0 after each run.
- Grant 1 (GitHub): not used.
- Side effect: the operator's in-memory search query reads `vhaxk` until it is cleared (not persisted).

## Known limitations

- The helper cannot click (layer surfaces reject synthetic pointer clicks on this host, AR:188-196).
- `withClipboardRestored` keeps one MIME type per selection. A selection offering several types comes back with one (text preferred). This run's clipboard offered only `image/png`, so it came back whole.
- `hyprctl -i 0` assumes one Hyprland instance.

## Post-merge operator checklist (from design.md, not a done-criterion)

1. Select a word in a browser. Open a prompt with a variable, Tab to the value, middle-click in the value. The word lands in the value and the prose is unchanged. Middle-click on the prose changes nothing.
2. In a value, type an accented letter with a dead key (on hr: AltGr+9 then e, giving é). The letter lands in the value.
3. If an IME with preedit is installed, type a composing word in a value and press Ctrl+C before committing. The clipboard holds the committed word.

The door moves the installed clone to merged main after the merge (CHART.md Pending steps).

## Final head note

Superseded by check.fix round 1: L1-L4 reran at the final head `b210f39`, and the installed clone is at `b210f39`.

## check.fix round 1 (2026-10-13)

Backup fixture for the rerun (readiness grant 2, fixture 1): /tmp/akr-1000/5c3c/7c0e9f04/overlay-plugin-live/varhop-backup, recorded before creation.

Input: review-B.md check.repair "Handed to A": A F1 / B F1, B F2, B F3. Reviewed base `5cac0ae`, reviewed head `fc11a85`. Refresh: `git fetch origin`, `origin/main` = `5cac0ae` = merge base, so the branch did not move. Handed-off base `5cac0ae`, handed-off head `b210f39`. Plan: dated "Implementation notes" section added to plan.md.

### Repairs

| Finding | Reproduction (red before fix) | Fix | Result |
|---|---|---|---|
| B F2: CLI errors exit 1, plan D5 says 2 | `8aebd1e` test "a usage error exits 2 with its message and no result line". Red: `Expected: 2 Received: 1` (`implementation/fix-red-F2.log`) | `97f83e7`: top-level `import.meta.main` maps a thrown error to stderr and exit 2. Cleanup still runs through the `finally` blocks first | green at `b210f39`. Live: absent-overlay and mid-sequence-hide runs exit 2 |
| A F1 / B F1: keys keep going after the overlay hides | `90e7331` test "no press goes out once the overlay is gone, and held keys are released". Red: `Export named 'deliver' not found` (`implementation/fix-red-F1.log`) | `b210f39`: `deliver` checks `hyprctl layers` right before every press, releases held keys and throws when the layer is gone. Covers both the registration delay and a hide during the sequence | green at `b210f39`. Live proof below |
| B F3: install not at the final commit | none (live state) | L1-L4 rerun at `b210f39` after all commits | installed HEAD `b210f39` |

`b210f39` carries the `Test-Change: test/keyboard.ts` trailer (amended before the check ran, tree unchanged). No existing expectation changed.

### Proofs at `b210f39`

| Criterion | Command | Result |
|---|---|---|
| 1 | configured `test` check | exit 0, 82 pass, 0 fail, 309 expect() calls, 2 s wall (`implementation/check-test-fix.log`). Ran on tree of `f47bf63` = tree of `b210f39` (amend changed the message only) |
| 3 | L1: `omarchy-plugin-validate <worktree>`; installed clone set-url to the worktree, `fetch origin overlay-plugin`, `reset --hard b210f39`; `omarchy-restart-shell` (13:27:50); `omarchy-shell shell summon ivan.varhop`; `hyprctl layers -j`; `journalctl --user --since 13:27:50` | validate 0, installed HEAD `b210f39`, restart 0, summon `ok`, layer `varhop` 1600x1000. Journal lines naming the plugin: only `DEBUG Local plugin changed, reloading` and the `qmlscanner` "outside of the config folder" WARN. No QML error. Entry `cmp` equal, shell.json sha256 `dfa6df0d…` OK. ~1 min wall |
| 4 | L2: D6 command | `{"result":"pass","observed":"vhmaxk"}`, exit 0 (`implementation/live-fix-L2-pass.log`) |
| 5 | L3: D7 command | `{"result":"fail","expected":"vhmaxk","observed":"vhaxk"}`, exit 1 (`implementation/live-fix-L3-break.log`). `grep -c varhop- /proc/bus/input/devices` = 0. Clipboard and primary were empty at L0 and are empty after (`Nothing is copied` both) |
| F1 live | `bun test/keyboard.ts --device varhop-overlay-plugin-kbd --keys "ctrl+a backspace esc shift" --read none` with the overlay shown | Esc hid the overlay (empty query), the next press (Shift, chosen as harmless) was refused: `No varhop layer is shown; stopped with 2 of 10 key events unsent`, exit 2, no result line (`implementation/live-fix-F1-hide.log`). Layer list empty after, device count 0, selections still empty |
| 6 | L4: installed clone set-url `file:///home/ivan/Work/omarchy-customizations/varhop`, no fetch or reset after; `git rev-parse HEAD`; `omarchy plugin list`; entry `cmp`; `sha256sum -c`; `diff -r --no-dereference` and mode lists against the backup; `rm -rf` backup | origin set, HEAD `b210f39`, clean. `ivan.varhop enabled third-party overlay`. Entry equal, shell.json OK. Cache and state byte- and mode-equal (no restore needed). Backup and scratch dir absent |
| 2 | table above | product unchanged `0df6f48`..`b210f39` (diff touches only `test/` and `docs/`), so no archived row is invalidated. Rows citing this leaf's L1/L4 now cite `b210f39` |

### Notes

- L3 did not need `omarchy-shell shell hide`: the F1 live probe hid the overlay with Esc.
- Side effect: the operator's in-memory search query is empty (cleared by the F1 probe).
- New limitation: the per-press check leaves a one-`hyprctl`-call window, and focus loss without the layer disappearing is not detected (plan Implementation notes).
- Grant 2 operations only. Grant 1 (GitHub) not used. No merge check configured.
