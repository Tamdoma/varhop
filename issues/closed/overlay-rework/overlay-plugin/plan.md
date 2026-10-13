# Plan: overlay-plugin

Debate: no. This plan is synthesized directly from brief.md and design.md.

## Preflight (recorded 2026-10-13, slot A)

- Worktree `/home/ivan/.akrogon/worktrees/varhop/overlay-plugin` HEAD = `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`, `git status --short` empty, 33 commits ahead of main. Brief's first step holds.
- Blocking `test` check on untouched 0df6f48: 77 pass, 0 fail. No repair is needed under split 2a, so this leaf plans none. A repair appears only if a later check fails on untouched code.
- `akrogon status overlay-plugin`: `env_names: []`, no `Missing:` lines. The design names no credential variable. No human-only blocker.
- Installed copy `~/.config/omarchy/plugins/ivan.varhop`: HEAD 0df6f48, origin `file:///home/ivan/.akrogon/worktrees/varhop/overlay-plugin`.
- `/dev/uinput` ACL `user:ivan:rw-`. Bun 1.4.3. `uv` and `qmltestrunner` are not on PATH (the existing view tests resolve their runner themselves).
- Probe (scratch, deleted): `bun:ffi` `dlopen("libc.so.6")` `ioctl` with UI_SET_EVBIT, UI_SET_KEYBIT, UI_DEV_SETUP (92-byte struct), UI_DEV_CREATE created `varhop-overlay-plugin-probe` in `/proc/bus/input/devices`; UI_DEV_DESTROY plus close removed it. No keys were sent.

## Read first

1. `issues/open/overlay-rework/overlay-plugin/brief.md`, `design.md`, `readiness.yaml` (grants and fixture rules).
2. `issues/chart/overlay-rework/archive/overlay-plugin/brief.md` (the archived done-criteria the table must list).
3. `issues/chart/overlay-rework/archive/overlay-plugin/implementation/report.md` ("Done-criterion evidence" and every F15 live section) and `review-B.md`.
4. `docs/reference-index.md`, `README.md`.
5. `test/clipboard.ts` (`withClipboardRestored`, `waylandEnv`) and `test/clipboard.test.ts`.
6. `Varhop.qml:743-760` (OverlayWindow, `WlrLayershell.namespace: "varhop"`), `qml/FieldKeys.js` (search field Ctrl+C copies the selection), `qml/SearchBody.qml:90-125`.
7. `learnings/LESSONS.md` is empty. No lesson applies (gap noted, nothing invented).

## Decisions

- D1. Product code at 0df6f48 lands unchanged. The check passes on untouched code, so no repair is planned. A repair, if one becomes necessary, follows split 2a: smallest change, fail-first test, listed in the report with its reason.
- D2. The helper is TypeScript run by bun, using `bun:ffi` against libc `ioctl` on `/dev/uinput`. Reason: bun is already the project runtime and test toolkit, the clipboard save and restore helper already exists in TypeScript (`test/clipboard.ts`, reused, not duplicated), and the FFI route needs no new dependency. The design's "python-evdev today" is replaced by this choice, which the design delegates to the plan. Nothing is added to `package.json` because nothing new is installed. Note for review: the design's dependency-recording rule is satisfied vacuously.
- D3. Location and names: `test/keyboard.ts`, a module plus CLI (`import.meta.main`). It ships in the plugin repo next to the existing live-proof helpers in `test/`.
- D4. Module interface:
  - `type KeyEvent = {code: number, value: 0 | 1}`.
  - `parseSequence(text: string): KeyEvent[]`. Tokens are separated by spaces. A token is a chord of names joined by `+`. Names are Linux key names, lowercase, without `KEY_` (`a`-`z`, `0`-`9`, `left`, `right`, `up`, `down`, `home`, `end`, `tab`, `enter`, `esc`, `backspace`, `delete`, `space`, `comma`, `period`, `minus`, `slash`) plus modifiers `ctrl`, `shift`, `alt`, `super` (KEY_LEFTCTRL 29, KEY_LEFTSHIFT 42, KEY_LEFTALT 56, KEY_LEFTMETA 125). A chord presses its names left to right and releases them right to left. An unknown name throws an `Error` naming the token.
  - `withKeyboard<T>(name: string, run: (send: (events: KeyEvent[]) => void) => T): T`. Creates the uinput keyboard (EV_KEY plus every code in the name table), waits until `hyprctl devices -j` lists a keyboard with that name (3 s limit, then throws), runs `run`, and destroys and closes the device in `finally`. `send` writes each event as a 24-byte `input_event` followed by EV_SYN, with a short gap between keys.
