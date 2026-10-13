# Slot B review — 2026-10-13

Verdict: fix.
Base: b210f39da935cb944cd51cf2fe2501c657a276a2.
Reviewed head: fa71cf010c77ea0edf9b4c794199f98fa518efed.
Scope: the whole base-to-head diff, plan, design, brief, implementation report and affected README key contract. Leaf debate is no; no positions-B.md or rebuttal-B.md exists. Peer review was not read.

## Fixes

### F1 — Plain Tab into the header loses the body's input focus on return

Source: the documented keyboard flow in search: type x, press plain Tab to Settings, then Esc (or Ctrl+Tab) to resume typing. Card.qml:130-139 remembers the body focus only through focusHeader(), which plain Tab does not call. focusBody() consequently focuses SearchBody's plain Item rather than queryField. The header releases focus but the text field cannot receive typing. This breaks brief criterion 4 and plan D6: header Esc/Ctrl+Tab must return to the body's last focus item with its state intact.

Live component reproduction on the reviewed head: makeCard({}), wait for queryField.activeFocus, keyClick("x"), plain Tab until settingsButton.activeFocus, keyClick(Escape), then verify(queryField.activeFocus). The final assertion is false. QtTest result: 2 passed, 1 failed, runner exit 1. Trace: implementation/review-B-focus.log. Existing test_plain_tab_reaches_header_and_space_presses only activates the header button; the round-trip test enters through Ctrl+Tab, so neither catches this failure.

Repair: preserve the last body focus for every path into the header and return to that actual input item. Add the failing plain-Tab/return reproduction before the fix.

### F2 — Native Shift+Delete cuts rejected prose selections to the clipboard

Source: in the inline editor, enter a filled value, select the line with Ctrl+Home then Shift+End, and use the standard Shift+Delete Cut shortcut. EditorBody.qml:355-370 intercepts Ctrl+X but permits Shift+Delete through to TextArea. Native Cut changes the clipboard before the deferred guard restores the prose. The rejected action therefore overwrites the user's clipboard with prompt prose, violating brief criterion 3 and D4's explicit requirement that a rejected cut never touches the clipboard.

Live component reproduction on the reviewed head: seed clipboard with SENTINEL; open "A {{X}} b"; type value; Ctrl+Home, Shift+End selects "A value b"; Shift+Delete; wait for the guard. Text is restored to "A value b", but a clipboard paste reads "A value b" instead of SENTINEL. QtTest result: 2 passed, 1 failed, runner exit 1. Trace: implementation/review-B-cut.log. This uses real keyboard shortcuts through TextArea, not an injected invalid data structure. test_editor_prose_never_changes checks only Ctrl+X and misses this native cut route.

Repair: route the native Cut shortcut through the same guarded cut() path. Add the failing clipboard-preservation reproduction before the fix.

## Verification

- Read the reference index, README, full brief/plan/design/report, current components, root wiring, affected tests and search cache diff. Compared the menu surface with installed Emojis.qml. No AREA.md changed. README's updated keyboard contract is implicated by F1; the other documented changes match the intended behavior.
- The final-head configured test check has complete green evidence in implementation/check-test-1791910073795-1067274.log: 84 pass, 0 fail, including both QML suites. The latest changed test and its dependencies precede that run. No planned runner or case is skipped or disabled. The earlier same-head theme case failure is recorded as inconsistent in implementation/compare-test.yaml and passed on its one retry. No full-check rerun was needed for this review.
- The report and scratch/live.md record final-head OA1/OA2/OA3, Ctrl+Tab, reset isolation and restore. Read-only verification found installed HEAD fa71cf010c77ea0edf9b4c794199f98fa518efed, origin file:///home/ivan/Work/omarchy-customizations/varhop, and no remaining scratch/varhop-backup. Criterion 8's post-merge checklist is present.
- Ran setup under the worktree's akrogon-install.lock, then targeted qmltestrunner probes on Wayland using the existing component helpers and test/clipboard.ts. Authorization: readiness.yaml grants[1], local user ivan, qmltestrunner on Wayland and clipboard save/restore. Both probes exited normally with one failed assertion each. Clipboard and primary were restored and byte-compared by withClipboardRestored. No external fixture IDs were created, no retained install was mutated, and temporary probe files were deleted.
- git diff --check b210f39...HEAD passed. Worktree remains clean. No code edits or commits were made during review.

