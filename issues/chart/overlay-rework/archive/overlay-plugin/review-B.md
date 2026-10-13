# Slot B review

Date: 2026-10-13. Phase: check.review. Verdict: **fix**.
Base: `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`.
Reviewed head: `61c742e6f26845f048ec4a668341a89ff0655467`.
Initial review, blind. Debate is off, so positions-B/rebuttal-B are absent as expected. No peer review was read. No product files or commits were changed.

## Evidence

Read brief, complete plan/design, readiness grants, implementation report, ponytail guidance, README/reference index, the changed code/tests, consumed lib and CLI contracts, and affected installed shell surface. The diff contains no AREA.md or lesson removal. README is the documented behavior page and remains correctly indexed. Its promised draft, copy and navigation behavior is affected by the findings below.

The latest recorded configured test run, `implementation/check-test-1791854861016-2543000.log`, reports 75 pass, 0 fail. The preceding green run also covers the current test bodies. Subsequent head changes only add a commit trailer. Test edits do not disable or filter planned runners. Existing green evidence was reused instead of repeating the clipboard-mutating suite. It does not establish root wiring or the missing live outcomes.

Focused observations are saved in:

- `implementation/review-B-sync-draft-probe.log`: real `bin/varhop-sync accept` in a temporary cache, then unchanged extracted root functions with supplied boundary objects. Accept exit 0 removes staged-1.json. finishSync subsequently reads that nonexistent path and leaves view=settings. close after copy success recaptures the draft.
- `implementation/review-B-copier-probe.log`: the actual Copier instance under quickshell, two successive copies to a stdin-consuming `cat`. First succeeds. Second writes its text but never closes stdin and times out.
- `implementation/review-B-views-probe.log`: actual interactive components under Wayland qmltestrunner. Zero-variable open makes zero copier calls. Reset, type h, undo restores old. Empty value mirror shows {{X}}. Query field code leaves public query empty.
- `implementation/review-B-fixture-probe.log`: the planned generator's long file is 15,057 bytes with zero actual newlines.

These observations are diagnostic evidence, not replacements for the plan's live proofs. Setup was run under the install lock before them. Desktop probes use readiness.yaml's local-desktop grant as ivan for temporary quickshell/qmltestrunner configs. They invoke no clipboard commands, plugin/config edits, shell restart or GitHub writes. Temporary probe directories/configs/output files were removed, and directory absence verified. No new live plugin IDs were created.

Read-only live inspection: installed Varhop.qml is byte-identical to the reviewed file, although the install clone has marker head `ab9c7d9b95ee6b3444cd33704ad8e41c0438e826`. hyprctl shows three connected monitors, with no currently open varhop layer. Current binds JSON parses and has 258 records. Journal inspection for shell PID 2231877 shows module-scanner warnings, not a current Varhop QML error. None of this establishes the missing interactive scenarios.

## Fixes

### F1 — Sync publishes before importing, then reads a deleted staged file

Source: any successful first selection or Ctrl+R through the real repo-sync integration. `bin/varhop-sync:120-124` moves staged-N.json to library.json. `Varhop.qml:278-289` then sets libraryFile.path to that staged path. onLoadFailed at 337-341 clears the in-memory library before reverting to the stable path. More fundamentally, no code reads/imports staged files before saveSelection/accept: syncProc uses only the CLI summary.

Consequence: every successful sync attempts a nonexistent file, can transiently clear the old library, and publishes without the required successful import. A repo change also clears its draft before the bundle is loaded. Trace is reproduced in review-B-sync-draft-probe.log. Violates D8 and brief 2/7. Read and import the staged bundle before committing selection/publication, and swap the already validated library after successful accept. Add proof at this integration boundary.

### F2 — Selection-save/accept failure cannot preserve the old selection

Source: a repo switch when shell.json saving fails, or the cache cannot publish its staged bundle. `saveSelection` at 247-259 updates shell.json before accept. A failed read-back at 262-269 has no failure completion or timeout, leaving syncing=true indefinitely. config load failure additionally clears selection. An accept error calls failSync at 292-297, which neither restores the previous saved selection nor the associated usage identity.

Consequence: failed switching can leave the new selection pointing at the old library, or permanently block every subsequent pull. Violates D8's explicit failed save/accept retention contract and brief 7c. Keep the previous state until the transaction succeeds, handle unsuccessful read-back as an error, and preserve/restore the durable selection on accept failure. The accepted design does not require a dangerous live shell-save injection. Its ordering and error completion still have to be correct.

### F3 — Required load/first-sync routing is missing

Source: choosing a repository on first run, or restarting with a saved selection and a repo-id-mismatched cache. finishSync never changes view from settings to search. route at 176-186 always chooses search when selection exists, ignoring libraryMismatch. importBundle records the mismatch but never routes to settings.

Consequence: first import stays at the picker, and mismatched-cache summon shows search rather than the required named mismatch with Sync now. First case is observed in review-B-sync-draft-probe.log. Violates brief 2b/2e and D15/D9. Complete routing after the successful import, and route cache failures to the settings recovery view.

### F4 — Successful copy immediately recreates its draft

Source: Ctrl+C exporting any variable prompt, including the report's code-review flow. Copier.onSucceeded at 499-505 sets draft=null then calls hide. hide calls close at 200-209, which sees null and captures the editor again.

Consequence: reopening resumes the just-exported draft instead of ending it. review-B-sync-draft-probe.log executes that unchanged close function and records the recreated draft. Violates brief 6a and D4/D10. Make successful completion and draft-preserving hide distinct state transitions. Existing component tests never check the root completion path.

### F5 — A second copy through the retained Copier times out

Source: copying a second prompt, or a second hotkey line, in the same keepLoaded shell session. `qml/Copier.qml:49-51` sets stdinEnabled=false after the first copy and copy() never reenables it. A later write opens/writes stdin, but assigning false again does not close it.

Consequence: the second stdin-consuming child waits until timeout, so normal repeated exports fail. Actual Copier observation: first cat received first and succeeded; second received second and timed out. See review-B-copier-probe.log. Violates brief 6a and keepLoaded behavior. Reset the input-stream lifecycle per copy and prove consecutive calls on one instance. The existing test creates a fresh Copier for every case.

### F6 — Zero-variable open emits a signal that copies nothing

Source: opening any prompt without tokens. `EditorBody.qml:111-113` emits copyRequested without calling requestCopy. The root connects that signal to an empty function at Varhop.qml:630.

Consequence: the promised automatic copy never starts. Actual component probe records ZERO_VARIABLE_COPIER_CALLS 0. Violates brief 5a and D5. Route this opening through the real copy operation. The current zero-variable test counts only the signal, so it passes while the outcome fails.

### F7 — View changes and resumed editing lose or mix drafts

Source: fill a value, Ctrl+, Esc back to editor. Loader.active at Varhop.qml:623 destroys the editor on entry to settings, but the Ctrl+, branch at 577-580 captures nothing. Returning creates an editor without openPrompt. Similarly, after resuming an existing draft, close only captures when draft===null, so subsequent edits/cursor/selection are discarded on the next summon. Opening another result while a draft exists binds that old draft to the new prompt; EditorBody.openPrompt copies draft.values and activeName without matching promptId.

