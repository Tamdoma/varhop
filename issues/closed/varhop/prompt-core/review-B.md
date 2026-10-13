# Slot B review

Date: 2026-10-13. Phase: check.review. Verdict: fix.

Base: `d22e7c4f9fbc13194e5a91fd67ffb59052b7d30c`.
Reviewed head: `5cc766b65939c2a66eb70122ee976befae12c0d8`.

## Context and verification

Read brief, design, plan, implementation report, reference index, README, authoritative search/front-matter forks, and the whole initial diff. Debate is disabled, so positions-B/rebuttal-B are absent as expected. No peer review was read. No AREA.md or lesson removal occurs in this diff. No documented behavior changed in the existing README or reference index. The fork contracts below govern the new modules.

Ran the configured blocking command unchanged:

```sh
akrogon run-check --name 'test' -- sh -c 'flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c '\''bun install'\'' && akrogon guard own-modules && sh -c '\''bun test --pass-with-no-tests'\'''
```

Exit 0: 69 pass, 0 fail, 270 assertions across 7 files, including the real QML smoke boundary. Log: `implementation/check-test-1791851288816-1653833.log`. This current run covers every planned test file. No planned tests were filtered, skipped, disabled, or changed after their recorded final run. There are no merge_checks. No missing environment values, live grants, or operator actions apply.

Additional probes used `bun run -` with imports of the unchanged reviewed modules. They exercise the exported import/rank boundary with representative supported repository content. Real source trace for all findings: an operator-authored UTF-8 Markdown file under `prompts/<category>/[<subcategory>/]<name>.md` is emitted unchanged as `{path,text}` by `bin/varhop-fetch:135-146`; `importLibrary` consumes precisely that contract, and `rank` consumes its Prompt output. These cases require no malformed bundle or contract-violating caller. Probes modified no code or fixtures.

## Fixes

### F1: Ignore the continuation lines of unknown metadata

Location: `lib/import.mjs:180-184,218-226`.

Real source: the operator places future metadata in a supported prompt header, for example:

```markdown
---
future:
  hint: keep
  - example
title: Known
---
Body
```

Observed: title `Known` is retained, but errors are returned for lines 3 and 4, both `unrecognized header line`. Only the unknown key's first line is skipped.

Consequence today: a supported unknown metadata block is reported as broken front matter. This violates design/front-matter Values: “Unknown keys and their lines are skipped silently,” and the repo-format extension contract. No existing test catches unknown-key continuation handling. Repair must leave errors for genuinely malformed known fields and the thematic-break fixture intact.

### F2: Restore category, subcategory, title ordering

Location: `lib/search.mjs:120-124`; incorrect expectation in `lib/search.test.ts` empty-query fixture.

Real source: a library contains `prompts/a/root.md` titled `Zulu` and `prompts/a/sub/nested.md` titled `Alpha`. Opening search with no query and no copies is an ordinary supported user action.

Observed boundary output: `[prompts/a/sub/nested.md, prompts/a/root.md]`. Required output is `[prompts/a/root.md, prompts/a/sub/nested.md]`, because the null subcategory sorts first.

Consequence today: alphabetical titles interleave subcategories instead of presenting the settled category grouping. This contradicts plan D9 and the authoritative search fork's settled “category, subcategory, title” ordering. The implementation report explicitly substitutes the test's order for the plan. A wrong test cannot supersede an operator decision. The existing empty-query expectation must be corrected by A, citing that settled outcome, and the implementation must follow it. The worker brief's stated subcategory-first rule also contradicts its example order.

### F3: Do not suppress a title because it equals the file stem

Location: `lib/search.mjs:65-67`; search field-weight test fixture.

Real source: the operator writes `title: needle` in both `prompts/c/needle.md` and `prompts/c/other.md`. Searching `needle` should score both explicit titles equally.

Observed: `other.md` scores 6 with matchedField `title`; `needle.md` scores 5 with matchedField `fileName`, so input order and usage can no longer break their equal title relevance.

Consequence today: changing a file name changes title relevance even when its explicit title is unchanged. Folded equality does not identify whether a title was explicit. Moreover, the settled search contract includes “title (or file-name default)” as a searched field, and plan D7 assigns title weight 6 without this exclusion. The report's accepted deviation violates that contract. Existing tests encode the exclusion by expecting a default-title prompt to score only at file-name weight. A must correct the conflicting fixture/expectation with the search contract as its source, then restore title scoring. Add a boundary regression for identical explicit titles with different file stems.