## Test-Change trailers

src/test-files.ts matches test/views.test.ts and test/plugin.test.ts. It does not match qml/tst_views.qml or qml/tst_card.qml.

61e137abb944d4b31bf1d7c5ba48d1856426e575:
- Test-Change: test/views.test.ts plan.md criteria 1-5: run tst_card.qml beside tst_views.qml
- Test-Change: test/plugin.test.ts plan.md criterion 2b: static check of the Emojis surface recipe in Varhop.qml

These sources justify adding the card suite and surface assertion. The old view suite still runs.

e0081df0c090b4309c56b3c8b3b9752f85903ff2:
- Test-Change: qml/tst_views.qml adds test_search_rank_survives_replaced_libraries; no existing expectation changed. Source: the live Omarchy shell segfaulted in QV4 WeakMap.get under Sea.rank (coredumps 2934914 at 2026-10-13 13:27 on b210f39 and 1945630-1963336 at 14:02 on 323d3f2); the case segfaults qmltestrunner on 323d3f2.

The report records the real library-replacement source and fail-before/pass-after. The new reproduction and bounded replacement caches address that mechanism.

## Operator actions

None.

## check.repair — 2026-10-13

Reviewed both initial reviews at fa71cf010c77ea0edf9b4c794199f98fa518efed. No operator actions are open. No code edits or commits were made.

### Handed to A

- A/F1: Settings controls receive focus below the visible card. This product repair requires the live reset-isolation keyboard proof (criterion 5), and plan W4 requires a fresh live sweep after any code commit. check-issue assigns product defects requiring a live rerun to A.
- B/F1: Plain Tab to the header followed by Esc/Ctrl+Tab loses input focus. This product repair changes Card.qml; plan criterion 6 reruns live Ctrl+Tab and W4 steps 4–7 after any code commit. check-issue assigns product defects requiring a live rerun to A.
- B/F2: Shift+Delete cuts rejected prose to the clipboard. This product repair changes EditorBody.qml; plan W4 requires the final-head live sweep after any code commit, including editor OA2/OA3, then restoration. check-issue assigns product defects requiring a live rerun to A.

A must add each finding's reproduction test, show it red before its fix and green afterward, keep each fix in its own commits, run the planned component/check commands and refresh the final-build live evidence. Existing machinery and readiness grants cover these operations; no missing-machinery stop applies. The initial review logs remain the current fail-before evidence for B/F1 and B/F2.

## Repair re-check — 2026-10-13

Verdict: ready.
Prior reviewed base: b210f39da935cb944cd51cf2fe2501c657a276a2.
Prior reviewed head: fa71cf010c77ea0edf9b4c794199f98fa518efed.
Handed-off base: b210f39da935cb944cd51cf2fe2501c657a276a2.
Reviewed repair head: 0be8ca43d9c88c2a98d809ef6bc7070479377b62.

Computed git range-diff b210f39..fa71cf0 b210f39..0be8ca4: all six original commits are unchanged; six repair commits were added. Reviewed only fa71cf0..0be8ca4, including all three reproduction tests and product fixes. No new blocking defect was found.

### Earlier Fixes

- B/F1 resolved by 6f2d5fc. Card records the focused descendant of bodyArea whenever focus changes, so plain Tab and Ctrl+Tab share the same return target. Reproduction 63a920e fails before repair in fix-bf1-red.log and passes afterward in fix-bf1-green.log. The test checks both Esc and Ctrl+Tab return. Final-head live sequence s u tab esc m reads sum in scratch/live.md.
- B/F2 resolved by 9ebfa5d. StandardKey.Cut routes Shift+Delete through guarded cut(), before native TextArea processing. Reproduction 09f2109 fails before repair in fix-bf2-red.log and passes afterward in fix-bf2-green.log. Final-head live Ctrl+Home/Shift+End/Shift+Delete preserves SENTINEL; export confirms prose and the value remain intact.
- A/F1 resolved by 0be8ca4. Settings tracks focus inside its content column and adjusts contentY to expose the focused control. Reproduction 820ef2a fails before repair in fix-af1-red.log and passes afterward in fix-af1-green.log. Final-head live Reset is fully visible before Enter, resets only the current repo, and leaves the other usage file unchanged.

