# Review B: repo-sync

Date: 2026-10-13. Phase: check.review. Verdict: fix.
Base: a467aa6b907791191c8cbf240f70173d0e52214d
Reviewed head: 0fa608108c852ab539328b44bdfea9470a1eca3e

Initial blind review of the full diff against brief.md, design.md, plan.md, implementation/report.md, the reference index, chart and sync proof docs. Debate is disabled, so no positions-B.md or rebuttal-B.md is expected. No peer review read, no product files changed, no commits made.

## Fixes

### F1: Existing prompts/ with no Markdown files reports ok

Location: bin/varhop-fetch:132-148.
Actual source: a user selects or manually pulls a nonempty prompt repository containing only a draft such as prompts/notes/draft.txt. The GitHub sync path delegates to this same fetch executable; non-Markdown content is explicitly permitted and skipped. This is also reachable when the user removes their last Markdown prompt but keeps a non-Markdown file in prompts/.

Trace: after checkout the prompts/ directory exists, so the missing-directory check does not run. The find loop collects zero .md files, but STATUS is initialized to ok and never changes. The executable exits 0 and writes both a success response and staged bundle with status ok, files [], errors [].

Consequence today: the CLI mislabels an empty prompt collection, denying its consumer the planned no-prompts state.

Contract: plan D5 explicitly requires no-prompts when prompts/ is present but collecting zero .md files. This is a wrong status at the public fetch/sync boundary.

Evidence: implementation/review-B-no-prompts.log records a real local Git repository, executable command, exit status, stdout and staged bundle fields. Expected no-prompts; observed ok. Temporary fixture and cache were removed.

Repair: preserve staging and commit while returning no-prompts for the zero-Markdown case. Add the smallest executable-boundary reproduction test and show it failing before the repair and passing after. The existing missing-prompts test covers only an absent directory and does not catch this defect.

## Verification

- Configured test check rerun on the reviewed head: exit 0, 19 pass, 0 fail, 110 assertions. Log: implementation/check-test-1791849678270-664215.log. The exact configured test command from akrogon config was run, including locked bun install, akrogon guard own-modules and bun test --pass-with-no-tests. No filters or disabled cases.
- Current implementation/proof-live.md names the reviewed head and records criteria 1-2 through the real stored gh login: status/repos/repo, sync/accept, remote HEAD and byte comparisons, and identity mismatch writing nothing. No auth or network code changed during review, so these recorded live proofs were reused. No external mutation or new external resource was needed.
- Tests cover the listed lifecycle scenarios, empty repo, absent prompts/, invalid UTF-8, layout errors, symlink/gitlink/non-Markdown skips, malformed repo arguments and empty GH_CONFIG_DIR. Red-first evidence is recorded in plan.md. F1 is not covered by current tests.
- Both executable files have mode 755. Runtime uses bash and stock tools with no Bun/Node runtime dependency. Library publication is confined to accept's rename.
- No documented behavior changed in existing docs. Chart and sync docs describe the intended clone, authentication and prompt-format contracts and were followed as review inputs. Chart artifacts are in the registered checkout rather than the ignored worktree issues/ directory. No AREA.md is changed, and no lesson line is removed.
- Worktree remains clean at the reviewed head. No failed configured check requires a comparison record.

## Test-Change trailers

3db8ec61be663a9bbd2fb50ee9fa8fc984dd7079:
Test-Change: test/sync.test.ts brief design leaf architecture repoId field; real output showed numeric 222

Accepted: the path matches akrogon's src/test-files.ts rule. The sole assertion correction changes repoId from string to number 222, consistent with the design's numeric identity contract, gh .id data and numeric ids in current live proof output. The latest test run includes this correction. The initial added test file requires no trailer. No other old test expectation is changed or deleted.

## Nits and operator actions

None.

## Phase result

akrogon phase repo-sync check.repair --slot B --verdict fix returned recorded. Waiting for the other initial verdict. No repair was performed in this review pass.

## 2026-10-13 check.repair

Reviewed both initial reviews for head 0fa608108c852ab539328b44bdfea9470a1eca3e. Both Fixes concern the same plan/code status mismatch and require settling the plan before a repair. No independent doable Fix remains. No code or tests changed, no commits made, and no operator action is open. The initial configured check and live proofs remain applicable to the unchanged head. No additional test run is needed for this handoff.

### Handed to A

