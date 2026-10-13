# Slot B review — 2026-10-13

Verdict: **fix**.

Base: `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`.
Reviewed head: `fc11a853b240dd79a445750d1b8279e538699047`.
Adopted product head: `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`.

Initial blind review. No peer review was opened or peer contacted. Debate is no, so positions-B/rebuttal-B are absent as expected. Code and tests were not edited, and no commit was made.

## Evidence

Read the authoritative brief, plan, design, readiness grants, implementation report and logs, reference index and README, and the archived brief/report/B review. Reviewed the whole base-to-head change, including carried root/view wiring, search/import changes, clipboard and QML proof boundaries, and the new keyboard helper. `git diff 0df6f48 HEAD` confirms the carried product and existing proof files are unchanged. The successor adds only the keyboard module/test and one reference-index link.

The configured test command in `implementation/check-test-1791889566749-681527.log` passes: **80 pass, 0 fail, 304 assertions**, 2.63 seconds. It includes all three planned keyboard cases and the existing QML checks. This run follows the latest helper change, f66ddad. HEAD is an empty trailer commit, and both HEAD and f66ddad have tree `cb5144e702ae912e59ab42631f43449106333c13`. No test, helper, fixture or runner changed after that run. No planned test is skipped, filtered or disabled. The earlier red new-module run and the live pass/deliberate-break logs establish the planned fail-first and deliberate-break evidence. No redundant full-check rerun was needed. `git diff --check 5cac0ae...HEAD` passes.

Criterion 2's table enumerates all archived bullets, including the explicitly transferred rows. Reviewed its archive references against the archived report and final review, including the later all-empty export evidence. The helper link exists. No AREA.md is in the reviewed diff. README's product behavior did not change relative to the adopted head. The new documented helper contract is reviewed below.

Read-only live inspection as local user ivan: installed clone is clean, enabled as `ivan.varhop`, origin is `file:///home/ivan/Work/omarchy-customizations/varhop`, and installed HEAD is f66ddad, not reviewed HEAD. `hyprctl layers -j` currently shows no varhop layer. The active window is foot. `/proc/bus/input/devices` has no varhop-* device. The implementation report records backup absence and cache/state/entry equality after its live runs. B created no fixture, changed no clipboard, sent no keys, restarted no shell and changed no installed configuration. GitHub retained resources were not accessed or mutated.

One safe CLI probe, with the overlay already absent, ran:

```text
bun test/keyboard.ts --device varhop-overlay-plugin-kbd --keys a --read field --expect a
error: No varhop layer is shown; refusing to send keys
  at main (test/keyboard.ts:143:38)
  at test/keyboard.ts:157:23
Exit: 1
No result JSON line.
```

This probe stops before clipboard capture or device creation. It confirms F2 without sending input. No red test/check comparison record is applicable: the failing operation is this helper's explicit environment refusal, whose cause is in the reviewed code.

## Fixes

### F1 — Keyboard delivery continues after the overlay disappears

Source: the operator's real shared desktop session during the intended live helper run. The report already observed foreign operator key events hiding the overlay around L2. Search Esc on an empty query hides (`qml/SearchBody.qml:81-84`); editor Esc hides too (`qml/EditorBody.qml:222-224`). Esc is an explicitly supported helper input, and the design's real uinput probe also uses two Esc presses to clear/hide.

Trace: `test/keyboard.ts:143` checks for a varhop layer once, before clipboard capture and virtual-device registration. Registration may wait up to three seconds (`76-81`). The send loop (`96-101`) then writes every event with 30 ms gaps without checking whether the layer still exists or retains keyboard focus. If the operator presses Esc while registration or the marker sequence is in progress, the remaining marker keys go to the underlying focused app. A helper sequence that hides the overlay likewise continues delivering subsequent presses, including the field-mode appended Ctrl+A/C (`142`). The current empty-layer refusal protects only the initial snapshot.

Consequence today: the reusable proof helper can type or issue shortcuts in the operator's terminal/browser after focus returns there. This violates readiness grant 2's bound, synthetic keys only while the overlay is focused, and the helper's scoped-input contract. This is traced from ordinary supported user actions, not an arbitrary handcrafted-input concern. B did not execute an out-of-overlay delivery to demonstrate an already traced violation.

Repair: verify the target again after device registration and prevent new key presses once overlay focus is lost during delivery, while safely releasing held keys and preserving cleanup. Keep intentional terminal actions such as hide/export usable. Prove the delivery boundary stops subsequent presses when the real overlay action hides it. Existing parser/device-lifetime tests do not catch this defect.

