# Proof: third-party overlay plugin (C2 F2), 2026-10-13

Grant: operator answer "3a" (2026-10-13). Local machine only, identity: user ivan's omarchy-shell session. Targets: ~/.config/omarchy/plugins/ivan.varhop-probe (created), the shell.json plugins entry for ivan.varhop-probe (created by enable), and one temporary marked line appended to ~/.config/hypr/bindings.lua. Operations: copy, validate, rescan, enable, summon, hide, toggle, append bind, hyprctl reload, then cleanup with remove --yes, delete the bind line, and restore from backup if the hash differs. Backups and sha256 values are in the session scratchpad (shell.json 459fbc8b…, bindings.lua 8d3ee482…). No public, billing or remote effects.

Versions: omarchy 4.0.0.r6912.gdefbf90-1, Hyprland 0.56.2-4, Quickshell 0.3.2-4, Qt 6.12.0-2.

| # | Command | Observed |
|---|---|---|
| 1 | symlink into plugins/, rescan | Not listed. `omarchy-plugin-validate` rejects symlinks. A real folder copy is required. |
| 2 | copy folder, `omarchy-plugin-validate` | exit 0 |
| 3 | `omarchy-plugin-enable ivan.varhop-probe` | shell.json gets `{"id":"ivan.varhop-probe"}` |
| 4 | `omarchy-shell shell summon ivan.varhop-probe '{"probe":1}'` | Prints `ok`. A layer with namespace varhop-probe appears on the focused monitor (DP-2, 1600x1000). Screenshot: themed card over the scrim. open() receives the payload. |
| 5 | `wtype xyz` while summoned, then `shell hide` | close() logs `kept:"xyz"`: the overlay held keyboard focus and typing landed in TextInput. Layer gone after hide. |
| 6 | `shell toggle` twice | Layer count goes 1 then 0. The opens counter keeps increasing, so the item stays loaded across hides (keepLoaded). |
| 7 | Append `o.bind("SUPER + ALT + P", "Varhop probe", { panel = "ivan.varhop-probe" })`, `hyprctl reload` | `hyprctl binds -j` shows modmask 72 key P dispatcher `__lua` description "Varhop probe". No config errors. |
| 8 | `wtype -M logo -M alt p` | No summon. A virtual-keyboard chord does not prove or disprove the bind. The bind resolves to exec `omarchy-shell shell toggle 'ivan.varhop-probe'` (helpers.lua:80-87, 99-100), and that command is proven in row 6. |

| 9 | Operator pressed Super+Alt+P physically, typed, then pressed it again (2026-10-13) | The overlay opened, typed text was accepted, and it closed. The changed text was still there on reopen. The bind path and the draft-across-hide behavior are proven. |
| 10 | Cleanup: delete the bind line (cmp with backup), `hyprctl reload`, `omarchy-plugin-remove ivan.varhop-probe --yes`, delete the `.ivan.varhop-probe.bak.*` folder that remove creates for non-git plugins, rescan | sha256 of shell.json and bindings.lua equal the pre-proof values. No "Varhop probe" bind remains. listPlugins has no ivan.varhop-probe. No probe folder remains. |

Finding: `omarchy plugin remove` backs up non-git plugin folders as `.<id>.bak.<ts>` instead of deleting them (omarchy-plugin-remove:105-115). A git-installed varhop is deleted outright.
Limits: rows 4-6 use the CLI path that the bind executes. First-open layer behavior on the other two monitors is not yet observed.

## Proof 2: git install, update, clipboard chords (B F5/F9, C H10), 2026-10-13

Grant: operator 4a (overlay may appear during the build) and the overlay-plugin local live-install grant. Identity: user ivan's omarchy-shell session. Fixtures: two local git repos in the session scratchpad holding plugins `ivan.varhop-probe` and `ivan.varhop-probe2` (count 2, marker id prefix `ivan.varhop-probe`). Pre-state: shell.json sha256 459fbc8b…, clipboard text saved (54 bytes). Versions as above plus gh 2.102.0.

