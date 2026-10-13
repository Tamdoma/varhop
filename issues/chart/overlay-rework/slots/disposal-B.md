# Disposal: blind notes from Slot B

Read 2026-10-13. Only Question and Carries were read from the disposal fork. No other slot's disposal notes were read. Recommendations below are not operator decisions. Only this return file was written.

Paths: `L` = `issues/open/varhop/overlay-plugin` in `/home/ivan/Work/omarchy-customizations/varhop`; `W` = `/home/ivan/.akrogon/worktrees/varhop/overlay-plugin`; `A` = `/home/ivan/Work/infra/akrogon/src`. Relative chart paths are under the registered varhop repository.

## Q1. What happens to the failed leaf and its code?

### Pick, reason and cost

**Recommend retiring the old leaf as superseded while retaining its complete code as the base of one successor leaf.** The operator has asked to reconsider the failed leaf, and the new inline requirement needs a clear revised contract. Keeping the code preserves repaired sync, clipboard, draft and performance behavior. A successor should explicitly inherit useful tests and unresolved proof obligations, not start with an assumed clean acceptance record.

Cost: retirement is a manual records/ownership operation, not a supported akrogon phase. The door must finish the archive and branch handoff before dispatching the successor. Use a distinct successor slug and a branch of that name rooted at `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`. Keep the original branch unchanged until the successor's ancestry and files have been checked. This is a proposed procedure, not an executed operation.

### Rejected options and reasons

- **Recover the same leaf with revised contract:** a valid second choice, and mechanically simpler. Reject as the default because it mixes the superseded UI contract and its review history with the newly charted work. Do not claim recovery is impossible: failed can return to planning, and frozen tests can change with valid citations. Pick recovery if preserving the existing leaf identity matters more than separating the two contracts.
- **Retire and rebuild from main:** no evidence justifies discarding the full implementation. The branch contains both the plugin and core performance changes. A rewrite creates additional work and loses established regression evidence without removing the physical-input blockers.
- **Drop the overlay product:** contradicts the continuing request to resolve F1–F7 and the locked overlay destination. Offer only as an explicit change of product direction. It must be recorded as cancelled scope, not completed repair.

### Evidence: tier, source and date

- **Operator, 2026-10-13:** `issues/chart/overlay-rework/INTAKE.md`, the two verbatim requests: resolve the pooled issues and decide whether the failed overlay leaf needs removal. These support separating leaf retirement from deleting useful code or abandoning the product. They do not select an option.
- **Better-than-training, inspected 2026-10-13:** `L/state.yaml:16`, `:35` records four rounds and a blocked failure naming OA1–OA4. `L/review-B.md:419`, `:435` records 77 passing tests and unresolved live outcomes without asserting a new product defect in that review. This supports reuse but does not establish acceptance of F1–F7.
- **Better-than-training, inspected 2026-10-13:** `L/plan.md:22` identifies the retained search/import performance repairs. Read-only Git inspection found W clean at the exact head above.
- **Better-than-training, inspected 2026-10-13:** `A/next.ts:325`–`:333` checks for a branch matching the leaf slug and adopts it when creating the worktree. With a distinct successor slug, that branch must first be created at the retained head. Otherwise the command starts from its tracking branch. An already-existing worktree takes the separate path at `:315`–`:323`, so branch adoption is not a general migration command.
- **Better-than-training, inspected 2026-10-13:** `A/routing.ts:37` allows failed recovery to active phases. `A/phase.ts:351` requires recovery without `--slot`; `:159` retains the repair count. `A/phase.ts:562`–`:598` permits frozen-test changes when cited. Frozen widget names are therefore a test-update cost, not a reason recovery cannot work.

### Pitfalls and what removes them

- **R1. Successor accidentally starts from main.** Before dispatch, verify the successor branch resolves to the retained head and its eventual worktree has the expected ancestry and files. The inspected adoption path supports this plan, but no adoption probe was run in this notes-only exchange.
- **R2. Two leaves own the same unfinished implementation.** Archive the superseded record outside lifecycle discovery before creating the successor. Assign one completion owner. Do not leave the failed record in open/closed under a reused slug.
- **R3. New leaf identity erases old failures.** Carry a criterion-to-evidence table containing F1–F7 and OA1–OA4, retaining or explicitly revising each obligation. Rerun evidence affected by the new editor. A new state file supplies no proof.
- **R4. Re-charting becomes a way around test review.** Keep unchanged behavior tests. Cite the new inline contract for necessary presentation-test changes and retain coverage of shared values, immutable prose, copy bytes and draft state. The source requires test-change citations even apart from the frozen record (`A/phase.ts:392`–`:394`).

### Question missing from the fork

Confirm that the successor owns the **whole unmerged plugin baseline**, including the search/import changes, and that retirement means supersession rather than successful completion. This is the essential handoff boundary. The later proof-bar fork still needs to decide how the unresolved OA outcomes will be established.

