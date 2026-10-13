# Plan: prompt-core

Debate off (`debate: "no"` in state.yaml); synthesized directly from brief + design + live surfaces.

## Decisions

- D1 — Module layout matches the brief's five capabilities, one ES module each: `lib/import.mjs`, `lib/tokens.mjs`, `lib/rebuild.mjs`, `lib/search.mjs`, `lib/usage.mjs`. Pure JS, no Node/Bun/QML APIs; each loads unchanged in bun and the QML engine. `fold` is exported from `lib/search.mjs` per the locked interface; the implementation lives in shared `lib/fold.mjs` (see D14) and `search.mjs` re-exports it (verified: QML engine accepts `export { fold } from "./fold.mjs"`).
- D2 — `splitSegments` and `uniqueNames` live in `tokens.mjs`; `importLibrary` calls them so every `Prompt` carries `segments` and `names` precomputed.
- D3 — `rebuild` derives `unset` itself from the token segments: names in first-appearance order that are absent from `values`. An empty string is a set value (variable-editing Q3: empty is distinct from unset).
- D4 — `Prompt.fileName` keeps the `.md` extension; `search.fileName` is the folded stem without `.md`. `title` fallback is the stem unchanged (criterion 2).
- D5 — Path rule: only `prompts/<category>/[<subcategory>/]<name>.md` imports. `prompts/<name>.md` (no category) and deeper files produce an error with `line: null`. Anything else (`prompts/*.txt`, outside `prompts/`, case-mismatched `.MD`) is ignored — consistent with the "deeper files shown with an error note" taken rule applied to every malformed placement. Noted for review: the design names only the deeper case; loose `.md` directly under `prompts/` erroring is this plan's extension of that rule.
- D6 — Header scan is per line: a `key:` line inside the header that isn't a known key and isn't a `tags:` block item is a malformed header line and gets a file-and-line error; unknown `key:` lines are skipped silently. A block-scalar value (`description: |`) errors on its own line, and its indented continuation lines error as unrecognized header lines.
- D7 — Field weights (term best-field score = subsequence quality × weight): title 6, fileName 5, tags 4, category/subcategory 3, description 2. Category and subcategory share weight 3. `matchedField` is the field behind the best-scoring term; ties take the heavier field.
- D8 — Body tier runs only when the structured result count is strictly below `DISPLAY_CHUNK` (50), requires every query term to have folded length ≥ 3, matches the folded body as a substring, and appends below all structured rows with `matchedField: "body"` and a one-line snippet = the trimmed body line holding the first matched term.
- D9 — Ranking: total score desc → frecency (decayed `UsageState` score) desc → input order. Body rows form a band below structured rows and are frecency-ordered within the band. Empty/whitespace query: up to 10 recently copied prompts by `last` desc, then the rest by category, subcategory (null first), title.
- D10 — `recordCopy` decays only the touched entry at copy time (`score·2^(-(now-last)/HALF_LIFE_MS) + 1`); decay at read time happens inside `rank`. Returns a fresh state object; input is never mutated.
- D11 — `parseUsage` returns `{state}` or `{error}`; it validates version === 1, entries is a non-array object, and every entry has numeric `score` and `last`. Never resets silently.
- D12 — QML smoke resource `lib/qml-smoke.qml` is checked in beside the modules (relative imports require it). `Qt.exit` schedules quit and the last call wins, so the script collects failures and exits exactly once. `QT_FORCE_STDERR_LOGGING=1` surfaces `console` output.
- D13 — Env: `akrogon status` shows no `Missing:` lines and the design names no credentials. No blockers.
- D14 — `fold` lives in `lib/fold.mjs`, imported by `import.mjs` (precomputed search fields) and re-exported through `lib/search.mjs` so the locked `fold` interface stays in `search.mjs`. `fold.mjs` is owned by the import unit; `search.mjs` may not exist when `import.mjs` is built (disjoint worktrees), and verified QML re-export keeps the contract in one place without duplicating the fold rule.

## Read-first

- `brief.md`, `design.md` (this leaf folder) — contract and pinned interfaces.
- `issues/chart/varhop/forks/front-matter.md` — boundary, values, error rules, fixture list.
- `issues/chart/varhop/forks/search.md` — settled ranking/fold/frecency, latency target context.
- `issues/chart/varhop/forks/variable-editing.md` — token grammar pinning.
- `issues/chart/varhop/forks/repo-format.md` — path rules.

## Interfaces (design-locked)

- `importLibrary(files: {path, text}[]): {prompts: Prompt[], errors: {path, line: number|null, message}[]}` — `lib/import.mjs`
- `splitSegments(body): Segment[]`, `uniqueNames(body): string[]` — `lib/tokens.mjs`; `Segment = {kind:"text", text} | {kind:"token", name, raw}`
- `rebuild(segments, values): {text, unset}` — `lib/rebuild.mjs`
- `fold(s): string`; `rank(prompts, query, usage, now): {id, score, matchedField, snippet|null}[]`; `DISPLAY_CHUNK = 50` — `lib/search.mjs`
- `recordCopy(usage, id, now): UsageState`; `resetUsage(): UsageState`; `parseUsage(text): {state}|{error}`; `HALF_LIFE_MS = 1209600000` — `lib/usage.mjs`