Consequence: settings navigation destroys edits, repeated hide/resume returns stale edits, and Find another can put another prompt's values into the newly selected prompt. Undo histories are also reset on every open and absent from captureDraft. Violates brief 3a/5f/7 and D4. Own a current prompt-specific draft independent of Loader destruction, capture current state before transitions, initialize recreated editors, and restore only the matching prompt's state/history. These real UI sequences need boundary coverage.

### F8 — Query and selected row are not retained

Source: type code, open a result, Ctrl+P, or Ctrl+R after moving to a non-top result. SearchBody.queryField emits queryEdited but never updates root.query (`SearchBody.qml:73,97`). Varhop records item.query at 605, so it saves an empty string. prevSearch.selectedId is never used. Every rows change resets selectedIndex=0 at SearchBody:34, including refresh and usage reloads; importBundle additionally rebuilds the empty query.

Consequence: Find another loses the actual query/selection and pulls cannot retain the selected id. Actual view probe records queryField=code while query="". Violates brief 4d/7a. Save the actual query and selected id at the root and apply query-edit reset versus refresh retention correctly.

### F9 — Semantic undo skips later typing and merges two required steps

Source: enter a value, Delete twice, type a replacement, Ctrl+Z. The reset stack always takes priority over TextArea's native undo at EditorBody:57-72/306-318. pushAction combines empty and unset into one action at 43-52.

Consequence: Ctrl+Z after typing restores the old value instead of undoing the latest edit, and undo cannot step through both empty and unset. Probe records reset→h→undo=old. Violates brief 5c's per-variable edit/reset history. Keep one chronological per-variable history rather than prioritizing unrelated stacks. The test currently expects merged reset undo, contradicting the brief's separate empty/reset edits, so correcting that existing expectation belongs to A.

### F10 — Empty mirrors look unset, and unset count is absent

Source: empty a variable that occurs more than once, then inspect/copy it. EditorBody:340-348 renders seg.raw when a value is present but empty, even though rebuild correctly produces an empty string. No displayed item uses rebuiltText().unset or shows its count.

Consequence: mirrors display {{NAME}} that is absent from the exported text, and users get no required remaining-unset count before exporting. The empty mirror is observed in review-B-views-probe.log. Violates brief 5a/5c/6a. Distinguish present-empty from absent for mirrors and show the count from the consumed rebuild result.

### F11 — Malformed usage is overwritten on the next ordinary copy

Source: the explicitly required malformed usage-file case, followed by a successful prompt export. Varhop:351-354 leaves the old/default usage object available after parseUsage fails. recordUsage at 300-303 unconditionally writes that object over the malformed file, and onSaved clears the error. onLoadFailed at 357 also treats permission/read errors as an empty state without reporting them.

Consequence: ordinary copy silently replaces unreadable history after briefly reporting it, and inaccessible history is silently reset. Violates brief 8 and D9. Retain a failed-load state, distinguish absence from read failure, and prevent ordinary recording from overwriting history that could not be loaded. Explicit Reset usage can remain the recovery action.

### F12 — Chord field does not accept the displayed syntax or refuse bad characters

Source: type the suggested `SUPER + ALT + P` shown by the field placeholder/README, or type @ into the chord field. parseChord splits on + but trims no tokens (`SettingsBody.qml:48-68`), so the displayed spaced syntax is never ready. The field at 303-322 has no validator or invalid-character rejection.

Consequence: the documented chord syntax is rejected while invalid characters remain editable. Violates brief 3e and D14. Parse the shown vocabulary including spaces and refuse invalid input. The current test checks only ready=false for @, which cannot detect whether the character was refused.

### F13 — The latency fixture does not create the required workload

Source: the exact test/make-library.sh fixture named by plan proof 4g. Its BODY is 3000 copies of word-space, about 15 KB rather than 20 KB. Double-quoted shell strings contain literal backslash-n, so jq --arg writes no actual line breaks.

Consequence: the planned proof would measure the wrong body size and import front matter as body text with filename-derived titles. The two-file probe records 15,057 bytes and zero newline characters. Violates brief 4g's half-20-KB workload and plan's synthetic search proofs. Generate actual valid text and at least the required body size before running the 500/2000/5000 measurements.

### F14 — Configured tests do not restore the operator clipboard/primary

Source: normal configured `akrogon run-check` and direct bun test. views.test.ts runs paste/copy component cases without saving either selection. copier.test.ts saves/restores only a nonempty regular clipboard; its wl-paste/wl-copy calls lack the reconstructed Wayland environment given to its child. The earlier logs prove that run-check removes the Wayland connection environment.

Consequence: a green check can leave test data in the clipboard, lose an empty previous clipboard, and alter the primary selection. Violates readiness desktop-grant restoration bounds and D13. Preserve both selections byte-exact around the whole QML test sequence with the same working session environment, surface restoration failures, and verify the restored bytes. Do not repeat these checks without an outer preservation boundary until repaired.

### F15 — Required live proof and fixture cleanup remain incomplete

Source: the implementation report's own done-criterion evidence and limitations. Its latency result is eight keystrokes on four real prompts, not 200 at each required size. It explicitly omits identity mismatch. There is no retained result for picker-row first selection, mismatched cache, killed sync retention, restart hash/fetchedAt equality, selected-id retention, accented input, exact repeated draft resume, unset/all-empty exports, browser+terminal key-state sequences, failed/successful draft-bearing repo switch, usage error/corruption/reset isolation, or disable/enable/remove leftovers. Source paths for screenshots are disposable scratch and no proof outputs are retained for these outcomes.

Consequence: brief 1–8/10 cannot be signed off. These are required outcomes, not optional edge cases. Existing machinery is available, so this is missing execution/evidence, not a request to build a new runner. Complete the planned live scenarios after repairs and record actual commands/results against the final product head. New/changed behavior also needs the planned deliberate-break proof, and bug repairs need fail-before/pass-after evidence.

Live read-back additionally finds `~/.config/omarchy/plugins/ivan.varhop`, `~/.cache/varhop` and `~/.local/state/varhop` still present. The report records no cleanup/absence proof, original clipboard/primary restoration result, pre-run shell hash comparison, or retained authorization for these local fixtures. They predate this review and B did not delete them. A must establish its recorded creation ownership and finish the granted cleanup, preserving other configuration bytes, or record the precise operator action if ownership/restoration cannot be established. The GitHub starter repository is separately retained by readiness.yaml and must remain untouched.

## Test-Change trailers

Trailers in base..HEAD, checked against the actual edits and evidence:

