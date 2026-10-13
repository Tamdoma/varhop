# Review A — prompt-core (check.review, initial)

Base: `d22e7c4` | Reviewed head: `5cc766b` | Diff: `git diff d22e7c4..HEAD` — 6 new `lib/*.mjs` (607 lines) + 6 test/resource files.

Scope checked: all modules line-by-line vs design's locked front-matter / repo-format / search / variable-editing / usage rules; token edge cases traced by hand; QML-engine constraint verified live (object spread, `Object.hasOwn`, `flatMap`, `matchAll`, `.at()`, `replaceAll` all rejected — already repaired in `5cc766b`; full suite green 49/49 after repair and after rebase).

## Fixes

- F1 — Empty-query ordering contradicts the settled rule. `search-merged` settled text (taken verbatim): "Empty query: full library by category, subcategory, title." `lib/search.mjs` `emptyRank` sorts category → title → subcategory (subcategory effectively only as tiebreak inside equal titles), and `lib/search.test.ts` encodes that order (`a/sub/a.md` before `a/y.md` before `a/sub/z.md`). Under the settled tuple order, a prompt with no subcategory sorts before subcategory'd siblings in the same category: expected `a/y.md`, `a/sub/a.md`, `a/sub/z.md`. Realistic source: a real library with mixed `prompts/a/x.md` and `prompts/a/sub/y.md` renders the browsing list in the wrong order today — any operator-built library with both depths shows it. Criterion hit: done-criterion 5's "then all prompts by category" with the settled ordering words it stands on. Fix requires reordering `emptyRank` and correcting the test expectation (test change → A's cited-expectation correction; the settled text is the citation).

## Nits

- N1 — `emptyRank` ignores the subcategory position entirely except as a last tiebreak; the two-tier design reading (subcategory grouped before title) vs tuple reading is debatable wording, but the settled text reads as a tuple. Promoted to F1 above; nothing else here.
- N2 — `import.mjs` rejects a few YAML shapes the spec neither accepts nor forbids (trailing `#comment` with no space after quoted scalars/flow lists; `tags: <scalar>` followed by block items concatenates rather than errors). Fail-loud, consistent with the taken error rules, no done-criterion depends on accepting them. Promote to Fix only if a real repo produces a shape that currently errors but must parse.
- N3 — `subseq` scorer is greedy-per-start; a pathological alignment could mis-rank two structured hits that both match. No realistic library title pair found; ranking-only, no correctness loss. Test would promote it.
- N4 — `snippet` splits the folded body by `\n` and assumes line-alignment with the original body (true for fold, which never emits `\n`). Coupling is internal to this file pair today; a fold that altered newlines would mis-slice. No current failure.

## Verification evidence

- `bun test` on head: 49 pass / 0 fail / 155 expects across 6 files; `test/sync.test.ts` (repo-sync, landed via rebase) also green — 69 total.
- QML criterion: `qml lib/qml-smoke.qml` offscreen exits 0, `smoke ok` logged.
- `akrogon status prompt-core`: no `Missing:` lines; no env needed.

## Docs

- `docs/reference-index.md` still resolves (README + CHART paths exist). No `AREA.md` in the diff. No documented behavior changed — README says only "varhop".

Verdict: fix (F1 only — wrong browsing order vs settled rule, test+code must move together under the cited-expectation correction).