| # | Command | Observed |
|---|---|---|
| 11 | `omarchy plugin add file://<scratch>/repo --enable --yes` | Clones, validates, adds and enables. shell.json gets `{"id":"ivan.varhop-probe"}`. `omarchy-git-url-check` allows `file://`. |
| 12 | Commit v2 in the fixture repo, `omarchy plugin update ivan.varhop-probe --yes` | "Updated". Plugin HEAD moves to the new commit. The shell.json entry is byte-identical before and after. |
| 13 | Summon, then `hyprctl dispatch 'hl.dsp.send_key_state({ mods = M, key = K, state = "down" })'` and `"up"` 50 ms later, the exact sequence clipboard.lua:8-16 sends for Super+C/V (CTRL for browsers, CTRL SHIFT for terminal-tagged windows, :34-47) | On fresh `ivan.varhop-probe2` with a browser active underneath, the focused TextInput received `X/0`, `V/Ctrl+Shift`, `C/Ctrl+Shift`, `V/Ctrl` in order. Ctrl+V pasted natively. Ctrl+Shift+V pasted only through the probe's own handler, so Qt's TextInput does not paste on it by itself. |
| 14 | After the updates in row 12, plus disable then enable, summon and read the close log | The running shell kept executing the code first loaded from that plugin path in this shell session. Neither update, rescan nor disable/enable loaded the new QML, although shell.qml:1527 calls `Qt.clearComponentCache()`. Repeated on `ivan.varhop-probe2` (update adding a `rev` field): the field never appeared. |
| 15 | Cleanup: `omarchy-plugin-remove <id> --yes` for both, restore clipboard | Git checkouts deleted with no `.bak` folder. listPlugins and shell.json have no probe entry. shell.json sha256 equals 459fbc8b…. Clipboard bytes equal the saved copy. |

Finding: during rows 13-14 the operator's own typing landed in the focused probe twice. A live run that focuses the overlay competes with the operator's keyboard.
Finding: a plugin's new code reaches the running shell only through a fresh path or a shell restart (row 14). `omarchy-restart-shell` exists and refuses while the session is locked. It was not run.
Limits: the physical Super key path is not exercised (operator choice 1a, 2026-10-13). Row 14 shows that new code is not loaded. It does not prove that `omarchy-restart-shell` loads it.

## Proof 3: component test runner and text input routes (B F6, C H7), 2026-10-13

Identity: user ivan. Fixtures: two throwaway QML test files in the session scratchpad, run as short-lived `qmltestrunner` windows. Clipboard and primary selection saved before and restored after (byte compare ok). Versions: qt6-declarative 6.12.0-1, fcitx5 with only `keyboard-hr` (QT_IM_MODULE=fcitx).

| # | Command | Observed |
|---|---|---|
| 16 | `QT_QPA_PLATFORM=wayland qmltestrunner -input tst_paste.qml` with `keyClick(Qt.Key_V, Qt.ControlModifier)` and `mouseClick(..., Qt.MiddleButton)` on a TextEdit, clipboard `CLIP`, primary `PRIM` | Ctrl+V pasted `CLIP` from the real Wayland clipboard. The synthetic middle-click pasted nothing. Under `offscreen` neither pasted (no clipboard). 4 passed. |
| 17 | Same runner window focused, then `wtype -k dead_acute e`, and separately `hl.dsp.send_key_state` with keys `dead_acute`, `e`, `ccaron` | `č` arrived through the fcitx5 path. No route produced `é`: wtype gave `o`, key-state gave `i` then `e`. Dead-key composition and IME preedit are not reachable by the agent on this machine. |

Limits: the hr layout has no preedit engine configured. Middle-click primary paste needs a real pointer, and no pointer injection tool is installed (ydotool, wlrctl and dotool absent; hl.dsp has no click dispatcher).

## Proof 4: shell restart loads new plugin code (operator 3a), 2026-10-13

Grant: operator `3a` (2026-10-13). Fixture: plugin `ivan.varhop-probe3` from a scratchpad git repo (count 1). Pre-state: shell.json sha256 459fbc8b…, clipboard saved.

| # | Command | Observed |
|---|---|---|
| 18 | add v1 (`rev: 1` in the close log), summon/hide, commit v2 (`rev: 2`), `omarchy plugin update --yes`, summon/hide | Both close logs show `rev: 1`. The update did not load the new code. |
| 19 | `omarchy-restart-shell` (session unlocked), summon/hide | exit 0 in 1.6 s, `shell ping` ok, close log shows `rev: 2`. A restart loads the updated code. |
| 20 | Cleanup: `omarchy-plugin-remove ivan.varhop-probe3 --yes`, restore clipboard | No probe folder or entry. shell.json sha256 and clipboard bytes equal the pre-run values. |

Finding: the operator's typing landed in the focused probe again (`eli`).

## Proof 5: standalone Quickshell process failures (B recheck F11), 2026-10-13

Fixture: one scratchpad `shell.qml` run by `quickshell -p <file>` (Quickshell 0.3.2), no window, exits by `Qt.quit()`.

| # | Command | Observed |
|---|---|---|
| 21 | `Process` running `false`, a missing binary, and `sleep 10` stopped by a 500 ms Timer | `false`: onExited code 1. Missing binary: `running` turns false and onExited never fires. Stopped `sleep`: onExited code 15. The standalone runner exits 0. |

Finding: a failed start is visible only as `running` going false with no `exited`, so copy code must treat that as a failure.