### F4: Strip comments on otherwise empty values

Location: `lib/import.mjs:94-98,183`.

Real source: the operator uses ordinary commented empty metadata and a supported block tag list:

```markdown
---
title: # comment
description: # comment
tags: # labels
- useful
---
Body
```

Observed: title `# comment`, description `# comment`, tags `["# labels", "useful"]`, no errors. Required: default title `example` for `prompts/c/example.md`, absent description, and tags `["useful"]`.

Consequence today: comments become visible title/description and searchable tags. The initial `.trim()` removes the space before `#` before `withoutComment` checks for ` #`, defeating the documented comment rule exactly when the value is absent. This violates front-matter Values' plain-scalar comment stripping and empty-value semantics. The current comment test covers a non-empty scalar only and cannot catch this. Fix comment recognition before destructive trimming, retaining literal quoted hashes and unspaced hashes inside plain values.

## Test-Change trailers

`git log --format='%B' d22e7c4..HEAD` contains no `Test-Change:` trailers. All test files are newly added in this range, so the changed-existing-test path rule in akrogon's `src/test-files.ts` imposes no trailer requirement here. Existing regression tests from main are untouched. F2 and F3 identify incorrect new expectations, with the binding sources that justify their correction.

## Disposition

Request check.repair. F2 and F3 require A's correction of conflicting test expectations under the skill's repair ownership rule. F1 and F4 are doable parser fixes. No operator actions or additional Nits are held. No code was edited or committed during review.

## check.repair — 2026-10-13

Starting head: `5cc766b65939c2a66eb70122ee976befae12c0d8`. Read both initial review files. A F1 duplicates B F2. No other Fix or operator action appears in A's review.

### Repaired

- B F1: reproduction commit `0a528ed`, fix commit `400538d`. Unknown metadata now consumes its indented, indentless-list and blank continuation lines before the next top-level header line. Known fields still parse and unsupported known fields still report errors. `bun test lib/import.test.ts` on the reproduction commit exited 1: 14 pass, 1 fail; expected error lines `[8]`, received `[3,4,6,8]`. After the fix, the same command exited 0: 15 pass, 0 fail, 72 assertions. The regression preserves the error on the subsequent `description: |` while ensuring unknown metadata produces none. Existing thematic-break and malformed-known-field tests remain green.
- B F4: reproduction commit `bb47d39`, fix commit `4ea20f0`. Plain-scalar comment detection now recognizes a leading hash after trimming as well as the existing space-hash case. Quoted scalars take their existing separate parser, and hashes inside unspaced plain values remain literal. `bun test lib/import.test.ts` on the reproduction commit exited 1: 15 pass, 1 fail; expected default title `example`, received `# comment`. After the fix, the same command exited 0: 16 pass, 0 fail, 77 assertions, including absent description and block tags `["useful"]`.

Each Fix has a separate reproduction-test commit followed by its own product fix. Both test commits carry a `Test-Change: lib/import.test.ts` trailer citing the finding's operator-authored source and front-matter contract. No existing assertion or fixture was changed.

### Handed to A

- B F2 / A F1: restore category → subcategory → title ordering and correct the conflicting empty-query expectations. A owns corrections of existing test expectations. This also reverses the report's deviation from plan D9 and the settled search decision.
- B F3: restore title scoring and correct the conflicting field-weight fixture/expectation, using the settled title-or-file-name-default search contract. A owns corrections of existing test expectations. This also reverses the report's deviation from plan D7. Include the identical-explicit-title regression described above.

### Final verification

Final repair head: `4ea20f0`.

- `bun test lib/import.test.ts lib/tokens.test.ts lib/rebuild.test.ts lib/search.test.ts lib/usage.test.ts lib/qml.test.ts`: exit 0, 51 pass, 0 fail, 164 assertions. Runs all planned proof files for criteria 1–7, including real offscreen QML loading.
- The configured blocking `checks.test` command quoted above: exit 0, 71 pass, 0 fail, 279 assertions across 7 files. Log: `implementation/check-test-1791851405062-1695192.log`. No merge_checks exist or were run.
- Reviewed the repair diff and verified the worktree is clean. No temporary helpers were created. No plan, design, or unrelated code was changed. No operator action is open.