## Q2. Where do retired records go, and what happens to the installed copy?

### Pick, reason and cost

**Records:** recommend moving the complete old leaf folder to `issues/chart/overlay-rework/archive/overlay-plugin/`, preserving brief, design, plan, reviews, report, readiness, original failed state and retained evidence files. Record that it was superseded, its exact code head, and the successor link in the chart. Preserve the original state as history. Do not relabel it merged.

**Installed copy:** recommend leaving the current installation and binding in place until the replacement is ready, unless the operator explicitly wants the desktop copy removed now. This avoids coupling a records decision to immediate loss of the current tool and saved repository selection. Cost: the current reported defects remain available during the interim, and the successor must treat the installed copy and its data as pre-existing user state.

These are two independent choices. Present them separately in the operator round rather than making archive location imply uninstall permission.

### Rejected options and reasons

- **Delete the old records:** loses why checks failed and which behavior was already proved. Archiving removes them from active discovery without losing that evidence.
- **Move the failed record to issues/closed and call it complete:** closed is still scanned, and a failed state is still failed. This does not express supersession. Do not invent a terminal phase unsupported by the schema.
- **Leave retired records in issues/open:** retains a stale active-queue entry and obscures the successor's ownership.
- **Uninstall immediately:** reasonable if the operator wants the current UI gone, but not implied by retiring its leaf. Removal deletes the plugin selection entry and leaves the bind/cache/usage behind. If chosen, state those effects and retain personal data unless its deletion is separately requested. Keeping the existing binding for the same replacement plugin ID avoids an unnecessary config edit, but it does nothing while the plugin is absent.
- **Disable instead of uninstall as a supposedly state-preserving pause:** the old contract says disable also removes the selection entry. It is not a way to retain that selection while hiding the plugin.

### Evidence: tier, source and date

- **Operator, 2026-10-13:** the removal note in `issues/chart/overlay-rework/INTAKE.md` refers to the failed leaf ambiguously. It does not separately request erasure of its records, desktop binding, cache or usage history.
- **Better-than-training, inspected 2026-10-13:** `A/state.ts:144`–`:158` discovers state files under issues/open and issues/closed. An archive under this chart is outside that lifecycle scan. `:160`–`:164` rejects duplicate slugs across the discovered records. `A/routing.ts:2`–`:13` has no retired/cancelled state. The archive location is a proposed administrative convention, not a built-in command.
- **Supplied observation, read 2026-10-13:** `issues/chart/overlay-rework/slots/map-merged.md:7` reports the plugin currently installed and Super+Alt+P bound. I did not independently inspect the live desktop because it is outside this brief's permitted context. The old cleanup evidence at `L/review-B.md:423` describes an earlier run and must not be treated as current absence.
- **Better-than-training, inspected 2026-10-13:** `W/README.md:66`–`:74` documents removal, deleted entry and remaining paths. `L/design.md:72`–`:75` records disable/remove selection loss. `W/README.md:23`–`:32` requires a shell restart to load updated code.
- **Better-than-training, inspected 2026-10-13:** `L/readiness.yaml:36` requires fixture paths to be absent and says to stop rather than delete pre-existing paths. `:38` permits cleanup only of recorded run-created paths. That old disposable-install procedure cannot simply be reused against the reported retained desktop installation.

### Pitfalls and what removes them

- **R5. Archive drops uncommitted proof files.** Move the whole leaf directory after recording its contents, then verify the archive is complete before removing the original path. Include untracked reports/logs, not just Git-tracked documents. Keep referenced evidence discoverable from the successor.
- **R6. Stale state closes the chart's own session.** The old record names a tab and both panes (`L/state.yaml:18`–`:24`). Before any session cleanup, the door must verify what those resources currently host. Do not close a recorded tab automatically as part of archiving a leaf.
- **R7. Successor cleanup deletes the operator's installation or data.** At handoff, inspect current installation provenance and saved state, then write the correct update/test/restore procedure. If the copy stays installed, its existing files are not disposable fixtures. If uninstall is selected, verify absence and report retained paths.
- **R8. Worktree removal breaks the installed checkout's update source.** Before deleting or moving the original worktree, inspect the installed checkout's Git remote and record the replacement update source. Current installation provenance is unverified here. Branch retention alone does not guarantee a file-URL origin remains usable.
- **R9. Replacing files leaves old QML running.** The replacement rollout must verify deployed files and load them through the recorded restart procedure. Retirement alone changes neither the loaded code nor the desktop shortcut.

### Question missing from the fork

Q2 combines independent decisions. Ask separately whether to retain or remove the installed copy during development. If removal is selected, distinguish removing the executable/plugin entry from deleting the binding, cache, usage history or the retained GitHub prompt repository. None of those extra deletions follows from retiring the failed leaf.