- fef6396: `qml/tst_views.qml adjusted during implementation: QtTest import (QtQuick.Test module name is wrong on Qt 6.12), visible:true on created items (createTemporaryObject defaults to invisible) and context menu driven via v.ContextMenu.menu since synthetic clicks never produce QContextMenuEvent; no expectation weakened`. Import/visibility changes correct the real runner boundary. The context-menu edit removes the prior fallback to Ctrl+V and tests the actual menu action, which is useful, but no retained proof establishes the cited QContextMenuEvent explanation or real right-click opening. Include that required component/live input evidence in F15. No test of the product is replaced by a mock.
- dea832c: `bump views.test.ts and copier.test.ts test timeouts to 60s`. Later green log shows a real 5.454-second view run, so raising the 5-second Bun limit is justified and changes no behavior expectation. This trailer lacks exact paths, subsequently supplied in 9eb5f84.
- 9eb5f84: `test/views.test.ts scan the wayland socket in a waylandEnv helper so the runner connects under run-check's scrubbed env; no existing expectation changed`.
- 9eb5f84: `test/copier.test.ts same waylandEnv helper for the quickshell spawn; no existing expectation changed`.
- 9eb5f84: `test/views.test.ts raise the bun test timeout to 60s; qmltestrunner needs ~6s under wayland, above the 5s default`.
- 9eb5f84: `test/copier.test.ts same 60s timeout for the quickshell runner`.
  The earlier two recorded runs fail initializing Wayland. The latest run is green after these runner edits. Sources support the environment/timeout corrections, with clipboard preservation still defective as F14.
- 61c742e: `test/make-library.sh new fixture generator for the synthetic library bundle used by plugin.test.ts; added in this leaf's test pass`. This commit changes no files. The generator is a new fixture, so no old expectation needs a cited contradiction. However plugin.test.ts does not consume it. Its actual consumer is the planned live latency run, and the fixture defect is F13.

The path rule in akrogon/src/test-files.ts matches test/ files, but not qml/tst_views.qml. It does not exempt changed QML expectations from substantive review. The existing merged-reset expectation is addressed by F9. Component checks alone do not detect F1–F8/F11 root behavior, and the zero-variable assertion does not test the promised copy outcome.

## Nits and operator actions

No additional Nits. No present operator-only permission finding: all doable repairs and required granted runs remain within the leaf's existing authorization. If A cannot establish ownership or restore the original fixture state for F15, that specific missing operator action must be recorded before cleanup. No peer interaction or out-of-grant live mutation was attempted.

## Requested phase result

Request `check.repair` with verdict `fix`. Actual command result will be appended below. Required live runs and the F9 expectation correction belong to A under check.repair routing rules.

Phase command: `akrogon phase overlay-plugin check.repair --slot B --verdict fix`.
Result: `recorded`. B's verdict is saved. The command has not confirmed movement to repair and is waiting for the other initial review.

# check.repair — 2026-10-13

Input: both initial reviews of head `61c742e6f26845f048ec4a668341a89ff0655467`. Output head: `2e0607b9ad98661afc93669e6d5299e84339cf61`. No branch refresh or rebase. No plan/design edits. Each repair is isolated from other findings.

## Repaired

| Finding | Reproduction / command evidence | Fix commits | Result |
|---|---|---|---|
| B F14 | `implementation/repair-B-F14-before.log`: original wrappers exit 0 but clipboard absence/bytes differ. `repair-B-F14-after.log`: same wrappers exit 0, clipboard and primary match their prior bytes/absence. | `d793e32` | Both QML wrappers share a session-aware preservation boundary, including absent and zero-byte selections, restore both selections in finally, and verify read-back. Existing assertions retained. This is a test-command repair, with before/after command evidence. |
| B F5 / A F1 | Reproduction commit `0960fec`. `repair-B-F5-red.log`: second call on one Copier times out, exit 1. `repair-B-F5-green.log`: both Copier tests pass, exit 0. | `169830c` | stdin is reopened before each retained Process run. New regression uses a real stdin-consuming shell command twice, verifying text and EOF without touching the clipboard. |
| B F6 | Reproduction commit `0bbb64a`. `repair-B-F6-red.log`: zero-variable opener never calls its injected external copier. `repair-B-F6-green.log`: QML suite passes. | `c814c45` | Plain prompts call the same real copy operation as the editor shortcut. The old signal assertion remains intact. |
| B F10 | Reproduction commit `a91f396`. `repair-B-F10-red.log`: empty mirror is {{X}} instead of empty. `repair-B-F10-green.log`: suite passes, including transitions between empty/set and unset with their count. | `4feed45` | Empty mirrors remain empty and clickable, mirror styling observes unset state, and a plain-text remaining-unset count comes from rebuild(). |
| B F12 | Reproduction commit `b340c1f`. `repair-B-F12-red.log`: field accepts @ after the displayed spaced chord. `repair-B-F12-green.log`: suite passes, including refusal and ready state. | `c214c71`, `2e0607b` | TextField uses native validation derived from the same modifier/key vocabulary as parsing. Tokens are trimmed. Only the planned modifiers are accepted. TextField is inherently plain text. Final configured check covers the last shared-vocabulary change. |
| B F13 | Before: `implementation/review-B-fixture-probe.log`, 15,057 bytes and zero actual newlines. After: `repair-B-F13-after.log`, actual importLibrary returns two named prompts, no errors, bodies of 12 and 20,480 bytes. | `b8c1653` | Fixture writes real front-matter line breaks and half its bodies have exactly 20 KB. This is a fixture-command repair, verified through the actual parser. |

B F5/F6/F10/F12 each have a reproduction committed before their product fix. No existing test expectation was corrected or deleted. Changed old test files carry Test-Change trailers citing the finding's real user or configured-check source. F13's existing fixture also has its trailer. F14 changes command execution/preservation, leaving outcome assertions unchanged.

## Verification and grants

The exact configured check was run after the repairs:

```sh
akrogon run-check --name 'test' -- sh -c 'flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c '\''bun install'\'' && akrogon guard own-modules && sh -c '\''bun test --pass-with-no-tests'\'''
```

Result: exit 0, **76 pass, 0 fail, 297 expect calls**. The first configured green run is `implementation/check-test-1791856121473-2918174.log`; the second green run after the final vocabulary edit is `implementation/check-test-1791856159900-2921632.log`. No merge_checks exist, and none were run. `git diff --check 61c742e..HEAD` passes and the worktree is clean.

Component proof covers the planned views, copy failure cases and PlainText checks, plus the new reproductions. It does not sign off the pending live done-criteria or the contradicted undo expectation. The entire final test run occurs after the latest test/helper/product edits. No unrelated-red check or comparison disposition was needed: each deliberate red reproduction failed in its leaf-changed unit and turned green after its fix.

Grant used: readiness.yaml local desktop grant, user ivan, QML test configs and Wayland clipboard/primary with save/restore. The F14 before run was protected by an outer capture/restore of both selections. Its diagnostic restored both and verified bytes/absence, without printing or saving the original content. The later wrappers preserve both selections themselves and verify restoration on every run, including the scrubbed configured-check environment. No installed plugin, shell.json, Hyprland settings, live cache, usage file or GitHub resource was mutated. The fixture proof used only a recorded temporary directory, removed it, and verified its absence. No new plugin IDs or live install paths were created.

The before-run diagnostic initially kept a restored primary owner's log pipe open. Replacing that owner with identical primary bytes and detached log streams let the diagnostic finish. Both final byte/absence comparisons passed. No temporary implementation helpers/scripts remain. Persistent qml/test files are the requested regression checks and preservation helper, not scratch artifacts.