### F2 — Environment/usage errors violate the CLI exit-status contract

Source: the intended helper CLI called while the overlay is hidden, a state already encountered in the implementation's `live-L2-refused-hidden.log`. The safe current probe above reproduces it on HEAD.

Trace: plan D5 assigns exit 1 to an observed-text mismatch and exit 2 to usage/environment errors. `main` throws for the absent overlay at line 143 and `if (import.meta.main) main()` at line 157 leaves that error uncaught. Bun exits 1. The implementation report explicitly changes this interface to rely on the absence of a result line instead.

Consequence today: a caller following the planned status interface cannot distinguish a deliberate failed comparison from a run that never delivered keys by exit status. The report's alternative requires an extra output-parsing contract that the approved plan did not choose. This is a broken plan D5 CLI contract, observed in a normal live invocation, rather than a wording preference.

Repair: retain the error details and cleanup, and return exit 2 for usage/environment failures as planned. Add a fail-first CLI boundary reproduction using the missing/invalid argument or absent-overlay path. Existing tests cover only the module, not the CLI error status.

### F3 — Final installed revision is not the reviewed final commit

Source: the actual retained installed plugin checkout, verified with `git -C ~/.config/omarchy/plugins/ivan.varhop rev-parse HEAD` during this review.

Observed installed revision: `f66ddadaf97922a1e861d8b9ba5a3b2bd723041b`.
Reviewed final revision: `fc11a853b240dd79a445750d1b8279e538699047`.

Brief criteria 3 and 6 require the installed copy at this leaf's final commit. The report's final-head note confirms the install remains at f66ddad because the empty trailer commit was added after the last live step. Tree equality is enough to retain the unit and behavior proof evidence, but does not establish the explicitly required deployed revision. Consequently the criterion 3 install/restart and criterion 6 end-state handoff are incomplete at the actual final head.

Repair belongs to A because it requires the named live run. Finish code/trailer commits first, then repeat the planned L1-L4 installation/restart and end-state sequence at the resulting final head. The existing grant permits resetting the installed copy through the worktree origin and then restoring the main-tracking origin as the last step. Do not fetch/reset after the final origin change. Record the actual final deployed SHA and preservation/cleanup evidence.

## Nits and operator actions

None. The report's existing single-MIME and single-Hyprland-instance limitations are disclosed design ceilings, not new acceptance criteria. No reusable Nit or new lesson is asserted, and no learning file is changed.

## Test-Change assessment

The path rule in akrogon `src/test-files.ts` matches every file below test/, including helper/fixture scripts. It does not match qml/tst_views.qml, whose expectation changes still require substantive source evidence.

The trailers below were read across base..HEAD. Sources are supported by the archived B review's findings, repair entries, red/green logs and current brief/plan. In particular, the old merged-reset undo expectation was corrected against the archived brief's separate empty/reset edits, not against a cosmetic preference. Async delegate waits follow the actual ListView change. QtTest import/visibility/context-menu harness changes follow the actual Qt runner behavior. Wayland environment, timeout and clipboard changes retain assertions and respond to actual failing configured runs. The generator trailers' claim that plugin.test.ts consumes the generator is inaccurate, but the real consumer is the required live latency workload, documented in archived F13, and the generator correction has real import output. This does not invalidate its source. The new helper trailer cites current brief 4-5/plan D3 and changes no old expectation.

The final configured run is current for all these changes. No source-free deletion or weakened existing regression assertion was found.

### Recorded trailers

