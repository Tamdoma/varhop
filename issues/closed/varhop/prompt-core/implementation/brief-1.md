# Worker brief 1 — tokens + fold (leaf prompt-core, wave 1)

## 1. Goal

Implement the token grammar and the diacritic fold for prompt-core, plan decisions D2 (splitSegments/uniqueNames live in tokens.mjs), D14 (fold's implementation lives in lib/fold.mjs; lib/search.mjs will re-export it later — you do NOT write search.mjs). Pure ES modules that load unchanged in bun and in Qt 6.12's QML engine.

## 2. Acceptance criteria

- `lib/tokens.mjs` exports `splitSegments(body)` and `uniqueNames(body)`; every test in `lib/tokens.test.ts` passes.
- `lib/fold.mjs` exports `fold(s)`; a smoke run shows `fold("Đorđe") === "dorde"`, `fold("č Ž Š Ć Đ") === "c z s c d"`, `fold("ÁbC") === "abc"`.
- Both files parse as ES modules under bun with no `node:`/`bun:` imports (QML compatibility: no `require`, no `process`, standard ES only).

Binding grammar (locked, do not renegotiate):
- Token = `{{` + `[A-Z0-9_]+` + `}}`. No first-character rule: `{{1}}`, `{{_X}}`, `{{A1_2}}` are all tokens.
- `{{{NAME}}}` parses as text `{`, token `NAME`, text `}`.
- Tokens inside code fences count.
- `\{{NAME}}` (backslash directly before a valid token) yields a text segment holding the literal `{{NAME}}`. The backslash is removed ONLY before a valid token: `\{{abc}}`, `\{{NA-ME}}`, `\x{{T}}` stay byte-for-byte literal.
- Anything not matching the grammar (`{{abc}}`, `{{Name}}`, `{{NAME`, `{NAME}`, `{{}}`, `{{NA ME}}`, `{{NA-ME}}`) stays literal text.
- Segment = `{kind:"text", text} | {kind:"token", name, raw}` where `raw` is the verbatim `{{NAME}}`. Adjacent text may merge; the test asserts concatenated text plus exact segmentation for the simple cases listed.
- `uniqueNames` returns unique token names in first-appearance order.
- Fold rule: lowercase, NFD, strip combining marks U+0300–U+036F, map `đ`/`Đ`→`d`. No "dj" alias, no locale tricks.

## 3. Read-first

- `lib/tokens.test.ts` — the executable spec for tokens.mjs; every assertion must pass unchanged.
- `lib/search.test.ts` — read ONLY the `fold` test block for exact fold expectations; you do not make this file pass.
- `/home/ivan/.pi/agent/skills/implement-issue/ponytail.md` — read before editing.

## 4. Change list and needed interfaces

You own exactly: `lib/tokens.mjs` (new), `lib/fold.mjs` (new). Commit both in one commit.

Signatures:
- `splitSegments(body: string): Segment[]`
- `uniqueNames(body: string): string[]`
- `fold(s: string): string`

Must land first: nothing (wave 1). Consumers in later waves: `lib/import.mjs` imports `splitSegments`, `uniqueNames` from `./tokens.mjs`; `lib/search.mjs` re-exports `fold` from `./fold.mjs`. Do not write those files.

## 5. Do-not, reasons and exceptions

- Do not edit `lib/tokens.test.ts` or any `*.test.ts` / `qml-smoke.qml`: tests are locked; a red or wrong test is a mismatch you return to A with evidence, never a test fix. Exception: a revised brief from A.
- Do not create `lib/import.mjs`, `lib/rebuild.mjs`, `lib/search.mjs`, `lib/usage.mjs`: other units own them; a wrong shared interface is a mismatch. Exception: revised brief.
- Do not use `node:` or `bun:` imports, `require`, `process`, or TypeScript syntax: the files must load in the QML engine. No exception.
- Do not commit `bun.lock`, `node_modules`, or anything outside your two owned paths. No exception.
- Do not add token defaults, hints, or lowercase tolerance: locked out by design. No exception.
- Return a mismatch with evidence to the plan author instead of changing scope or an interface; the exception is a revised brief from A authorizing that change. All exclusions above stand under this rule.

## 6. Ordered steps

1. Read `lib/tokens.test.ts` fully and the `fold` block of `lib/search.test.ts`.
2. Write `lib/tokens.mjs` implementing the grammar (a scanner, not one big regex chain; keep it small).
3. Write `lib/fold.mjs` implementing fold per the rule (decompose + strip marks + đ→d; `String.prototype.normalize` and `toLowerCase` are standard ES and available in the QML engine).
4. Run section 7 commands; iterate until `lib/tokens.test.ts` is green and the fold smoke prints the three true values.
5. Commit `lib/tokens.mjs` and `lib/fold.mjs` in one commit: `git add lib/tokens.mjs lib/fold.mjs && git commit -m "Add prompt-core tokens and fold modules"`.

Advisory size: 2 files, under 12 turns.

## 7. Commands

```
flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c 'bun install' && bun test lib/tokens.test.ts
bun -e 'import {fold} from "./lib/fold.mjs"; console.log(fold("Đorđe") === "dorde", fold("č Ž Š Ć Đ") === "c z s c d", fold("ÁbC") === "abc")'
```

AKROGON_BASE: a467aa6b907791191c8cbf240f70173d0e52214d

Do not run other test files; they import modules that do not exist yet and their failure is expected.

## 8. Done-when, evidence and report

Done when `bun test lib/tokens.test.ts` exits 0, the fold smoke prints `true true true`, and both files are committed. Report the commit ID and paste the command outputs. If `String.prototype.normalize` or `toLowerCase` behaves differently than expected under plain bun, flag it — the same code must run in the QML engine later.

Changed files and reasons: <paths and why>
Tests run: <commands and results>
Known limitations: <limitations or none known>
Unverified criteria: <criterion and why, or none>