## Handed to A

- B F1: missing planned staged-read/import unit and implementation contradicting D8; complete staged import before publication, then run the required first-selection/manual-sync live integration proof.
- B F2: plan correction for failed save/accept retention. D8 promises the previous durable selection, but its save-before-accept sequence lacks rollback and unsuccessful read-back completion. Resolve that missing transaction step, implement it and verify the error path without an unsafe whole-config write injection.
- B F3: initial-import and mismatched-cache routing both require the named live outcomes in brief 2b/2e after the root repair.
- B F4: root successful-copy completion currently recaptures its draft; repair the completion transition and rerun the live copy→reopen outcome in brief 6a. Copier's repeated-call failure is separately repaired above.
- B F7 / A F2: missing planned owned draft/history state plus multiple root transitions make this too large for B's component pass. Capture resumed edits before hide/view destruction, restore the matching prompt state, and prove settings round-trip, repeated resume and Find another without mixing values.
- B F8: root query/selected-id persistence needs the required live Ctrl+P and refresh-retention scenarios in brief 4d/7a after its repair.
- B F9: existing merged reset-undo expectation needs correction against the brief and a single chronological per-variable history. Test expectation corrections belong to A.
- B F11: protect unreadable usage history and distinguish absent from failed reads, then run brief 8's malformed-file and write-failure live outcomes. B did not mutate the existing usage fixture.
- B F15 / A F3: complete all required live proof against the final repaired product, including 200 keystrokes at 500/2000/5000 prompts using the corrected fixture. Establish A's creation/restoration records and clean its existing local fixtures under the grant, or record a precise operator action if that cannot be established. Starter GitHub repository remains retained and untouched.

There is no new operator-only blocker in B's repaired scope. A's Nits were not promoted into extra work. B holds no reusable Nit to record at this handoff.

Requested next phase: check.fix, slot A. Actual command result will be appended after the move.

Phase result: the first move was rejected because the new `test/clipboard.ts` also needed a citation trailer. Added message-only commit `02bd828558c542308cae9d8946a2d808cc9ff353` with the exact path, B F14 source and reason. No code or test body changed after the final green run. Product/test head remains `2e0607b9ad98661afc93669e6d5299e84339cf61`; handed-off head is `02bd828558c542308cae9d8946a2d808cc9ff353`.

Retried `akrogon phase overlay-plugin check.fix --slot B`: **moved check.fix**. Nine unique unresolved findings are handed to A above. Six findings are repaired, including A F1/B F5. No merge readiness is claimed.

# check.review re-check — 2026-10-13

Verdict: **fix**. Initial reviewed base/head: `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed` / `61c742e6f26845f048ec4a668341a89ff0655467`. B's repaired handoff: `02bd828558c542308cae9d8946a2d808cc9ff353`. Current reviewed head: `360a9af51bce5c8850ab289761db5ccf2b947a1d`.

Reviewed A's repair commits `85ccf70` and `360a9af` against B's handoff, and checked their changes against the original findings. Report records no branch refresh/rebase, so no range-diff was needed. Report's `9949cc9` label is not the handed-off head; the current commits and current run below establish the review revisions. No new code or tests were edited or committed during re-check.

## Verification

The configured check was rerun because the latest prior test evidence preceded the final repair commit and because the newly rewritten undo boundary needed verification:

```sh
akrogon run-check --name 'test' -- sh -c 'flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c '\''bun install'\'' && akrogon guard own-modules && sh -c '\''bun test --pass-with-no-tests'\'''
```

Exit 0: **76 pass, 0 fail, 297 expect calls** on reviewed head `360a9af`. Log: `implementation/check-test-1791860099388-48014.log`. The shared preservation helper restored and read-back-verified clipboard and primary around the QML cases. No unrelated-red comparison was needed. `git diff --check 02bd828..HEAD` passes, and the worktree is clean.

Diagnostic evidence: `implementation/recheck-B-undo.log` runs the actual changed EditorBody through Wayland qmltestrunner using native keyClick for two variables, Tab/Backtab and Ctrl+Z. It records LANGUAGE=p, DIFF=d with LANGUAGE active before undo, then LANGUAGE=p, DIFF=empty afterward. The diagnostic intentionally records observations rather than claiming a successful acceptance test. Temporary config was removed and directory absence checked. Grant: readiness.yaml local desktop grant, ivan, short-lived QML test window. No clipboard command, shell config edit, installed plugin/cache mutation or GitHub write was performed by this diagnostic.

README remains the affected behavior documentation. Its promises for copy completion and return navigation were checked against the repair. There are no changed AREA.md files, affected index additions, or lesson removals in the repair diff.

## Earlier findings

- **F1 resolved for the original order/path defect.** stagedFile now reads/imports the staged bundle before saving/accepting; finishSync applies the retained parsed object instead of rereading the deleted staged path. Required live failure outcomes remain tracked in F15.
- **F2 partially repaired, still open for durability proof.** saveWatchdog supplies failure completion and restorePrevSelection uses the installed shell API's actual whole-entry replacement semantics. However rollback clears its tracking state and requests a reload without confirming that the old entry was restored or surfacing a failed rollback. The failure-retention outcome has no live/retained verification. Keep the earlier F2 requirement to preserve the durable previous selection and confirm recovery.
- **F3 partially repaired, still open.** first-import finishSync can now route to search. For a mismatched cache loaded while the overlay is closed, importBundle merely stores libraryMismatch, because its settings transition is guarded by opened. route still selects search solely from selection on the next summon, without considering that stored mismatch. This is the original brief 2e source/outcome, not a new finding. The report records no mismatched-cache run.
- **F4 resolved for the recapture defect.** copySucceeded guards close during successful export, and the report records copy→hide→no draft pin on reopen.
- **F5/F6/F10/F12/F13/F14 remain repaired.** Their B regression checks/command changes are retained and the final configured run is green.
- **F7 partially repaired, still open.** close now captures resumed edits and openPrompt scopes values to promptId. Settings capture at Varhop.qml's Ctrl+, handler is still guarded by draft===null: resume an existing draft, edit it, Ctrl+, Esc back, and the newer edits are lost when its Loader is destroyed. Also openPrompt clears _hist/_redos and captureDraft omits them, so the planned draft-owned history remains absent. These are the original state-retention finding, with the same real navigation source.
- **F8 partially repaired, still open.** root.lastQuery now records typing and row selection can be retained by id. SearchBody.query is still not updated by queryField.onTextChanged. applyParsed and parseConfig still rebuild using searchLoader.item.query rather than lastQuery. A real Ctrl+R after typing therefore eventually rebuilds rows from the stale public query (usually empty). The new selection-only component case does not exercise the root sync integration or catch that original failure.
- **F9 partially repaired.** Single-variable empty/reset actions now form separate undo steps, and later typing is undoable before older resets. The new global-stack behavior violates the required per-variable boundary as F16 below.
- **F11 still open.** Only the read-failure branch was changed. After parseUsage rejects malformed JSON, recordUsage still unconditionally writes the previous/default object with setText and onSaved clears usageError. A normal successful export therefore still overwrites unreadable history, exactly as originally reported. The report provides no malformed-file followed-by-copy proof.
- **F15 still open.** The report now supplies a 500/2000/5000 × 200-keystroke latency matrix and several repaired navigation/copy observations. It explicitly still leaves identity mismatch undriven, despite brief 2g being a required outcome. It still lacks the original outstanding retention/error/lifecycle results and cleanup/absence/restoration evidence. Read-only listing confirms the same installed plugin, cache and state directories remain present. B did not delete resources created by A. Complete the previously requested granted scenarios and establish creation ownership/restoration/cleanup. No new runner is requested. The physical Super-key path remains the expressly deferred operator check and is not added as a blocker.

