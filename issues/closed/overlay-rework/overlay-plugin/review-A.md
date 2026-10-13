# Slot A review

Base `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`. Reviewed head `fc11a85` (tree equal to `f66ddad`). Diff over adopted `0df6f48`: `test/keyboard.ts` (+157), `test/keyboard.test.ts` (+28), `docs/reference-index.md` (+1). No product file changed.

## Evidence

- Configured `test` check at `f66ddad`: 80 pass, 0 fail (`implementation/check-test-1791889566749-681527.log`). `fc11a85` is empty, so no rerun.
- Planned tests: `test/keyboard.test.ts` red at `1ec6a6d` (`implementation/plan-red-keyboard.log`), green at `f66ddad`. No planned test skipped or filtered.
- Live: `implementation/live-L2-pass.log` (pass `vhmaxk`), `live-L3-break.log` (fail, observed `vhaxk`), `live-L2-refused-hidden.log` (guard refused while the overlay was hidden). Report rows for criteria 3 and 6 record commands and results.
- Docs: `docs/reference-index.md` gains one pointer, and `test/keyboard.ts` exists. README describes plugin behavior, which did not change. No AREA.md in the diff.
- Criterion 2 table spot-checked: AR:28 (level 3 on three monitors), AR:117-123 (2e, 2g, 2f, 4d, 7c failure, 8, 10), AR:180-186 (all-empty zero bytes), AR:190-194 (pointer clicks) match their rows. Rows 5f, 6b, 7c success and 8b read "owned by overlay-rework".

## Fixes

### F1: the overlay check runs seconds before the keys are sent

`main` calls `varhopLayerShown()` (test/keyboard.ts:143) before `withClipboardRestored` reads both selections, before the device is created, and before `waitForKeyboard` polls Hyprland for up to 3 s. Only after all that does `send` run (test/keyboard.ts:146-147).

- Realistic source: the operator's own input hides the overlay. This happened during this leaf's L2 run. After summon, four foreign `varhop-search` key events arrived at 13:06:39 and the overlay was hidden before the helper ran (`live-L2-refused-hidden.log`). A hide inside the check-to-send window sends the sequence to whatever window then has focus.
- Consequence today: criterion 4's sequence starts with `ctrl+a backspace`, and `field` mode appends `ctrl+a ctrl+c`. In an editor that selects and deletes the operator's text. In a terminal, `ctrl+c` interrupts the foreground process.
- Hits: readiness grant 2 bound "synthetic keys only while the overlay is focused (checked ... before sending)", and plan D5 ("Before creating the device it requires a layer ..."). The check exists but is stale by the time keys go out.
- Repair: move the `varhopLayerShown()` check into the `withKeyboard` callback, immediately before `send(events)`. The window shrinks from device setup plus registration (up to 3 s) to one `hyprctl` call. No test change. Criteria 4 and 5 rerun live after it (plan rerun trigger "change to `test/keyboard.ts`"), which also moves criteria 3 and 6 to the new head.

## Nits

- N1. `let observed: string | null` is assigned inside a closure and compared afterwards (test/keyboard.ts:144-151). TypeScript control flow narrows it to `null` there, so a strict type check would flag the comparison. It runs correctly, and no type check is configured (no bun types installed). Would become a Fix if the repo adds a `tsc` check.
- N2. `clipboard` and `field` reads pass on the first poll when the clipboard already held the expected text, even if the sequence copied nothing. The caller controls the pre-state, and criteria 4 and 5 start from an unrelated clipboard (a PNG). Would become a Fix with an overlay-rework criterion whose pre-run clipboard equals its expected text.
- N3. The installed clone sits at `f66ddad`, not the final SHA `fc11a85`. The trees are equal, and the brief forbids a fetch after the final origin change. Any repair commit for F1 reruns L1-L4 on the new head anyway.

## Verdict

fix (F1).