- D5. CLI: `bun test/keyboard.ts --device <name> --keys "<sequence>" --read field|clipboard|none [--expect "<text>"]`.
  - `--device` must start with `varhop-` (readiness marker). The live runs here use `varhop-overlay-plugin-kbd`.
  - Before creating the device it requires a layer with namespace `varhop` in `hyprctl layers -j`, else exits 2 without sending keys (grant bound: keys only while the overlay is shown).
  - The whole run sits inside `withClipboardRestored`, so clipboard and primary bytes are saved before the sequence and restored and byte-compared after it, on both outcomes.
  - `field` sends `ctrl+a ctrl+c` after the sequence and reads the clipboard. `clipboard` reads the clipboard the sequence left. `none` compares nothing. Reads poll `wl-paste --no-newline` until it equals `--expect` or 2 s pass. The last read is the observed text.
  - Output is one JSON line on stdout: `{"result":"pass","observed":...}` with exit 0, or `{"result":"fail","expected":...,"observed":...}` with exit 1. Usage or environment errors throw with exit 2.
  - The hr layout maps KEY_Y to z and KEY_Z to y. The helper takes key codes, and the report states this mapping.
- D6. Known-good sequence (criterion 4): `--keys "ctrl+a backspace v h m a r k left shift+left x" --read field --expect vhmaxk`. It types the marker `vhmark`, moves the caret before `k`, selects `r` with Shift+Left and replaces it with `x`.
- D7. Deliberate break (criterion 5): the same sequence with the `m` key removed, still `--expect vhmaxk`. Expected result: exit 1 with observed `vhaxk`.
- D8. Live runs are serial in the operator's one shell session. A typed-text check whose observed text shows foreign keys is repeated once (standing design).
- D9. Cache and state: the backup fixture (`<implementer scratch>/varhop-backup`, path written into the report before creation) is taken before L1 even though no planned step writes there, because a shell restart and summon are not proven write-free. Cleanup restores byte-identical and deletes it.
- D10. Report location: `issues/open/overlay-rework/overlay-plugin/implementation/report.md` in the leaf folder. Archived criteria are numbered by bullet order (1a-1d, 2a-2g, 3a-3e, 4a-4g, 5a-5f, 6a-6c, 7a-7c, 8a-8c, 9, 10a-10b), matching the archive report's own labels (2e, 5f, 6b, 7c).
- D11. Docs: `docs/reference-index.md` gets one line pointing to `test/keyboard.ts` as the live keyboard helper. README is unchanged (the helper is proof machinery, not plugin behavior).

## Units and waves

Serial-solo: every wave holds one unit, so A implements without workers.

### Wave 1: U1 keyboard helper
- Owns: `test/keyboard.ts`, `test/keyboard.test.ts` (committed in this pass as the red test), `docs/reference-index.md`.
- Shared test resource: `/dev/uinput` (device creation only, no keys sent by the test).
- Depends on: nothing.
- Done when `test/keyboard.test.ts` is green and the full `test` check passes.

### Wave 2: U2 live proofs and report
- Owns: `issues/open/overlay-rework/overlay-plugin/implementation/report.md` and its logs. No worktree path.
- Shared test resource: the operator's omarchy-shell session, keyboard focus, clipboard and primary, the installed plugin clone, the shell.json `ivan.varhop` entry, `~/.cache/varhop`, `~/.local/state/varhop`.
- Depends on: U1 committed. The final commit must exist before L1.
- Steps, each a restart boundary (an interrupted run restores from the backup and restarts at the interrupted step; any new commit restarts at L1):
  - L0. Record the final commit SHA and clean tree. Save `jq -c '.plugins[]|select(.id=="ivan.varhop")' ~/.config/omarchy/shell.json` and the file's sha256. Save clipboard and primary bytes to scratch. Write the backup path into the report, then `cp -a` both directories into it.
  - L1 (criterion 3). `omarchy-plugin-validate <worktree>`. In the installed clone: `git remote set-url origin file:///home/ivan/.akrogon/worktrees/varhop/overlay-plugin`, `git fetch origin overlay-plugin`, `git reset --hard <final SHA>`. `omarchy-restart-shell` (session unlocked). `omarchy-shell shell summon ivan.varhop`, then `hyprctl layers -j` shows namespace `varhop`. `journalctl --user --since <restart time>` has no QML error naming the plugin path. Entry compared to L0.
  - L2 (criterion 4). Overlay summoned on search. Run D6. Expect exit 0.
  - L3 (criterion 5). Overlay summoned on search. Run D7. Expect exit 1 with expected and observed text. Then `omarchy-shell shell hide ivan.varhop`. `grep -c 'varhop-' /proc/bus/input/devices` is 0. Clipboard and primary bytes equal the L0 copies (`cmp`).
  - L4 (criterion 6, last live step). `git -C ~/.config/omarchy/plugins/ivan.varhop remote set-url origin file:///home/ivan/Work/omarchy-customizations/varhop`, no fetch or reset after it. Verify installed HEAD = final SHA, plugin listed enabled, entry equals L0, `diff -r` plus mode and mtime-independent byte compare of cache and state against the backup (restore from it if different and record why), then delete the backup and confirm it is absent.
  - Report (criterion 2): the criterion-to-evidence table, the helper contract from D4-D5 with the hr Y/Z note, each live step's command and result, the repair list (expected: none), and the post-merge operator checklist from design.md copied into completion notes.