## New repair defect

### F16 — Undo in one variable changes another variable

Introduced by `85ccf70`, `qml/EditorBody.qml:49-92` and the Ctrl+Z/Y handlers: one editor-wide _hist/_redos stack is popped without using the focused variable name.

Realistic source: the ordinary multi-variable code-review workflow already exercised by the implementation, with LANGUAGE and DIFF. Enter a value in LANGUAGE, Tab to DIFF and edit it, Shift+Tab back to LANGUAGE, then Ctrl+Z. The actual component probe records activeName=LANGUAGE throughout, while DIFF changes from d to empty and LANGUAGE stays p. This changes a value the user is not editing and can silently change the rebuilt/exported prompt.

Hits brief 5c's **per-variable undo/redo**, and D5's variable-local edit history. It is a concrete repair-introduced behavior defect, not an extra case outside the criteria. Keep chronological edit/reset history separately for each unique name, and apply undo/redo to the active variable. Add the two-variable reproduction before fixing it. Existing new undo tests cover only one name and therefore do not catch this defect.

## Test changes and report evidence

Repair trailers:

- `85ccf70`: `Test-Change: qml/tst_views.qml reproduced the fixed defect (covers chronological undo across delete-reset boundaries, draft prompt-id scoping, refresh selection retention, and the merged empty/reset undo steps)`.
- `85ccf70`: `Test-Change: qml/tst_views.qml covers new regression expectations for the same component behavior`.
- `360a9af`: `Test-Change: qml/tst_views.qml added tryVerify/waitForRendering for async ListView delegates; no existing expectation changed`.

The existing reset expectation correction is supported by original F9 and brief 5c. Waiting for virtualized delegates replaces the old immediate assertion with the same outcome and is justified by the actual ListView change. New tests cover the component directly, with external interfaces injected. However the new chronological test begins with Delete on an unset value (which does nothing), then makes a programmatic abc write. It does not establish the previously described real typed-value→empty→reset→typing sequence or variable-local undo. The final green runner result is current, but the report contains no fail-before/pass-after output for A's added regression tests. That missing repair proof remains part of earlier F15, rather than a new product finding.

The repair also modifies lib/search.mjs and lib/import.mjs for latency, beyond the original plan's lib-untouched repair choice. Existing core tests remain green. The report explains the measured runtime reason, but the plan was not amended to acknowledge the changed core boundary or its proof. Resolve this with the already handed plan/proof work instead of treating the prior leaf's tests as evidence for all new cache/mask paths.

A combined many-finding product/test commit does not supply the skill's separate reproduction-before-fix commits. No previously red output for these new cases is retained. Keep the original proof requirement open; no unsupported fail-before claim is accepted.

## Disposition

No new Nits, operator-only actions, or code changes in this re-check. Request check.repair with verdict fix for the open earlier findings and new F16. Actual phase result follows.

Phase command: `akrogon phase overlay-plugin check.repair --slot B --verdict fix`.
Actual result: **moved check.repair**. Reviewed head remains `360a9af51bce5c8850ab289761db5ccf2b947a1d`.

# check.repair — 2026-10-13, second B pass

Input: latest B re-check of `360a9af51bce5c8850ab289761db5ccf2b947a1d`. Repaired head: `62e9d0e12e90329adffd8d3123cd59c0fdde16e8`. No branch refresh or rebase, no plan/design edits, and no installed-plugin/config/cache/usage mutations.

## F16 repaired

Reproduction commit: `3c875e7`, adding one native-key component reproduction to qml/tst_views.qml. Its Test-Change trailer cites the real LANGUAGE/DIFF editing workflow from F16. No old expectation was changed or removed.

Before fix: `bun test test/views.test.ts` exits 1. `implementation/repair-B-F16-red.log` records the new case failing at active-variable undo: LANGUAGE remains p when it must become empty. Other component cases remain green. The test was committed on the reviewed product head before the fix.

Fix commit: `62e9d0e`. EditorBody now holds chronological undo and redo arrays keyed by unique variable name. Every key handler passes the focused name. A new edit clears only that name's redo stack. History entries no longer carry a redundant variable name, so an action cannot point to a different variable from the stack that contains it.

After fix: the same `bun test test/views.test.ts` exits 0, including the new case and all old cases. Log: `implementation/repair-B-F16-green.log`. The reproduction checks focused-variable undo, unchanged sibling value, redo surviving edits in the sibling, mirror consistency, and chronological edits in the sibling. It uses actual EditorBody fields and native Tab/Shift+Tab/Ctrl+Z/Ctrl+Y/key delivery, without mocking the unit under test.

F9's local chronological empty/reset behavior remains covered by its existing component checks and is now variable-local. Draft history survival is still F7's separate unresolved root/state-lifetime requirement.

## Verification

Ran the exact configured check after the final product change:

```sh
akrogon run-check --name 'test' -- sh -c 'flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c '\''bun install'\'' && akrogon guard own-modules && sh -c '\''bun test --pass-with-no-tests'\'''
```

Exit 0: **76 pass, 0 fail, 297 expect calls**. Log: `implementation/check-test-1791860416366-86463.log`. All affected component checks, including the newly added reproduction and earlier chronological/reset/mirror checks, ran after the latest test and product edits. No checks were skipped or filtered in the final run. No merge_checks exist or were run. `git diff --check 360a9af..HEAD` passes, and the worktree is clean. Every undoTop/redoTop caller was inspected and supplies its current variable name.

Grant used: readiness.yaml's local desktop grant, user ivan, QML component tests and Wayland clipboard/primary preservation. The existing wrapper saved, restored and read-back-verified both selections on each red/green/final run. No new temporary scripts or fixtures were created, and no original clipboard content was printed or saved. Required live/root done-criterion proofs remain pending with the findings below, so this pass does not claim merge readiness or full criterion completion.

## Handed to A

