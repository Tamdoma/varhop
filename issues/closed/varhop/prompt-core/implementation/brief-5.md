# Worker brief 5 — search (leaf prompt-core, wave 3)

## 1. Goal

Implement `lib/search.mjs` for prompt-core: folding re-export, field scoring, scored subsequence matching, body tier, frecency and empty-query ordering. Plan decisions D7, D8, D9, D14. Pure ES module, loads unchanged in bun and Qt 6.12's QML engine.

Already in your worktree: `lib/fold.mjs` (`fold`), `lib/import.mjs` (`importLibrary`), `lib/usage.mjs` (`resetUsage`, `recordCopy`, `parseUsage`, `HALF_LIFE_MS`). Import `fold` from `./fold.mjs` and re-export it: `export { fold } from "./fold.mjs";` (QML-verified pattern).

## 2. Acceptance criteria

`lib/search.test.ts` passes completely. Interface (locked):

```js
export { fold } from "./fold.mjs";
export const DISPLAY_CHUNK = 50;
rank(prompts, query, usage, now): {id, score, matchedField, snippet|null}[]
```

Binding rules:

Matching
- Terms = folded query split on whitespace. Whitespace-only query = empty query.
- ANDed: every term must match some structured field via scored subsequence, or the prompt falls to the body tier. Subsequence only — NO typo tolerance (`cdoe` matches nothing), no smart case, no query syntax.
- Case-insensitive: query and fields both folded (`fold` already lowercases + strips marks).
- A query that is itself a subsequence of a longer term still works: `cdr` matches `Code Review` (tight, c-o-d-e R-e-v-i-e-w has c,d,r close together) above a title matching only with scattered letters.

Field scoring (D7)
- Per term, take the best field's score = subsequenceQuality × weight. Weights: title 6, fileName 5 (stem, no `.md` — use `search.fileName`), tags 4 (best tag), category/subcategory 3 (same weight, best of the two), description 2.
- Prompt score = sum of per-term scores. `matchedField` = the field behind the best-scoring term; ties take the heavier field.
- subsequenceQuality is a (0,1]-bounded fzf-V1-shaped score: any shape that ranks a tight/consecutive match above a scattered one satisfies the test — a simple gap-penalty scorer (e.g. start bonus + per-gap penalty normalized) is enough. Do NOT port fzf.

Body tier (D8)
- Runs only when structured results < DISPLAY_CHUNK (50). Requires EVERY term to have folded length ≥ 3. A body-only prompt needs every term as a folded substring of `search.body`.
- Body rows: `matchedField: "body"`, `score` below every structured row, `snippet` = the trimmed body line containing the first matched term (first term in query order). Structured rows: `snippet: null`.

Ranking (D9)
- Non-empty query: structured band (score desc), then body band. Within each band: frecency desc, then input order. Frecency = `usage.entries[id].score` decayed at read: `score · 2^(-(now - last)/HALF_LIFE_MS)`, missing entry = 0. Import `HALF_LIFE_MS` from `./usage.mjs`.
- Equal text score → frecency reorders (test: two prompts titled `repeat me`, the copied one first). Frecency NEVER reorders across relevance (title match with no usage still beats description match with usage).
- `score` in a row = the text score (structured band) or the body-tier score; the frecency tiebreak is not added into `score` (the test reads `score` for equal category/subcategory comparison).

Empty query
- Up to 10 recent copies first, ordered by `entries[id].last` desc (only ids present in `usage.entries`), then ALL remaining prompts sorted by category asc → subcategory asc (null first) → title asc. `matchedField: null`, `snippet: null`, `score: 0` for empty-query rows.
- Ordering check the test encodes: `a/sub/a.md` then `a/y.md` then `a/sub/z.md` — i.e. compare category, then subcategory (null sorts first among same category), then title.
- Usage entries pointing at ids not in `prompts` are ignored.

## 3. Read-first

- `lib/search.test.ts` — the executable spec; every assertion must pass unchanged (read the `prompt()` fixture helper to see the Prompt shape).
- `lib/fold.mjs`, `lib/import.mjs` (Prompt shape, `search.*` fields), `lib/usage.mjs` (UsageState, HALF_LIFE_MS).
- `/home/ivan/.pi/agent/skills/implement-issue/ponytail.md` — read before editing.

## 4. Change list and needed interfaces

You own exactly: `lib/search.mjs` (new). One commit.

Consumer-facing exports: `fold` (re-export), `rank`, `DISPLAY_CHUNK`. The QML smoke calls `Sea.rank(prompts, "q", resetUsage(), Date.now())` and `Sea.fold("Đorđe")`, `Sea.DISPLAY_CHUNK === 50`.

Must land first: `fold.mjs`, `import.mjs`, `usage.mjs` (all landed). Your test file imports all of them.

## 5. Do-not, reasons and exceptions

- Do not edit `lib/search.test.ts` or any test/resource file: locked; a red or wrong test is a mismatch returned to A with evidence. Exception: revised brief from A.
- Do not edit `fold.mjs`, `import.mjs`, `usage.mjs`: owned by landed units; a defect there is a mismatch. Exception: revised brief.
- No `node:`/`bun:` imports, `require`, `process`, TypeScript syntax: must load in QML. No exception.
- No typo tolerance, no per-character highlight output, no chunking/streaming: locked out. No exception.
- Do not commit `bun.lock`, `node_modules`, or anything outside `lib/search.mjs`. No exception.
- Return a mismatch with evidence to the plan author instead of changing scope or an interface; the exception is a revised brief from A authorizing that change. All exclusions above stand under this rule.

## 6. Ordered steps

1. Read `lib/search.test.ts` fully — note `order()` helper, `scoreOf`, and the exact empty-query expectation.
2. Write `lib/search.mjs` (~150 lines: scorer, term matching, body tier, frecency, empty query).
3. Run section 7 command; iterate until green.
4. Commit: `git add lib/search.mjs && git commit -m "Add prompt-core search module"`.

Advisory size: 1 file, under 16 turns.

## 7. Commands

```
flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c 'bun install' && bun test lib/search.test.ts
```

AKROGON_BASE: a467aa6b907791191c8cbf240f70173d0e52214d

Do not run `lib/qml.test.ts`; it is A's criterion proof and runs after your module lands.

## 8. Done-when, evidence and report

Done when `bun test lib/search.test.ts` exits 0 and the file is committed. Report the commit ID and paste the command output.

Changed files and reasons: <paths and why>
Tests run: <commands and results>
Known limitations: <limitations or none known>
Unverified criteria: <criterion and why, or none>