- `fc11a85`: Test-Change: test/keyboard.ts new uinput keyboard helper, the leaf's product per brief done-criteria 4-5 and plan D3 (lives beside test/clipboard.ts); no existing test expectation changed
- `0df6f48`: Test-Change: test/clipboard.ts F14 nonempty selection restoration waits on a daemon-held stderr pipe; capture errors in a cleaned temporary file while retaining exit and byte verification
- `ab63277`: Test-Change: test/clipboard.test.ts F14 configured QML checks time out while preserving the operator selections; reproduce byte-exact nonempty clipboard and primary restoration with a bounded child
- `5699fdf`: Test-Change: qml/tst_views.qml adds two red reproductions for F7 (draft undo history) and F8 (public query tracking); no existing expectation changed
- `3c875e7`: Test-Change: qml/tst_views.qml B F16 real LANGUAGE and DIFF edits followed by Tab navigation and Ctrl+Z change the wrong value; reproduce variable-local undo, redo retention and mirrors
- `360a9af`: Test-Change: qml/tst_views.qml added tryVerify/waitForRendering for async ListView delegates; no existing expectation changed
- `85ccf70`: Test-Change: qml/tst_views.qml reproduced the fixed defect (covers chronological undo across delete-reset boundaries, draft prompt-id scoping, refresh selection retention, and the merged empty/reset undo steps)
- `85ccf70`: Test-Change: qml/tst_views.qml covers new regression expectations for the same component behavior
- `02bd828`: Test-Change: test/clipboard.ts B F14 configured QML checks replace an empty operator clipboard and cannot restore under scrubbed session env; share capture, restore and byte verification for both selections
- `b8c1653`: Test-Change: test/make-library.sh B F13 planned latency fixture produced literal backslash-n and 15KB bodies; generate real lines and 20480-byte bodies for criterion 4g
- `b340c1f`: Test-Change: qml/tst_views.qml B F12 typing the displayed spaced chord does not become ready and accepts @; add the settings input boundary reproduction
- `a91f396`: Test-Change: qml/tst_views.qml B F10 emptying a repeated variable shows token text absent from export and no unset count; add the real editor boundary reproduction
- `0bbb64a`: Test-Change: qml/tst_views.qml B F6 real zero-variable prompt opening emits an unhandled signal; reproduce the actual copier invocation and text
- `0960fec`: Test-Change: test/copier.test.ts reviews A F1 and B F5 trace repeated real prompt exports through the retained Copier; add consecutive stdin boundary reproduction
- `d793e32`: Test-Change: test/views.test.ts B F14 configured component checks changed the operator clipboard; preserve and verify both selections without changing assertions
- `d793e32`: Test-Change: test/copier.test.ts B F14 empty selection and scrubbed Wayland env were not restored; use the shared preservation boundary without changing assertions
- `61c742e`: Test-Change: test/make-library.sh new fixture generator for the synthetic library bundle used by plugin.test.ts; added in this leaf's test pass
- `9eb5f84`: Test-Change: test/views.test.ts scan the wayland socket in a waylandEnv helper so the runner connects under run-check's scrubbed env; no existing expectation changed
- `9eb5f84`: Test-Change: test/copier.test.ts same waylandEnv helper for the quickshell spawn; no existing expectation changed
- `9eb5f84`: Test-Change: test/views.test.ts raise the bun test timeout to 60s; qmltestrunner needs ~6s under wayland, above the 5s default
- `9eb5f84`: Test-Change: test/copier.test.ts same 60s timeout for the quickshell runner
- `dea832c`: Test-Change: bump views.test.ts and copier.test.ts test timeouts to 60s
- `fef6396`: Test-Change: qml/tst_views.qml adjusted during implementation: QtTest import (QtQuick.Test module name is wrong on Qt 6.12), visible:true on created items (createTemporaryObject defaults to invisible) and context menu driven via v.ContextMenu.menu since synthetic clicks never produce QContextMenuEvent; no expectation weakened

## Phase result

`akrogon phase overlay-plugin check.repair --slot B --verdict fix` returned **moved check.repair**.

# check.repair — 2026-10-13

Starting head: `fc11a853b240dd79a445750d1b8279e538699047`. Read both initial reviews at this head. A F1 and B F1 concern the same delivery boundary. B F2 and B F3 also remain open. No operator-only action is open.

## Handed to A

- **A F1 / B F1:** proven keyboard-delivery defect requiring a live rerun. Plan criteria 4 and 5 explicitly rerun whenever test/keyboard.ts changes, and any repair commit also requires the final-head L1-L4 sequence. The check-issue repair rule hands a proven product defect whose repair needs a live rerun to A. Repair the stale pre-registration check and continued presses after hide together, preserve held-key release/device/clipboard cleanup, and commit the fail-first reproduction before the fix. A's suggested single pre-send check addresses registration delay but does not alone address B's during-sequence hide trace.
- **B F2:** proven CLI exit-status defect requiring a live rerun under the same test/keyboard.ts rerun trigger. Restore plan D5's exit-2 error interface, preserve detailed error output and cleanup, and commit its fail-first CLI reproduction separately from F1. Do not change an existing test expectation or replace the plan's interface in the report.
- **B F3:** required live installation/restart and final-state run. Complete every code and trailer commit first, then perform L1-L4 at the actual final head, including criteria 4-5 after helper changes. Keep the final origin change last, preserve entry/cache/state/selections, and record deployed revision and fixture absence.