- F2: the durable rollback/read-back problem repeats the prior repair round. This is a plan correction for D8's previous-selection retention guarantee: add/implement confirmed rollback and a visible unsuccessful-rollback outcome before claiming the error path is complete.
- F3: mismatched-cache summon still enters search when the cache was loaded while closed. This repeats the earlier routing defect and contradicts D9/brief 2e. Correct the recovery-routing plan/implementation and perform the named live mismatch proof.
- F7: resumed edits still disappear through Ctrl+, because capture is conditional on draft===null. Draft capture/open also still drops history. Both repeat the prior state-retention finding and the missing D4 draft-owned history step. Repair the root transition/state plan and perform repeated resume/settings/history verification. F16's now per-name history maps can be preserved by the draft owner, but B did not expand into that root repair.
- F8: refresh still rebuilds from SearchBody.query, which typing does not update, instead of the saved actual query. This repeats the prior query-retention defect. Correct the query-owner/refresh plan and run the required query plus selected-id Ctrl+R/Ctrl+P integration outcomes.
- F11: parse failure still allows the next successful copy to overwrite malformed history. This repeats the earlier silent-reset failure and contradicts D9/brief 8. Add the missing failed-load write gate and verify malformed-file→copy plus explicit Reset recovery on the live boundary.
- F15: required live outcomes, repair fail-before proof, local fixture creation/restoration/cleanup evidence, and the lib-search/import scope/proof reconciliation remain incomplete. These are execution and plan-correction tasks using existing machinery, not missing machinery for B to construct. Complete the original granted scenarios against the final product and clean A-owned fixtures only after establishing creation ownership. If an actual operator-only action is required, record its exact action, attempted identity/error and owner under the skill's operator-actions rule. The starter GitHub library remains retained.

No new operator-only blocker in B's repair scope. No additional Nits or lesson artifacts. Six earlier findings remain handed to A. F16 is repaired in isolated reproduction/fix commits.

Requested next phase: check.fix, slot A. Actual phase result follows.

Phase command: `akrogon phase overlay-plugin check.fix --slot B`.
Actual result: **moved check.fix**. Handed-off head: `62e9d0e12e90329adffd8d3123cd59c0fdde16e8`.

# check.review re-check — 2026-10-13, third review

Verdict: **fix**. Prior reviewed head: `360a9af51bce5c8850ab289761db5ccf2b947a1d`. B's subsequent repaired handoff: `62e9d0e12e90329adffd8d3123cd59c0fdde16e8`. Current reviewed head: `f2b2d93a62d3ea6e4e4c09e68aba9e52c80a3925`. Original base remains `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`.

Reviewed only A's latest repair diff, commits `5699fdf` and `f2b2d93`, against the B handoff and the six remaining findings. No branch refresh/rebase is recorded, so no range-diff is required. No code or test edit/commit was made in this review.

## Repair disposition

- **F2's missing rollback confirmation is repaired in code.** rollbackCheck is verified on config load and the watchdog reports failed restoration. Existing no-safe-live-save-injection exclusion remains respected. This closes the previously identified missing completion mechanism, with the remaining error-proof obligation carried in F15.
- **F3's closed-cache routing defect is repaired.** route checks stored libraryMismatch, and the report now records mismatched-cache summon reaching settings.
- **F7's capture/history defects are repaired in code.** Ctrl+, captures resumed edits unconditionally. captureDraft includes histories/redos, and matching-prompt open restores them. A new pre-fix reproduction and subsequent green report cover history capture/resume. Exact cursor/selection and full live lifetime proof remain in F15.
- **F8's stale public-query defect is repaired.** typing assigns SearchBody.query, and root-side rebuilding while the item is absent uses lastQuery. The added typing/backspace case supplies a direct component reproduction, and the report records refresh/Find another retention.
- **F11's overwrite defect is repaired in code.** usageLoadFailed gates ordinary recordUsage after malformed/unreadable reads; explicit Reset clears the gate. The report records malformed bytes remaining identical after an actual export.
- **F16 remains repaired.** Per-name histories and their regression case are retained. No new behavior defect was identified in the latest repair diff.
- **F14 must reopen because its B repair fails the configured command with a retained clipboard owner.** This is an earlier finding confirmed by an actual failed check, not a new product finding outside the repair scope. Details below.
- **F15 remains open.** More scenarios were run, but the completion heading overstates the evidence. Details below.

## F14 reopened — clipboard preservation blocks the configured check

Reran the exact configured command because no configured run after this latest repair is recorded:

```sh
akrogon run-check --name 'test' -- sh -c 'flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c '\''bun install'\'' && akrogon guard own-modules && sh -c '\''bun test --pass-with-no-tests'\'''
```

Exit **1**: **75 pass, 1 fail**, 297 expect calls, 108.30 seconds. Log: `implementation/check-test-1791861826348-180113.log`.

Failing unit: `test/views.test.ts`, `view component checks pass under qmltestrunner on wayland`, timed out after 60,000 ms. The terminal trace reports `wl-copy --primary restoration exited null` at test/clipboard.ts:37. The copier wrapper also took 47.19 seconds instead of its usual subsecond runtime.

The preservation helper I added in B's earlier repair starts a persistent wl-copy owner with stdout ignored but **stderr piped**. The background owner can retain that pipe beyond the spawning command's lifetime. While the configured run was stuck, the test process had no active runner child and a detached wl-copy owner was still alive. Replacing the review-created owner's content with identical bytes through a wl-copy command with both log streams detached released the pending command. The configured run then returned its terminal failed result. The original regular clipboard bytes used for that replacement were neither printed nor saved, and the replacement was byte-checked.

Repair the helper's daemon/stdio lifecycle and prove a configured run with nonempty saved selections finishes and verifies both restored byte sequences. This does not require lengthening test timeouts. The real source is the ordinary configured check preserving the operator's clipboard, and the consequence is failed verification and an unverified restoration, exactly within original F14's command/restoration contract.

No unrelated-red retry/base comparison applies: the failure trace is in a file added by this leaf's own diff and the failing command is a planned check. It cannot be classified known-red against the original base.

Grant: readiness.yaml local desktop grant, user ivan, configured QML tests plus clipboard/primary save/restore. The helper attempted both restorations, but its timeout means this run does **not** prove primary restoration. Read-back after the terminal failure finds both current selections absent. There is no surviving original snapshot from the terminated Bun process with which B can establish primary byte equality, so no successful primary-restoration claim is made. Recover/compare a retained baseline if one exists; if restoration cannot be established and needs operator input, record the precise operator action under the skill's rule. No additional permission is inferred merely from this verification gap.

## F15 still open — required outcomes and cleanup

Accept the newly reported mismatch, killed-sync retention, selection/query retention and malformed-file preservation observations for the outcomes they name. They do not establish the whole done-criterion set:

- Brief 5e/5f: accented input and exact cursor plus selection across hide/resume are still not recorded.
- Brief 6a/6b: unset/all-empty byte exports and browser plus terminal key-state sequences remain unrecorded.
- Brief 7c: the new report describes a failed switch and a temporary debug-key call to confirmReimport. It does not report a successful draft-bearing switch discarding the draft only after import on the final unmodified runtime.
- Brief 8: usage write failure and reset isolation between repositories remain unrecorded.
- Brief 10: disabling/enabling via setPluginEnabled does use the same installed registry contract, which removes the plugin entry. The reported absence of layers and later successful summon does not demonstrate picker routing after re-enable, nor the required remove/README-leftovers outcome.
- Read-only listing still finds the installed plugin, cache and usage state. No fixture creation ownership, original shell hash, clipboard/primary restoration comparison, granted cleanup or absence record is supplied.
- The plan still declares lib untouched for latency repairs, while prior repair changed lib/search.mjs and lib/import.mjs. The previously handed scope/proof reconciliation is unchanged.