- Review A F1: plan D5 correction. The finding explicitly requires changing plan.md, which check.repair assigns to A and prohibits B from editing.
- Review B F1: resolve alongside review A F1 because A proposes removing the exact D5 requirement B used as the repair contract. B cannot implement that requirement while independently settling the disputed plan. The existing probe demonstrates zero Markdown candidates, not invalid UTF-8 Markdown candidates, so the latter case should remain distinct when A settles the rule. If A retains D5, repair the executable with red-before/green-after boundary evidence. If A corrects D5, record how that correction resolves B's finding.

Requested next phase: check.fix for A's plan correction and resolution of both findings. No repair commits or new reusable B Nits to record.

## 2026-10-13 check.review after check.fix

Verdict: ready.
Prior reviewed base: a467aa6b907791191c8cbf240f70173d0e52214d
Prior reviewed head: 0fa608108c852ab539328b44bdfea9470a1eca3e
Handed-off base: a467aa6b907791191c8cbf240f70173d0e52214d
Reviewed repair head: d22e7c4f9fbc13194e5a91fd67ffb59052b7d30c

Scope: repair diff only, plus A's updated D5 and report. Independently computed git range-diff between the prior and handed-off base/head ranges: all four original commits unchanged, only 7f16792 and d22e7c4 added. No main commits or conflict resolutions to review.

Both earlier Fixes resolved: A settled the plan correction by distinguishing zero files with zero errors (no-prompts) from an errors-only collection (ok). The four-line executable repair matches that rule. Review B F1's draft.txt scenario now has a boundary regression test asserting both response and staged status; Review A F1's error-visibility concern is preserved by checking both temporary collections.

Evidence:
- implementation/report.md records the reproduction test red before the fix (19 pass, 1 fail) and green afterward. implementation/check-test-fix.log is a current configured check run including the final new test: 20 pass, 0 fail, 115 assertions, with ownership guard and no test filters. Existing expectations and fixtures are unchanged.
- New test trailer in 7f16792f9a24fcddada95d26a5a7507d0a2d25ad: Test-Change: test/sync.test.ts check.review review-B F1; real source: a repo whose prompts/ holds only non-.md files syncs as ok with empty files instead of the named no-prompts state; adds one case, no existing expectation changed. Accepted against the earlier executable probe and the corrected D5 contract. d22e7c4 changes product code only.
- Specific errors-only probe on the repaired head: a local Git repo containing only an invalid-UTF-8 Markdown file stages status ok, files [], and the invalid-UTF-8 error entry. Probe passed and is recorded in implementation/review-B-recheck-proof.json.
- Criterion 2 live proof rerun after the fetch change under readiness.yaml grants[0], using gh keyring login ivanjuras and retained private Tamdoma/varhop-prompts: real sync and accept passed; accepted commit matched remote HEAD 030140c219b1b4ff84b7486287ae5c8684ba20f1; all four file texts matched their Git blobs byte for byte. Expected repo id 1 refused with identity-mismatch, exit 5, and no cache created. Command arrays, exit results and assertions are recorded in implementation/review-B-recheck-proof.json. No external mutation or created external ID. All local proof fixtures and caches removed; retained remote unchanged.
- Criterion 1 proofs remain applicable because auth/API code is unchanged. Criteria 3-6 are covered by the current 20-test check. No merge_checks configured or run.
- No docs or AREA.md changed in the repair. No documented behavior changed. No lesson removals, new defects, open operator actions or reusable B Nits. Product worktree remains clean.

Requested next phase: merge.

## 2026-10-13 merge

Attempt: 0b622682-d580-44cc-894d-0c467508c2e2. Applied stack top and HEAD: d22e7c4f9fbc13194e5a91fd67ffb59052b7d30c. Refreshed AKROGON_BASE: a467aa6b907791191c8cbf240f70173d0e52214d. No carried members. Worktree clean; no commits, fetch or rebase performed.

Ran the configured test command on the recorded top: exit 0, 20 pass, 0 fail, 115 assertions. Evidence: implementation/check-test-1791849921244-725659.log. Command includes locked bun install, akrogon guard own-modules and bun test --pass-with-no-tests. No merge_covers, merge_checks or advisory commands configured. No failed checks or comparison records.

Merge result: merged --check returned ok for attempt 0b622682-d580-44cc-894d-0c467508c2e2. The final merged call exited 0, printed moved merged and deployed a467aa6b9077..d22e7c4f9fbc. No issue complete or epic complete line was emitted, so no completion broadcast was due.