## Done-criteria, proofs and tests

| # | Proof command | Catches | Size | Rerun trigger |
|---|---|---|---|---|
| 1 | `akrogon run-check --name 'test' -- sh -c '<configured test check>'` (runs `bun test`, including `test/keyboard.test.ts`) | Broken helper parsing or device cleanup, any regression in the existing 77 tests | seconds (~10 s) | Any commit |
| 2 | Read `implementation/report.md`. Every archived bullet (D10 labels) has one row with evidence at 0df6f48 or the final commit. 5f, 6b, 7c success and the reset-button click (8b) read "owned by overlay-rework". | Missing archived criterion, evidence that does not exist, an owned row claimed as proven | minutes | Any repair commit (re-prove affected rows) |
| 3 | L1 commands above | Plugin that fails validation, stale code after restart, QML load errors, entry rewritten by the update | minutes | Any commit after the last L1 |
| 4 | L2: `bun test/keyboard.ts --device varhop-overlay-plugin-kbd --keys "ctrl+a backspace v h m a r k left shift+left x" --read field --expect vhmaxk` | Helper that does not deliver arrows, Shift selection or replacement, or that misreads the field | seconds | Change to `test/keyboard.ts`, or foreign keys observed (repeat once) |
| 5 | L3: same command without the `m` token, then the device and clipboard checks | Helper that passes on wrong text, leaks the device, or does not restore clipboard and primary | seconds | Same as 4 |
| 6 | L4 commands above | Install left on the worktree origin, disabled plugin, changed selection, changed operator cache or state, leftover backup | minutes | Any commit after L4 (repeat L1-L4) |

Criteria 2-6 are live or documentary, proven by U2 with existing tools plus the product helper. No new proof machinery is needed.

### Tests written at plan.synthesis

`test/keyboard.test.ts` covers the helper at the smallest real boundary (criterion 1, and the mechanism behind 4 and 5):
- `parseSequence("ctrl+shift+left a")` gives presses 29, 42, 105, releases 105, 42, 29, then press and release 30.
- `parseSequence("ctrl+nope")` throws naming `nope`.
- `withKeyboard` makes a `/proc/bus/input/devices` entry with its name during `run` and none after, including when `run` throws.

Red at commit `1ec6a6d` (test only, before any helper code), log `implementation/plan-red-keyboard.log`:

```text
test/keyboard.test.ts:
error: Cannot find module './keyboard' from '.../overlay-plugin/test/keyboard.test.ts'
 0 pass
 1 fail
 1 error
```

Full `test` check at `1ec6a6d`: 77 pass, 1 fail, 1 error. The only failure is this planned red. The other 77 are the untouched 0df6f48 suite.

## Open limitations

- The helper cannot click. Pointer clicks on layer surfaces are undeliverable on this host (archive report I2), so the reset-button click stays with overlay-rework (keyboard route per proof-bar 4a).
- Physical Super key and physical paste are not exercised here. They stay on overlay-rework's checklist.
- `Ctrl+A` select-all in the search field is assumed native Qt behavior (FieldKeys.js does not intercept it). L2 is its first live proof. If it fails, the field read-back changes, not the plugin.

## Implementation notes (2026-10-13, check.fix round 1)

- Refines D5 (layer check). The check before device creation stays, and the send loop also checks the `varhop` layer immediately before every key press (`deliver` in `test/keyboard.ts`). When the layer is gone it releases held keys, sends no further press, and fails as an environment error. A sequence whose own key hides the overlay (Esc) still delivers that key. Any press after it is refused. Executable check: `test/keyboard.test.ts` "no press goes out once the overlay is gone".
- D5 exit status stands as written: usage and environment errors exit 2, message on stderr, no result line. Executable check: `test/keyboard.test.ts` "a usage error exits 2".
- Ceiling: the window between the per-press `hyprctl layers` call and the write is one call long, and focus loss without a layer change is not detected.
