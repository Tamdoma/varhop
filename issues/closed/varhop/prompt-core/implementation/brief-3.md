# Worker brief 3 — import (leaf prompt-core, wave 2)

## 1. Goal

Implement `lib/import.mjs` for prompt-core: the importer that applies repo path rules, front-matter rules, and precomputes per-prompt folded search fields. Plan decisions D1, D2, D4, D5, D6, D14. Pure ES module, loads unchanged in bun and Qt 6.12's QML engine. Available imports: `lib/tokens.mjs` (`splitSegments`, `uniqueNames`) and `lib/fold.mjs` (`fold`) already exist in your worktree.

## 2. Acceptance criteria

`lib/import.test.ts` passes completely (16 tests). Interface:

```js
importLibrary(files: {path: string, text: string}[]):
  {prompts: Prompt[], errors: {path: string, line: number|null, message: string}[]}
```

`Prompt = {id, category, subcategory, fileName, title, description, tags, body, segments, names, search}` where `search = {title, fileName, tags, category, subcategory, description, body}` holds the FOLDED strings computed once at import.

Binding rules (locked):

Path rules
- Only `prompts/<category>/<name>.md` and `prompts/<category>/<subcategory>/<name>.md` import. `prompt.id` is the verbatim path.
- Deeper files under `prompts/` and loose `.md` files directly under `prompts/` (no category) produce an error entry with `line: null`; they are not prompts.
- Everything else is ignored silently: files outside `prompts/`, non-`.md` names, `.MD` (extension match is literal, case-sensitive), `README.md` at repo root.
- `fileName` keeps the `.md` extension; `title` defaults to the file stem (name minus `.md`) unchanged.

Front-matter boundary
- One leading BOM (U+FEFF) is stripped from every file first.
- A header exists only when line 1 is exactly `---` (CRLF accepted) and a later line is exactly `---`; the header ends at the first such line (may be at EOF). Any leading blank line or space before `---` means NO header — the whole file is body.
- Validity never moves the boundary. Malformed header content produces errors AND the body is still everything after the close line.
- `---` then `---` (empty header) is valid and is the escape for a body starting with `---`.
- No closing `---`: the WHOLE file (including the opening `---`) is body plus exactly one error `{line: 1, message matching /unclosed/i}`.
- Body is sliced by offset after the closing line's line break: nothing trimmed, line endings and final newline preserved verbatim.

Header line rules
- Known keys: `title`, `description` (single-line scalars), `tags`.
- Plain scalar: trimmed; a ` #` (space before `#`) starts a stripped comment (`C# notes` keeps `#`); `: ` inside an unquoted value is unsupported → error on that line, key counts absent.
- Single-quoted scalar: `''` escapes a quote, otherwise literal. Double-quoted scalar: escapes `\\ \" \n \r \t \uXXXX`.
- Empty value, `~`, `null` → key absent (`description → null`, `tags → []`, `title` falls back to stem).
- `tags` accepts flow list `[a, "b c"]` (quote-aware), block `- item` lines (indented or not, following a bare `tags:` or continuing), or one scalar → single tag. Plain non-string scalars in a flow list coerce to string (`2` → `"2"`). Duplicates dropped, first wins.
- Block scalars (`|`/`>`), flow maps, anchors/aliases, multiline quotes, nested maps on a known key → the key line gets an error, key counts absent.
- Unknown `key:` lines are skipped silently (no error). A header line that is not `key:` (e.g. bare prose, or an indented continuation that isn't a `- item` after `tags:`) gets a file-and-line error.
- Duplicate known key: first wins, the second line gets an error (`/duplicate/i`).
- A block-scalar's indented continuation lines error as unrecognized header lines.

Per-prompt
- `segments = splitSegments(body)`, `names = uniqueNames(body)` — import both from `./tokens.mjs`.
- `search` fields are folded via `fold` from `./fold.mjs`: `search.title`, `search.fileName` (stem, no `.md`), `search.tags` (array of folded tags), `search.category`, `search.subcategory` (folded or null), `search.description` (folded or null), `search.body`.

## 3. Read-first

- `lib/import.test.ts` — the executable spec; every assertion must pass unchanged.
- `lib/tokens.mjs`, `lib/fold.mjs` — your two imports.
- `/home/ivan/.pi/agent/skills/implement-issue/ponytail.md` — read before editing.

## 4. Change list and needed interfaces

You own exactly: `lib/import.mjs` (new). One commit.

Imports available (already in worktree): `./tokens.mjs` exports `splitSegments(body)` and `uniqueNames(body)`; `./fold.mjs` exports `fold(s)`.

Must land first: `lib/tokens.mjs`, `lib/fold.mjs` (landed). Consumer in a later wave: `lib/search.mjs` imports `./fold.mjs` directly and consumes `Prompt.search.*`; `lib/search.test.ts` imports `importLibrary` and its `prompt()` fixture helper requires `importLibrary` to produce error-free prompts for `lines = ["---", "title: \"...\"", "description: \"...\"", "tags: [\"..\", \"..\"]", "---", body].join("\n")` — JSON.stringify quoting must round-trip through your scalar parser (double-quoted values with `\"`, `\uXXXX`).

## 5. Do-not, reasons and exceptions

- Do not edit `lib/import.test.ts` or any test/resource file: locked; a red or wrong test is a mismatch returned to A with evidence. Exception: revised brief from A.
- Do not edit `lib/tokens.mjs` or `lib/fold.mjs`: owned by a landed unit; a defect there is a mismatch. Exception: revised brief.
- Do not create `lib/rebuild.mjs`, `lib/search.mjs`, or any other file. Exception: revised brief.
- No `node:`/`bun:` imports, `require`, `process`, TypeScript syntax: must load in QML. No exception.
- Do not validate UTF-8 (repo-sync's boundary owns it; `text` arrives valid). Do not trim or normalize body bytes. No exception.
- Do not commit `bun.lock`, `node_modules`, or anything outside `lib/import.mjs`. No exception.
- Return a mismatch with evidence to the plan author instead of changing scope or an interface; the exception is a revised brief from A authorizing that change. All exclusions above stand under this rule.

## 6. Ordered steps

1. Read `lib/import.test.ts` fully; note every asserted `body` byte sequence and error line.
2. Write `lib/import.mjs`: path filter → BOM strip → header detection → line-by-line header parse → body slice → prompt assembly (segments/names/search).
3. Run section 7 command; iterate until green.
4. Commit: `git add lib/import.mjs && git commit -m "Add prompt-core import module"`.

Advisory size: 1 file (~200-300 lines is fine), under 20 turns.

## 7. Commands

```
flock "$(git rev-parse --git-path akrogon-install.lock)" sh -c 'bun install' && bun test lib/import.test.ts
```

AKROGON_BASE: a467aa6b907791191c8cbf240f70173d0e52214d

Do not run other test files; `lib/search.test.ts` and `lib/qml.test.ts` import modules that do not exist yet and their failure is expected.

## 8. Done-when, evidence and report

Done when `bun test lib/import.test.ts` exits 0 and the file is committed. Report the commit ID and paste the command output.

Changed files and reasons: <paths and why>
Tests run: <commands and results>
Known limitations: <limitations or none known>
Unverified criteria: <criterion and why, or none>