## Waves

No shared test resources. `lib/qml.test.ts`, `lib/qml-smoke.qml` and the `*.test.ts` files already exist on the branch (committed red before product code). Regrouped at implement: workers run in detached worktrees where only landed waves exist, so `import.mjs` cannot import the same-wave `tokens.mjs` — `import.mjs` keeps the locked segments/names contract by importing `splitSegments`/`uniqueNames` from `tokens.mjs` rather than duplicating the grammar, which puts `import` in W2. `fold.mjs` rides with the tokens unit: its behavioral assertions live in `search.test.ts`, unreachable in W1, and a two-line shared module does not need its own worker. The `qml smoke` unit folded into A's criterion-7 proof: `qml-smoke.qml` is already written and workers edit no test-side file. The run stays delegated because W1 holds 3 units. Final grouping:

| Wave | Unit | Owned paths | Depends on |
|---|---|---|---|
| W1 | tokens + fold | `lib/tokens.mjs`, `lib/fold.mjs` | — |
| W1 | usage | `lib/usage.mjs` | — |
| W2 | import | `lib/import.mjs` | `lib/tokens.mjs`, `lib/fold.mjs` |
| W2 | rebuild | `lib/rebuild.mjs` | `lib/tokens.mjs` (test import) |
| W3 | search | `lib/search.mjs` | `lib/fold.mjs` (module import); `lib/import.mjs`, `lib/usage.mjs` (test imports — same-wave isolation bars it from W2) |

## Verification

Blocking check: `checks.test` = `akrogon run-check --name 'test' -- sh -c 'flock … bun install … && akrogon guard own-modules && bun test --pass-with-no-tests'` (rerun trigger: any `lib/` change). Size: seconds.

| Criterion | Proof command | Test file | Catches | Intended red now |
|---|---|---|---|---|
| 1 front-matter fixtures | `bun test lib/import.test.ts` | `lib/import.test.ts` (fixture tests) | wrong boundary, quoting, tags, errors | `Cannot find module './import.mjs'` |
| 2 path rules | `bun test lib/import.test.ts` | `lib/import.test.ts` (paths test) | depth, ignore, id, stem default | same |
| 3 token grammar | `bun test lib/tokens.test.ts` | `lib/tokens.test.ts` | grammar, escape, order | `Cannot find module './tokens.mjs'` |
| 4 rebuild | `bun test lib/rebuild.test.ts` | `lib/rebuild.test.ts` | verbatim round-trip, unset list, literal values | `Cannot find module './tokens.mjs'` |
| 5 search | `bun test lib/search.test.ts` | `lib/search.test.ts` | fold, AND, weights, V1 shape, body tier, frecency, empty order | `Cannot find module './import.mjs'` |
| 6 usage | `bun test lib/usage.test.ts` | `lib/usage.test.ts` | decay math, purity, parse rejection | `Cannot find module './usage.mjs'` |
| 7 qml load | `bun test lib/qml.test.ts` | `lib/qml.test.ts` + `lib/qml-smoke.qml` | engine incompatibility, export shape | qml exits 2: `import.mjs unavailable` |

Observed red: `bun test` → `0 pass / 6 fail / 5 errors` (5 × `Cannot find module`, qml exit ≠ 0); `bun test --pass-with-no-tests` exits 1. Same through the `checks.test` wrapper.

No criterion needs new proof machinery: bun:test is configured, the qml binary is an existing system tool (`/usr/lib/qt6/bin/qml`, Qml Runtime 6.12.0).

## Docs

No agent or human doc is affected: `docs/reference-index.md` points at the README and CHART, and the format contract lives in `design.md`. README stays untouched.

## Implementation notes (2026-10-13)

- `.mjs` files must run in the QML engine's ECMAScript environment: no `node:`/`bun:` imports, no TypeScript syntax, no `require`/`process`/`globalThis` host assumptions beyond standard ES globals. Qt 6.12 supports ES modules, classes, `const`/`let`, template literals, `Map`/`Set`, `Intl`-free string methods (`normalize` is available — verify in worker worktree; if `String.prototype.normalize` is absent in the QML engine, return a mismatch, do not substitute a table).
- `qml-smoke.qml` and `*.test.ts` are test-side files committed on the branch; workers never edit them. A red or wrong planned test is a mismatch returned to A.
- `bun.lock` is not gitignored; `bun install` may create it in worker worktrees. Never commit it; commits add only the unit's owned `lib/*.mjs` paths.
- Wave regroup recorded in Waves: `import` moved to W2 (needs `tokens.mjs` + `fold.mjs`), `search` to W3 (its test imports `import.mjs` + `usage.mjs`), `fold` owns `lib/fold.mjs` alone in W1, `qml smoke` folded into A's criterion-7 verification.