These are previously identified missing required outcomes and cleanup evidence, not new acceptance criteria. Existing commands remain available, so no new proof machinery is requested. Physical Super-key testing remains deferred as authorized.

## Test changes

`5699fdf` trailer: `Test-Change: qml/tst_views.qml adds two red reproductions for F7 (draft undo history) and F8 (public query tracking); no existing expectation changed`.

The new cases test the actual components. Their sources are the already recorded real draft-resume and query-refresh failures. `implementation/repair-A-F7F8-red.log` records the two specific pre-fix failures; report records them green after repair. No old assertions were weakened, deleted or corrected in this diff. The reproduction commit precedes the product repair, though it bundles two findings instead of isolating them. That history concern is not promoted into a new functional defect.

The report's claimed 76-pass standalone run cannot override the actual failed current configured check. The red check concerns command preservation rather than a shown component assertion failure. Current end-to-end check verification is therefore incomplete.

`git diff --check 62e9d0e..HEAD` passes, and the worktree is clean. No changed AREA.md files, index pointers, or lesson removals. No new reusable Nit or lesson artifact. No proven new operator-only permission item. Request check.repair for reopened F14 and unresolved F15. Actual phase result follows.

Phase command: `akrogon phase overlay-plugin check.repair --slot B --verdict fix`.
Actual result: **moved check.repair**. Reviewed head remains `f2b2d93a62d3ea6e4e4c09e68aba9e52c80a3925`.

# check.repair — 2026-10-13, third B pass

Input: latest re-check of `f2b2d93a62d3ea6e4e4c09e68aba9e52c80a3925`. Repaired head: `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`. No refresh/rebase, no plan/design edits, and no product/root changes.

## F14 repaired

Reproduction commit: `ab63277`, adding one test of the actual preservation helper. It seeds nonempty regular and primary selections with UTF-8 and line endings, replaces them inside withClipboardRestored, then requires exact restored bytes and completion within a bounded child process. An outer preservation boundary protects the operator's current selections. The Test-Change trailer cites F14's real configured-check source.

Pre-fix run on the reviewed helper: `bun test test/clipboard.test.ts` exits 1. The child exceeds 3 seconds and exits with null status / exitedDueToTimeout=true. Log: `implementation/repair-B-F14-daemon-red.log`. This red run used an additional external preservation boundary with detached streams; both pre-run selections were restored and byte/absence checked afterward. An initial fixture-write attempt used an unsupported string stdin argument; it was corrected to Buffer before the committed reproduction/red run. No unsupported-fixture failure is claimed as bug proof.

Fix commit: `0df6f48`. restoreSelection gives wl-copy a regular temporary stderr file descriptor rather than a pipe. The persistent clipboard owner therefore cannot hold a parent pipe reader open. The helper still checks exit status, retains stderr details for failures, reads back MIME/content, and validates bytes or absence. File descriptors and temporary directories are released in finally on success and failure. No timeout was increased, error ignored, or fallback added.

Post-fix same test: exit 0 in 28 ms. Log: `implementation/repair-B-F14-daemon-green.log`. No existing expectation was changed or removed. The old helper and new reproduction file have exact-path Test-Change trailers. This repair remains isolated from F15.

## Final configured verification

Ran the configured command with **both selections seeded nonempty before the whole check**:

```sh
akrogon run-check --name 'test' -- sh -c 'flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c '\''bun install'\'' && akrogon guard own-modules && sh -c '\''bun test --pass-with-no-tests'\'''
```

Exit **0**, **77 pass, 0 fail, 298 expect calls**, 2.43 seconds. Current run-check log: `implementation/check-test-1791862361929-193431.log`. External seeded-state/read-back evidence and complete command output: `implementation/repair-B-F14-nonempty-check.log`.

The external read-back confirms the seeded regular clipboard and primary bytes both equal their pre-check values, including UTF-8, CRLF and a trailing newline. Finally, the external boundary restored the operator's actual pre-run selections and verified byte/absence equality. Original operator bytes were held in memory, never printed or saved. This is proof for the current run, not retroactive proof of the previous timed-out run's unknown original primary selection.

All final checks ran after the newest test/helper edits without filtering or disabling planned tests. The repaired QML history/query cases and all previous component/copy/core cases are green. No unrelated-red comparison or merge_checks run was needed. `git diff --check f2b2d93..HEAD` passes. Worktree clean.

## Grants and cleanup

Used readiness.yaml's local desktop grant as ivan for clipboard/primary tests with capture, restore and byte verification. No plugin install, shell.json edit, shell restart, live cache/state mutation or GitHub operation occurred. Setup uses the configured install lock. The error files use TMPDIR through tmpdir(), contain only command stderr, and are removed in finally. Live listing after the final check finds zero varhop-clipboard-* directories in this turn's TMPDIR. Temporary external output handles were closed. No temporary scripts/helpers remain. The new permanent test is the one F14 reproduction required by the skill.

## Handed to A

- F15: remaining named live outcomes and A-owned fixture cleanup still require A's granted live pass. Complete accented input, exact cursor/selection resume, unset/all-empty byte exports, browser/terminal key-state sequences, successful draft-bearing switch/discard, usage write-failure/reset isolation, re-enable picker routing, and remove/README-leftover outcomes. Reconcile the prior lib/search/import repair with the plan/proof scope. Establish creation ownership, original shell/selection baselines, restore/cleanup/absence evidence, including the earlier unverified primary restoration if a retained baseline exists. If a baseline cannot be recovered and an actual operator action is necessary, name it precisely with identity/error/owner under Operator actions. No new proof machinery is needed. The starter GitHub repository remains retained and untouched.

No new operator-only blocker in this B pass. No new Nit or lesson artifact. F14 is repaired with fail-before/pass-after and nonempty whole-check proof; only the earlier F15 handoff remains. Full live done-criterion completion and merge readiness are not claimed.

Requested next phase: check.fix, slot A. Actual phase result follows.

Phase command: `akrogon phase overlay-plugin check.fix --slot B`.
Actual result: **moved check.fix**. Handed-off head: `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`.

# check.review re-check — 2026-10-13, final evidence handoff

Verdict: **fix**. Prior B repaired handoff and current reviewed head are both `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`. Original base remains `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`. No commits or code/test diff were added in this pass. Reviewed the new report evidence and the leaf plan's D16a scope correction against earlier F15. No branch refresh/rebase or range-diff requirement. No code, tests, plan or design edited by B.

## Verified evidence and resolved portions

Latest recorded configured check: `implementation/check-test-1791869867775-968580.log`, **77 pass, 0 fail, 298 expect calls**, 2.44 seconds. This is current for the unchanged head. No rerun was needed because no code/helper/test changed and no remaining concern is a unit-check failure. F14 remains repaired with its nonempty preservation regression.

The report now records live unset-literal copy, unset count, usage write failure, accented input, value resume, removal/re-add picker routing, and the registry removal/leftover checks. Accept those specific observed outcomes. D16a now explicitly reconciles the earlier lib/search/import performance repair, superseding the plan's earlier lib-untouched statement. No new defect, test trailer or test expectation change exists in this handoff.