### Evidence and scope

Read all six fail-before/pass-after logs and final-head check-test-1791918676207-1477448.log. The full configured check finished with 84 pass, 0 fail after the latest test/helper changes. The component suites now contain 40 and 15 passing cases, including the three new reproductions. No old expectation, test, helper or runner configuration was changed or disabled. The initial timeout and same-command green retry are recorded in compare-test-0be8ca4.yaml as inconsistent; no base run was needed. Current complete evidence resolves the verification concern, so no redundant check rerun was performed.

The repair report and scratch/live.md record final-head Ctrl+Tab, OA1/OA2/OA3, the repaired keyboard flows, reset isolation and restoration. Read-only verification found installed HEAD 0be8ca43d9c88c2a98d809ef6bc7070479377b62 and origin file:///home/ivan/Work/omarchy-customizations/varhop; scratch/varhop-backup is absent. Criterion 8's checklist remains last in the report. The report explicitly records two failed primary-selection restorations whose prior values are unknown. That testing side effect cannot be recovered and is not evidence of a new product defect introduced by these repairs. Regular clipboard restoration and the criterion 7 cache/state/entry restoration are recorded as passing.

The repair changes no documented behavior beyond restoring the accepted keyboard contracts, and no doc or AREA.md is changed. git diff --check fa71cf0..HEAD passes. Worktree is clean. No review code edits, new runs affecting the session, or commits were made.

### Repair Test-Change trailers

- 63a920e: qml/tst_card.qml cites review-B F1 and review-B-focus.log for the documented plain-Tab/Esc flow.
- 09f2109: qml/tst_views.qml cites review-B F2 and review-B-cut.log for the standard Shift+Delete Cut route.
- 820ef2a: qml/tst_views.qml cites review-A F1 and real live W4 step 8 for off-screen Reset focus with eight picker rows.

Each trailer names the actual source and adds only its finding's reproduction. No existing expectation changed. These QML paths do not match src/test-files.ts, but the voluntary trailers provide the source anyway. Earlier target-to-head trailers remain listed in the initial review entry.

No open Fix, new Nit held by B, or operator action remains for this repair review. A's initial deferred base behavior concerns are outside the repair diff and were not reopened.

## Merge attempt 3c2e9e0f-4f5f-42ee-80cd-b9e2d03c63d2

Applied top: 0be8ca43d9c88c2a98d809ef6bc7070479377b62.
Refreshed AKROGON_BASE from config: b210f39da935cb944cd51cf2fe2501c657a276a2. Worktree clean, HEAD equals supplied top. No fetch, rebase or commit was performed. merge_covers is empty; the required test check was started with the configured command:

```sh
akrogon run-check --name 'test' -- sh -c 'flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c '\''bun install'\'' && akrogon guard own-modules && sh -c '\''bun test --pass-with-no-tests'\'''
```

Initial status: queued for the shared run permit held by framework/crawl-run-binding, framework/spec-path-open-categories, framework/pass-two-review-notes and framework/technical-pack-selection. No check result exists yet. There are no merge_checks or advisory commands. Completion-owner context gathered from overlay-rework/ISSUE.md and both overlay-plugin and overlay-rework briefs.

Merge check terminal result: exit 0, 84 pass, 0 fail, 323 assertions across 12 files, 7.16 seconds after the queue released. Both Wayland component suites passed. HEAD remained 0be8ca43d9c88c2a98d809ef6bc7070479377b62. The configured check includes setup, own-modules guard and the full test suite. No retry or comparison was required. Test operations use readiness.yaml grants[1] for local user ivan, Wayland component windows and clipboard/primary save-and-restore through the existing helpers. No retained install mutation or new live fixture was performed by the merge seat.