Green search tests do not close F2/F3 because their incorrect expectations still need A's correction. Request `check.fix` for those remaining items.

## check.review re-check — 2026-10-13

Verdict: ready. Base remains `d22e7c4f9fbc13194e5a91fd67ffb59052b7d30c`. Prior reviewed repair head: `4ea20f0d129e0aa74f2e798d054801adef24feb7`. Reviewed head: `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`.

Reviewed only `4ea20f0..5cac0ae`: four commits changing `lib/search.mjs` and `lib/search.test.ts`. This pass did not refresh the branch: the report records the base unchanged and the prior head is an ancestor of the reviewed head. No conflict resolution or main commit is included in the repair. No red-merge replay requirement applies.

- F2 / A F1 closed: `ba498fe` corrects the existing empty-query expectation to the settled category → subcategory → title rule; `5cb4758` implements that rule with null subcategory first. The recent-copy section and its cap remain intact. The report records the corrected expectation red against `4ea20f0`, then green after the fix.
- F3 closed: `0cb78a4` makes the file-name-weight fixture use a non-matching title, preserving its ability to distinguish title/file-name weights, and adds the equal-title ranking regression. `5cac0ae` removes the title exclusion, so both explicit and default titles score at title weight. The report records unequal scores before the fix. The fixture helper omits an explicit title equal to the stem, but import produces the identical Prompt.title/search.title contract in either case, so this regression catches the shared scoring defect without relying on title provenance.
- F1 and F4 remain closed: their product fixes and reproduction tests are unchanged and pass in the current complete run. No remaining Fix or operator action exists. No new defect was found in the repair, and B holds no reusable Nit.

### Test-Change trailers in base..head

The range now contains four trailers, all justified by the cited operator-authored source or settled outcome:

```text
Test-Change: lib/import.test.ts B F1 operator-authored unknown metadata blocks must be ignored under the front-matter contract
Test-Change: lib/import.test.ts B F4 operator-authored commented empty fields must remain absent under the front-matter contract
Test-Change: lib/search.test.ts search fork settled 'category, subcategory, title' ordering (operator taken); prior expectation interleaved titles across the null-subcategory boundary
Test-Change: lib/search.test.ts B F3 settled 'title (or file-name default)' search contract; adds identical-explicit-title regression, no existing expectation weakened; weights fixture retargeted to keep fileName weight observable
```

The new corrections preserve the existing tests' functional coverage and remove expectations that conflict with binding search decisions. No planned test, helper, fixture or runner was skipped or disabled.

### Current verification

Ran the configured blocking `checks.test` command quoted in the initial review after the final repair: exit 0, 72 pass, 0 fail, 280 assertions across 7 files. Log: `implementation/check-test-1791851601180-1763912.log`. Includes all planned criteria 1–7 and real offscreen QML smoke loading. This confirms the implementation report's final-head proof after all test/helper changes. The worktree remains clean. No docs or AREA.md changed in the repair. Request merge.

## merge — 2026-10-13

Attempt: `576870f9-bbef-40f5-a9f1-ba81838d4575`. Applied stack contains only the holder. Refreshed configured base: `d22e7c4f9fbc13194e5a91fd67ffb59052b7d30c`. HEAD equals the recorded top `5cac0ae48aa81e8af15b9ef06b2ed8ca6ede89ed`. Clean worktree, no fetch, rebase, code edits or commits during merge.

Ran every configured check on the applied top: the exact `checks.test` command quoted above exited 0 with 72 pass, 0 fail and 280 assertions, including QML smoke. Log: `implementation/check-test-1791851634260-1766226.log`. `merge_covers`, `merge_checks` and `advisory` are empty. No missing required environment values or open operator actions.

`akrogon phase prompt-core merged --slot B --check --attempt 576870f9-bbef-40f5-a9f1-ba81838d4575` returned `ok`, validating the tested top and Test-Change trailers. The parent still contains the open overlay-plugin leaf, so this batch is not expected to complete the whole varhop issue. The command owns the final push and completion result.

Final command returned `moved merged` and `deployed d22e7c4f9fbc..5cac0ae48aa8`. No `issue complete` or `epic complete` line was printed, so no completion broadcast applies to this leaf merge.