Cleanup is independently confirmed by read-only inspection: plugin directory absent, zero .ivan.varhop.bak.* paths, cache/state directories absent, and `omarchy plugin list` does not list ivan.varhop. The report also records shell.json matching the pre-run baseline and regular/primary bytes matching saved snapshots, including the earlier unverified primary selection. Accept that retained restoration report. B did not delete resources or mutate the session/clipboard during this review. The GitHub starter repository remains retained.

## F15 still open

Named required live outcomes remain unproven:

- **5f**: the report explicitly says exact cursor/selection resume could not be exercised because arrow/selection key injection produced no movement. Preserved value text alone is not the exact cursor-and-selection outcome.
- **6b**: the report explicitly says synthetic Ctrl+V/Ctrl+Shift+V did not insert text over browser or terminal. A passing component clipboard test and working Ctrl+C do not prove the required live paste result. Do not conclude the cause is outside the plugin solely because the component test passes; root focus/runtime integration remains part of this criterion until the operator verifies the ordinary physical interaction.
- **6a all-empty**: the addendum explicitly says the empty-value live copy was not retried after restart. The earlier synthetic body `{{X}}\n` would export a newline when X is empty, not the required empty string. The mirror/count component case does not call the real Copier with empty output or establish the live empty export. Prove an actually empty body/output through the unmodified runtime and compare zero bytes.
- **7c successful repo switch**: the report explicitly says a second repository is outside the current GitHub target grant. This is an operator authorization item, not a product Fix for the repair seat.
- **8 reset isolation**: the new report records write failure and malformed-file retention, but still records no Reset usage outcome with another repository's entries/file proved unchanged.

The required outcome bar is unchanged. These are the original F15 gaps, not added acceptance criteria. Code is unchanged and no new product defect is asserted. Cleanup, lib-scope reconciliation, accented input and the newly proven copy/write-failure outcomes are no longer held open.

## Operator actions

### OA1 — Authorize a second existing prompt repository for the switch proof

Owner: operator. Identity: gh keyring login ivanjuras, id 6634086. Current permitted repository: Tamdoma/varhop-prompts, id 1416196860. The live pass reports that varhop-sync's real second-repository lookup/clone was not attempted because the readiness grant names only that repository. No observed GitHub access-denied response is claimed; the observed blocker is the authorization boundary before mutation/read of an ungranted target.

Exact operator action: name and authorize read-only use of a second existing prompt repository, including `gh api repos/<owner/repo>` and shallow git clone/fetch through the same credential helper. Creating a new repository is unnecessary if an existing one is authorized. Then, with a draft present, choose that owner/repo, confirm the warning, and verify successful import discards the draft. Record the second target's identity and its cleanup/retention terms before using it. This gates brief 7c and therefore holds merge.

### OA2 — Perform the physical exact-selection resume proof

Owner: operator. Identity: local ivan Wayland session. Attempted operation: live arrow/Shift+arrow injection through hl.dsp.send_shortcut/send_key_state on deployed 0df6f48. Observed result in the report: no cursor movement or selection change, so the requested state could not be set by the agent.

Exact operator action: in a variable value, place the cursor within the text and select a nontrivial range using the physical keyboard/mouse. Hide and summon the overlay. Verify the same active value, cursor position and selected range return. Record the outcome on the unmodified deployed build. This gates brief 5f.

### OA3 — Perform the physical browser/terminal paste proof

Owner: operator. Identity: local ivan Wayland session and clipboard. Attempted operation: live Ctrl+V/Ctrl+Shift+V via both supported injection APIs, over Chrome and foot, on fresh/resumed editor fields. Observed report result: no insertion, while Ctrl+C does reach/export.

Exact operator action: with clipboard/primary saved for restoration, focus the overlay over a browser, paste into a value and search field using the physical Super+V binding, then repeat over a terminal-tagged window. Verify literal insertion in the focused field and unchanged prose. Exercise copy through the corresponding binding and verify prompt export from the editor. Restore and byte-check both prior selections. If this also fails physically, record a product/root-integration defect with that real interaction rather than declaring an environment exception. This gates brief 6b.

These operator actions are not Fixes handed to B to repair. The still-doable all-empty export and reset-isolation live proofs remain F15 work for A before any operator-only stop. No questions were posed during review and no ungranted second-repository operation was attempted.

## Disposition

Request check.repair with verdict fix for F15's remaining required proof and its merge-gating operator actions. No new Nits, lesson artifacts, code edits or test changes. Actual phase result follows.

Phase command: `akrogon phase overlay-plugin check.repair --slot B --verdict fix`.
Actual result: **moved check.repair**. Reviewed head unchanged: `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`.

# check.repair — 2026-10-13, proof-only handoff

Input/current head: `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`. Read the latest re-check: only F15 remains, comprising required live runs and explicitly named operator actions. There is no eligible product/test/command Fix for B to implement. No code, test, plan or design edit/commit, no runtime mutation, and no new fixture was created in this pass. Worktree remains clean.

Current unchanged-head check evidence remains `implementation/check-test-1791869867775-968580.log`: 77 pass, 0 fail, 298 expect calls. Cleanup was independently confirmed in the preceding review. No tests were rerun because nothing changed and the remaining uncertainty is confined to the named live outcomes. No merge_checks were run.

## Handed to A

- F15 / brief 6a: required live run of an actually empty rebuilt output through the unmodified runtime. The earlier {{X}} plus newline fixture cannot establish a zero-byte export. Use a zero-byte body/output, trigger the actual copy operation, verify zero clipboard bytes, draft completion and hide, then restore both selections and clean only the new recorded fixture.
- F15 / brief 8: required live Reset usage proof showing the selected repository's entries cleared while a separately recorded repository usage file remains byte-identical. Save/restore and clean only the grant-owned fixtures, and retain the outcome evidence.

These required live runs belong to A under check.repair routing. Existing machinery is available; this is execution, not missing proof machinery. Finish these doable items before any operator-only failed stop.

## Operator actions carried forward

OA1, OA2 and OA3 in the immediately preceding re-check remain open, with their exact owner, identity, attempted operation and required action recorded there. They are not handed to A as code Fixes:

- OA1: operator authorizes read-only use of a second existing GitHub prompt repository; gates successful draft-bearing repository switch, brief 7c.
- OA2: operator physically sets and verifies exact cursor/selection through hide/summon; gates brief 5f because agent key injection could not establish the requested state.
- OA3: operator physically verifies browser/terminal paste/copy binding behavior; gates brief 6b because live synthetic paste yielded no insertion. A physical failure must be treated as product/runtime evidence, not automatically excused as an environment limitation.

Because Handed to A work also remains, move to check.fix; A finishes that work and then makes the skill's one failed stop naming every still-open operator action. Do not clear these merge gates merely because component tests pass. No new Nit, lesson or additional operator action. No merge readiness is claimed.

Requested phase: check.fix, slot A. Actual phase result follows.

Phase command: `akrogon phase overlay-plugin check.fix --slot B`.
Actual result: **moved check.fix**. Handed-off head unchanged: `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`.
