# Worker brief 2 — usage (leaf prompt-core, wave 1)

## 1. Goal

Implement the usage (decayed copy-frecency) module for prompt-core, plan decisions D10 and D11. Pure ES module, loads unchanged in bun and Qt 6.12's QML engine.

## 2. Acceptance criteria

`lib/usage.mjs` passes every test in `lib/usage.test.ts`:

- `HALF_LIFE_MS` exported, exactly `1209600000` (14 days).
- `resetUsage()` returns `{version: 1, entries: {}}`.
- `UsageState = {version: 1, entries: Record<promptId, {score: number, last: number}>}`; all times Unix epoch milliseconds.
- `recordCopy(usage, id, now)` returns a NEW state object (input never mutated — the test stringifies input before and after): the touched entry's stored score decays by `2^(-(now - last) / HALF_LIFE_MS)`, then `+1`, and `last = now`. New entries start `{score: 1, last: now}`. Entries for other ids are copied through UNCHANGED (decay applies only to the touched entry; decay-at-read happens inside `rank`, not here).
- `parseUsage(text)` returns `{state: UsageState}` for valid serialized state, `{error: <non-empty string>}` for anything else: malformed JSON, missing/wrong `version` (must be exactly 1), `entries` that is an array or non-object, entries missing numeric `score` or `last`. Never throws, never resets silently.

## 3. Read-first

- `lib/usage.test.ts` — the executable spec; every assertion must pass unchanged.
- `lib/search.test.ts` — read only to see how `resetUsage`/`recordCopy` results are consumed (`rank(prompts, query, usage, now)` treats `usage.entries[id].score` as frecency); you do not make this file pass.
- `/home/ivan/.pi/agent/skills/implement-issue/ponytail.md` — read before editing.

## 4. Change list and needed interfaces

You own exactly: `lib/usage.mjs` (new). One commit.

Signatures (locked interface):
- `recordCopy(usage, id, now): UsageState`
- `resetUsage(): UsageState`
- `parseUsage(text: string): {state: UsageState} | {error: string}`
- `export const HALF_LIFE_MS = 1209600000`

Must land first: nothing (wave 1). Consumer: `lib/search.mjs` (later unit) calls `parseUsage` indirectly via tests and reads `usage.entries[id].score`/`.last` inside `rank` — keep the exact shape.

## 5. Do-not, reasons and exceptions

- Do not edit `lib/usage.test.ts` or any `*.test.ts` / `qml-smoke.qml`: tests are locked; a red or wrong test is a mismatch returned to A, never a test fix. Exception: revised brief from A.
- Do not create any other `lib/*.mjs`: other units own them. Exception: revised brief.
- Do not use `node:`/`bun:` imports, `require`, `process`, TypeScript syntax, `Date.now()` inside these functions (all times come from the `now` parameter): QML compatibility and purity. No exception.
- Do not mutate the input state in `recordCopy`: the contract is a fresh object. No exception.
- Do not commit `bun.lock`, `node_modules`, or anything outside your owned path. No exception.
- Return a mismatch with evidence to the plan author instead of changing scope or an interface; the exception is a revised brief from A authorizing that change. All exclusions above stand under this rule.

## 6. Ordered steps

1. Read `lib/usage.test.ts` fully.
2. Write `lib/usage.mjs` (~40 lines: constant, three functions, a small shape validator).
3. Run section 7 command; iterate until green.
4. Commit: `git add lib/usage.mjs && git commit -m "Add prompt-core usage module"`.

Advisory size: 1 file, under 8 turns.

## 7. Commands

```
flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c 'bun install' && bun test lib/usage.test.ts
```

AKROGON_BASE: a467aa6b907791191c8cbf240f70173d0e52214d

Do not run other test files; they import modules that do not exist yet and their failure is expected.

## 8. Done-when, evidence and report

Done when `bun test lib/usage.test.ts` exits 0 and the file is committed. Report the commit ID and paste the command output.

Changed files and reasons: <paths and why>
Tests run: <commands and results>
Known limitations: <limitations or none known>
Unverified criteria: <criterion and why, or none>