B makes no partial code repair because both behavior fixes require the live rerun assigned to A by the skill. No reproduction test, product edit, plan/design edit or commit is made in this pass. No peer Nit is adopted as a new Fix. No reusable B Nit remains.

## Verification and grant use

The blocking check uses readiness grant 2 as local user ivan for the existing short-lived QML windows, clipboard/primary preservation and virtual-device lifetime test. It does not send uinput keys or change the retained install, shell.json, cache/state or GitHub. Existing fixture markers: varhop-keyboard-test-kbd and temporary varhop-clipboard-* directories, cleaned by their test helpers. The configured command includes its install lock and setup. Current-run outcome and device-absence read-back are recorded below after completion. Criteria 2-5's existing evidence remains current for the unchanged tree, with F1/F2 open and criterion 6's deployed-SHA gap F3 assigned above. No merge-check command is configured or run.

Configured check: exit **0**, **80 pass, 0 fail, 304 assertions**, 2.57 seconds. Log: `implementation/check-test-1791890707034-2727266.log`. It initially waited for the shared run permit held by another repository, then completed normally. Read-back: **0 varhop devices**, **0 varhop-clipboard-* directories** in this pass's temporary directory. No comparison record needed.

Repair-phase result: `akrogon phase overlay-plugin check.fix --slot B` returned **moved check.fix**. Head remains fc11a853b240dd79a445750d1b8279e538699047, worktree clean. No Fix repaired by B, three B findings (including duplicate A F1) handed to A for the required live rerun.

# check.review re-check — 2026-10-13, slot B

Verdict: **ready**.

Prior reviewed base: `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`.
Prior reviewed head: `fc11a853b240dd79a445750d1b8279e538699047`.
Handed-off base: `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`.
Reviewed head: `b210f39da935cb944cd51cf2fe2501c657a276a2`.

Computed `git range-diff <prior base>..<prior head> <handed-off base>..<handed-off head>` independently. All 37 earlier commits are unchanged. Only four repair commits were added: `8aebd1e`, `97f83e7`, `90e7331`, `b210f39`. Reviewed their complete diff in test/keyboard.ts and test/keyboard.test.ts, the dated plan clarification, and the updated report. No branch refresh, conflict resolution or rejected merge check needs replay. `git diff --check` passes and the worktree is clean.

## Earlier findings

- **F1 / A F1 closed:** CLI delivery now passes every event through `deliver`, which checks the layer after registration and before every press. Layer disappearance releases held keys and throws before another press. Existing device and clipboard finally blocks still run. The current unit check covers held-key release and refusal. `live-fix-F1-hide.log` records the real search Esc action hiding the overlay, refusal of the subsequent Shift press, exit 2 and no result line. The report records device absence and restored selections. The pre-fix test log fails at the missing `deliver` export, rather than executing a behavioral assertion, so it alone does not reproduce the old delivery defect. The earlier realistic trace establishes the old defect; the current executable guard and real CLI hide probe establish the repaired behavior.
- **F2 closed:** the CLI boundary prints the original error and assigns exit 2 after cleanup. `fix-red-F2.log` shows the actual old status 1 against expected 2. The final check runs the same assertion green. B independently ran `bun test/keyboard.ts --device varhop-overlay-plugin-kbd --keys a --read field --expect a` after confirming no varhop layer: exit 2, detailed absent-layer error on stderr, no result JSON. This stops before clipboard capture or device creation. Mismatch still exits 1, proven by `live-fix-L3-break.log`.
- **F3 closed:** independent read-back of the retained installed clone gives full HEAD `b210f39da935cb944cd51cf2fe2501c657a276a2`, clean status, and origin `file:///home/ivan/Work/omarchy-customizations/varhop`. `omarchy plugin list` shows ivan.varhop enabled. The report records L1-L4 at that final revision, restart/summon without QML errors, unchanged shell entry/cache/state, and final origin change with no later fetch/reset. The named backup is absent on B's read-back.

## Verification and documentation

Read `implementation/check-test-fix.log`: configured test check, **82 pass, 0 fail, 309 assertions**. The tested `f47bf63` tree and reviewed `b210f39` tree both equal `a90a85b101693b0a4dd4449cf2f4a9d953ebf3b1`; the amendment changes only the commit message. Both added cases and all their unchanged helpers were present in that run. No planned test or runner was skipped, filtered or disabled. Current sufficient evidence makes another full check unnecessary.

