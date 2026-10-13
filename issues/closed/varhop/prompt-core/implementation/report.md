# Implementation report: prompt-core

## Refresh

- Prior base `a467aa6`, prior head `c810db7` → rebased onto `origin/main` `d22e7c4` (repo-sync landed during the pass), new head `5cc766b`. Clean rebase, no conflicts. `AKROGON_BASE` = `d22e7c4`.

## Changed files and reasons

| File | Reason |
|---|---|
| `lib/tokens.mjs` | Unit 1 (worker c826f22 → bbd2cf0): `splitSegments`, `uniqueNames` — criterion 3 |
| `lib/fold.mjs` | Unit 1: `fold` implementation (re-exported via `search.mjs`, D14) — criterion 5 |
| `lib/usage.mjs` | Unit 2 (worker 3f9b851 → 120c72d): `HALF_LIFE_MS`, `resetUsage`, `recordCopy`, `parseUsage` — criterion 6 |
| `lib/import.mjs` | Unit 3 (worker 3efde28 → 56c3226): path rules, front matter, folded `search` fields — criteria 1, 2 |
| `lib/rebuild.mjs` | Unit 4 (worker eb849ef → b0fdd34): `rebuild` — criterion 4 |
| `lib/search.mjs` | Unit 5 (worker 2e33850 → 289b61b): `fold` re-export, `rank`, `DISPLAY_CHUNK` — criterion 5 |
| `lib/{import,rebuild,search,usage}.mjs` | A repair commit `5cc766b` (pre-rebase `c810db7`): replaced constructs the QML engine rejects — `{...}` object spread (syntax error), `Object.hasOwn`, `flatMap`, optional catch binding `catch {}` — verified by probe: engine is ES2018-era (rejects `.at()`, `replaceAll`, `matchAll`, `Object.hasOwn`, `flatMap`; accepts `?.`, `??`, `Object.assign`, `Map`, `Set`, `normalize`, `[...iter]`). |

Plan artifact: `plan.md` (decisions D1–D14, regrouped waves, Implementation notes). Briefs: `implementation/brief-{1..5}.md`.

## Plan deviations folded in

- Wave regroup (recorded in plan.md): workers run in detached worktrees, so `import` needed `tokens.mjs`+`fold.mjs` landed → W2; `search` needed `import.mjs`+`usage.mjs` for its test → W3; `qml smoke` folded into A's criterion-7 proof.
- Search worker's two choices accepted after inspection: derived title (=== fileName stem) excluded from title-field scoring; empty-query sort is category → title (matches the test's encoded order; plan wording about subcategory-first superseded by the test, which the worker was right to follow).

## Verification — every done-criterion

Head `5cc766b`, all runs on the leaf worktree.

| Criterion | Proof command | Result |
|---|---|---|
| 1 front-matter fixtures | `bun test lib/import.test.ts` | 14 pass, 0 fail (68 expects) |
| 2 path rules | `bun test lib/import.test.ts` (paths test) | pass |
| 3 token grammar | `bun test lib/tokens.test.ts` | 8 pass, 0 fail |
| 4 rebuild | `bun test lib/rebuild.test.ts` | 7 pass, 0 fail |
| 5 search | `bun test lib/search.test.ts` | 12 pass, 0 fail (fold, AND, weights, V1 shape, body tier, frecency, empty order incl. 10-cap) |
| 6 usage | `bun test lib/usage.test.ts` | 7 pass, 0 fail |
| 7 qml load | `bun test lib/qml.test.ts` → `/usr/lib/qt6/bin/qml lib/qml-smoke.qml` offscreen | pass, qml exit 0, `smoke ok` logged |

Blocking check (verbatim `checks.test`):

```
akrogon run-check --name 'test' -- sh -c 'flock …bun install… && akrogon guard own-modules && bun test --pass-with-no-tests'
→ 69 pass, 0 fail, 270 expect() calls across 7 files (includes repo-sync's suite landed via rebase)
```

Intended-red evidence recorded in plan.md; first red run before product code: `0 pass / 6 fail / 5 errors`.

## Worker returns

- W1 tokens+fold: `c826f22`, 8 pass; limitation noted — escape text may emit adjacent text segments (allowed by spec).
- W1 usage: `3f9b851`, 7 pass, no limitations.
- W2 import: `3efde28`, 14 pass; strictness choices are fail-loud superset (blank header lines error, quoted scalars must close on the line) — consistent with "unrecognized header lines error". Also re-created its worktree after finding the path unprovisioned — verified intact before pick.
- W2 rebuild: `eb849ef`, 7 pass, no limitations.
- W3 search: `2e33850`, 12 pass; deviations above; body-row `score` is 0 (spec only requires below-structured).

## check.fix round (head 5cac0ae)

B's `check.repair` fixed B F1 (unknown metadata continuation lines) and B F4 (comments on empty values) in commits `0a528ed`+`400538d` and `bb47d39`+`4ea20f0`, each reproduction-test-first with `Test-Change:` trailers. It handed B F2 (= A F1) and B F3 to A.

- B F2: test correction `ba498fe` (red on head `4ea20f0`: expected `[a/y, a/sub/a, a/sub/z]`, code emitted title-interleaved order), fix `5cb4758` — `emptyRank` now sorts category → subcategory (null first) → title, the settled tuple order.
- B F3: test correction + regression `0cb78a4` (red: identical explicit titles `needle`/`needle` scored 6 vs 5), fix `5cac0ae` — removed the derived-title exclusion; `search.title` always scores at title weight. Weights fixture retargeted with an explicit non-matching title so fileName weight stays observable.

Refresh: base `d22e7c4` unchanged; head `4ea20f0` → `5cac0ae`. Proof on final head: `bun test` 72 pass / 0 fail / 280 expects across 7 files (repo-sync suite included via earlier rebase); blocking `checks.test` verbatim exits 0 with the same 72/0/280. Reverses the two search-worker deviations recorded above.

## Known limitations

- Subsequence scorer is greedy-per-start, O(field²·term) per term — fine at library scale; the 5000-prompt latency proof is overlay-plugin's, not this leaf's.
- `import.mjs` is stricter than the minimum spec in places that error rather than silently misread (per the taken error rules).

## Unverified criteria

None. All 7 done-criteria proven green on head; no env/credential requirements (`Missing:` clean, no `.env` touched).
