# Worker brief 4 — rebuild (leaf prompt-core, wave 2)

## 1. Goal

Implement `lib/rebuild.mjs` for prompt-core: turn segments plus values into the copy string. Plan decision D3 (`rebuild` derives `unset` from the segments itself; an empty string is a set value). Pure ES module, loads unchanged in bun and Qt 6.12's QML engine.

## 2. Acceptance criteria

`lib/rebuild.test.ts` passes completely (7 tests). Interface:

```js
rebuild(segments: Segment[], values: Record<string, string>):
  {text: string, unset: string[]}
```

`Segment = {kind:"text", text} | {kind:"token", name, raw}` (produced by `lib/tokens.mjs`, already in your worktree — the test calls `rebuild(splitSegments(body), values)`).

Binding rules (locked):
- `text` = concatenation of segments: text segments contribute `text`; token segments contribute `values[name]` when `name` is an OWN property of `values`, else `raw` (the verbatim `{{NAME}}`).
- An empty string value is set: `values = {A: ""}` → token contributes `""`, `A` not unset.
- A value containing `{{OTHER}}` is inserted literally — plain concatenation, never a re-parse or `String.replace`.
- With no values, the body is reproduced exactly EXCEPT each `\{{NAME}}` escape comes out as `{{NAME}}` (already handled: escapes arrive as text segments holding the literal).
- `unset` = unique token names absent from `values`, in first-appearance order (derive from segments, not from a `names` argument).
- CRLF bodies, missing final newline: verbatim pass-through (concatenation does this naturally — no line-ending logic).

## 3. Read-first

- `lib/rebuild.test.ts` — the executable spec; every assertion must pass unchanged.
- `lib/tokens.mjs` — the segment producer whose output you consume.
- `/home/ivan/.pi/agent/skills/implement-issue/ponytail.md` — read before editing.

## 4. Change list and needed interfaces

You own exactly: `lib/rebuild.mjs` (new). One commit.

`rebuild(segments, values)` — your module does not need to import `tokens.mjs` (it consumes segment objects), but importing it for nothing is unnecessary; keep the file self-contained (~20-30 lines).

Must land first: `lib/tokens.mjs` (landed — your worktree has it). Consumers: overlay-plugin (outside this leaf). The QML smoke calls `rebuild(segs, {B: "v"})` expecting `{text: "a v", unset: []}`.

## 5. Do-not, reasons and exceptions

- Do not edit `lib/rebuild.test.ts` or any test/resource file: locked; a red or wrong test is a mismatch returned to A. Exception: revised brief from A.
- Do not edit `lib/tokens.mjs` or create other `lib/*.mjs`: owned elsewhere. Exception: revised brief.
- No `node:`/`bun:` imports, `require`, `process`, TypeScript syntax: must load in QML. No exception.
- Do not use `Object.prototype` lookups for "set" (`name in values`/`values[name] !== undefined` alone would misbehave for `"toString"`-style keys — use `Object.hasOwn` or equivalent own-property check). Reason: correctness for arbitrary token names. No exception.
- Do not commit `bun.lock`, `node_modules`, or anything outside `lib/rebuild.mjs`. No exception.
- Return a mismatch with evidence to the plan author instead of changing scope or an interface; the exception is a revised brief from A authorizing that change. All exclusions above stand under this rule.

## 6. Ordered steps

1. Read `lib/rebuild.test.ts` fully.
2. Write `lib/rebuild.mjs`.
3. Run section 7 command; iterate until green.
4. Commit: `git add lib/rebuild.mjs && git commit -m "Add prompt-core rebuild module"`.

Advisory size: 1 file, under 8 turns.

## 7. Commands

```
flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c 'bun install' && bun test lib/rebuild.test.ts
```

AKROGON_BASE: a467aa6b907791191c8cbf240f70173d0e52214d

Do not run other test files; `lib/search.test.ts` and `lib/qml.test.ts` import modules that do not exist yet and their failure is expected.

## 8. Done-when, evidence and report

Done when `bun test lib/rebuild.test.ts` exits 0 and the file is committed. Report the commit ID and paste the command output.

Changed files and reasons: <paths and why>
Tests run: <commands and results>
Known limitations: <limitations or none known>
Unverified criteria: <criterion and why, or none>