Read the final live logs: known-good field read-back is `vhmaxk`, exit 0; deliberately missing marker key produces `vhaxk` against `vhmaxk`, exit 1. The updated report preserves the criterion-to-evidence table and explicitly owned rows. The helper repair changes no carried plugin behavior and invalidates no archived product evidence.

Opened the helper's CLI documentation and docs/reference-index.md. The documented exit status now matches plan D5 and the implementation. No documented plugin behavior changed. No AREA.md occurs in the repair diff. The report and plan disclose the remaining per-press sampling window and focus-without-layer-change ceiling; these are not new defects introduced by this repair.

## Added Test-Change trailers

The earlier base..HEAD trailers remain assessed above. These are the new trailers, judged against the cited prior findings and evidence:

- `8aebd1e`: `Test-Change: test/keyboard.test.ts review-B F2 the real CLI called with an invalid --device (and with the overlay hidden, live-L2-refused-hidden.log) exits 1, contradicting plan D5's exit 2 for usage and environment errors; adds one case, no existing expectation changed`.
- `90e7331`: `Test-Change: test/keyboard.test.ts review-A F1 and review-B F1 the operator's own input hid the overlay during this leaf's live L2 run (live-L2-refused-hidden.log), and the helper checks the layer once before a 3 s registration and never during the sequence, so later presses reach the operator's focused window; adds one case, no existing expectation changed`.
- `b210f39`: `Test-Change: test/keyboard.ts review-A F1, review-B F1 and review-B F2 the helper sent presses after the overlay hid and exited 1 on usage and environment errors; check the layer before every press, release held keys, and exit 2 on errors per plan D5; no existing expectation changed`.

Sources are the previously recorded real session and CLI failures. No old expectation was altered or deleted. `97f83e7` changes the same helper file, covered by the final helper trailer in this batch.

## Grants, cleanup and disposition

B used readiness grant 2 as local user ivan only for read-only layer/plugin/device inspection and the already-hidden-overlay refusal probe. B sent no synthetic keys, created no device or backup, changed no clipboard/configuration, restarted no shell, and mutated no retained resource. Read-back finds no varhop-* device and no recorded backup folder. GitHub grant 1 was unused.

No repair-introduced Fix, reusable Nit or operator action remains. No comparison record is needed: no blocking check is red, and the intentional CLI refusal is the expected exit-2 outcome. No code edit, commit or learning-file change was made.

Re-check phase result: `akrogon phase overlay-plugin merge --slot B --verdict ready` returned **moved merge**.

# merge — 2026-10-13, slot B

Attempt: `d87f7357-e1a4-4260-91dd-bb6ae61c4a07`. Applied top: `b210f39da935cb944cd51cf2fe2501c657a276a2`. Refreshed AKROGON_BASE: `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`. Batch has no carried members. HEAD equals the prompt top and worktree status is clean. No fetch, rebase, edit or commit was made on the applied stack.

Ran the complete configured check, with no merge_covers exclusions:

```sh
akrogon run-check --name 'test' -- sh -c 'flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c '\''bun install'\'' && akrogon guard own-modules && sh -c '\''bun test --pass-with-no-tests'\'''
```

Exit 0: **82 pass, 0 fail, 309 assertions**, 2.53 seconds runner time. Log: `implementation/check-test-1791891115517-3377152.log`. Setup and own-modules guard passed. No merge_checks or advisory commands are configured. No comparison record was needed.

Readiness grant 2, local user ivan, covers the existing test windows, restored clipboard/primary and the short-lived `varhop-keyboard-test-kbd` device. No synthetic keys were sent. Read-back finds no varhop-* device. The tests clean their own fixtures. Retained installed plugin, shell configuration, cache/state and GitHub were not mutated by this merge pass.

`akrogon phase overlay-plugin merged --slot B --check --attempt d87f7357-e1a4-4260-91dd-bb6ae61c4a07` returned `ok`, accepting the tested top and Test-Change trailers.

Completion-owner inspection: read overlay-rework/ISSUE.md and both leaf briefs. The other leaf, overlay-rework, remains open and depends on this landing, so this single-member batch does not complete the owner. Broadcast is required only if the final command prints an issue/epic complete line.

Final command returned `moved merged` and `deployed 5cac0ae48aa8..b210f39da935`, exit 0. No issue/epic complete line was printed, so no broadcast was sent.
