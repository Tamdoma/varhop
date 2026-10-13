# Design: prompt-core

## Binding decisions, verbatim

### repo-format (issues/chart/varhop/forks/repo-format.md)
#### Taken

2026-10-12 operator: `| 1a | 2a | 3a | 4a |` (Q5, what the Notion prompts look like, not answered).
Taken so far: Q1 `prompts/<category>/<subcategory>/<name>.md`, subcategory optional, deeper files shown with an error note, README outside `prompts/` ignored, no version file in v1 (foreclosed: any depth). Q2 YAML-lines front matter in the same file, optional `title` (default file name), `description`, `tags`, unknown keys ignored, broken front matter still loads with an error shown (foreclosed: JSON sidecar, no metadata). Q3 uppercase-only `{{NAME}}` (A-Z, 0-9, underscore), anything else in braces is literal, `\{{NAME}}` for literal (foreclosed: any case). Q4 no defaults or hints in v1; unknown keys ignored so they can be added later (foreclosed: `vars` now).

2026-10-12 operator, Q5: `it doesn't matter, I will adapt them to the new version. I'll create a new repo from scratch. The only requirement is that they're in markdown format, and they can contain and types of spaces and signs, paragraphs, etc.`
Taken: Q1-Q4 as recorded above. Q5: no migration or import tool; the operator builds a new repo to this format. Binding: prompt bodies are arbitrary Markdown and are copied verbatim (any whitespace, symbols, paragraphs); only `{{NAME}}` tokens and the `\{{` escape are interpreted.

### front-matter (issues/chart/varhop/forks/front-matter.md)
#### Taken (2026-10-13)
Operator answer: `1a | 2a | 3a`. The defaults presented were not objected to and are recorded as taken. Sources: slots/front-matter-{A,B,C,merged,rebuttal-B,rebuttal-C}.md.

Boundary (1a, B's rule)
- A header exists when line 1 is exactly `---` (after one optional BOM, with CRLF accepted) and a later line is exactly `---`. The header ends at the first such line, which may be at EOF.
- Validity never moves the boundary. A malformed header shows errors, and the body is everything after the close.
- An empty header (`---` then `---`) is valid. It is the documented escape for a prompt that must start with `---`.
- With no close, the whole file is body and an "unclosed front matter" error is shown.
- A leading blank line or space means there is no header.

Values (2a, A/C subset)
- `title` and `description` are single-line scalars. They can be plain (trimmed, with a ` #` comment stripped, and `: ` inside a value unsupported, so quote it), single-quoted (`''` escape), or double-quoted (`\\ \" \n \r \t \uXXXX`).
- Empty values, `~` and `null` mean absent.
- `tags` accepts a flow list `[a, "b c"]` (quote-aware), block `- item` lines (indented or not), or one scalar as a single tag. Duplicate tags are dropped.
- Block scalars, flow maps, anchors and aliases, multiline quotes and nested maps on a known key are unsupported.
- Unknown keys and their lines are skipped silently.

Errors (3a)
- An unsupported or malformed known key is ignored with a file and line error. The other keys stay.
- For a duplicate known key, the first wins and the second gets an error.

Body bytes
- The body is sliced by offset after the closing line's line break. Nothing is trimmed. Line endings and the final newline are preserved.
- One leading BOM is stripped from every file (default).
- Invalid UTF-8 is a file error, validated at the raw-data boundary (FileView data vs text, proof owed). Replacement-character decoding is never called verbatim.

Fixtures: a thematic break, then prose, then a break (the prose becomes an error and the body after the second break, per 1a); a YAML example body; an unclosed `---`; a title with `: ` and `#`; `description: |`; BOM plus a CRLF header with leading blank lines and no final newline; a BOM without a header; the empty-header escape; a duplicate title; mixed-type tags; indentless block tags; an invalid UTF-8 file.

### variable-editing (issues/chart/varhop/forks/variable-editing.md)
#### Taken

2026-10-12 operator: `1a | 2a | 3a`
- Q1 values only, prose fixed (settled by all slots, presented and not objected).
- Q2 one stop per unique name, first-appearance order, mirrors, Tab/Shift+Tab wrap, first stop selected on open, no final stop.
- Q3 filled values show without braces and stay revisitable; Delete on a selected value makes it empty; Delete again on an empty value restores unset `{{NAME}}` (operator 1a; foreclosed: separate Reset action). Hide and resume keeps the exact cursor and selection (operator 2a; foreclosed: reselect on show). Enter inserts a newline, Tab is the only navigation key. Per-variable semantic undo/redo including reset.
- Q4 copy rebuilt from parsed source segments plus values; grammar `{{[A-Z0-9_]+}}`, `{{{NAME}}}` = `{` + token + `}`, tokens in code fences count, backslash removed only before a valid token, pasted `{{OTHER}}` literal. Pasted values may be normalized by Qt (CRLF/U+2028/U+2029 to LF, NBSP to space); accepted for v1 (operator 3a; foreclosed: exact value-input path).
- Editor mechanism left to leaf design with the shared proof list in Findings.

### search (issues/chart/varhop/forks/search.md)
#### Taken

2026-10-12 operator: `1a | 2a`
- D-a 1a: body searched as a folded substring at the lowest weight; terms of 3+ characters only; runs only when structured matches are few; body-only rows show a one-line snippet around the first matched term (foreclosed: metadata-only search). Long-body performance is part of the latency proof.
- D-b 2a: decayed frecency of successful whole-prompt copies per prompt id, stored in a repo-id-scoped state-dir file (never shell.json), applied only after text relevance; empty query shows up to 10 most recently copied prompts first, then the library by category. Storage errors are shown, never silently reset (foreclosed: no usage store).
- All Settled items in Findings stand as presented and not objected.

### copy-and-close (issues/chart/varhop/forks/copy-and-close.md)
#### Taken

2026-10-12 operator: `1a`
- Esc in search: first Esc clears a non-empty query, Esc on an empty query hides (first-party habit; foreclosed: hide and keep the query).
- All Settled items in Findings stand as presented and not objected: wl-copy over stdin with exit-0 close, no auto-paste, history capture accepted, empty output valid, unset copied as `{{NAME}}` with a count, editor Ctrl+C and Ctrl+Shift+C always copy the whole prompt, editor Esc hides with the draft kept, "Find another prompt" binding owed to settings-and-hotkey, draft in memory only (survives hide and theme change, not plugin reload/update or shell restart).

### Excluded binding decisions
- form-factor, sync-and-auth and settings-and-hotkey: they belong to overlay-plugin and repo-sync. This leaf has no I/O, no QML views and no processes.
- From copy-and-close, only the unset-as-{{NAME}} rebuild and the count belong here. Clipboard, hide and keys belong to overlay-plugin.
- From search, ListView, PointerMoveGate, selection keeping, the pinned Resume row, storage-error display and the live latency proof belong to overlay-plugin. Only the scoring, folding, body tier, frecency math and empty-query order belong here.
- From front-matter, the invalid UTF-8 fixture and the raw-boundary validation belong to repo-sync, which proves them with iconv at its boundary (repo-sync criterion 4). importLibrary receives text that is already valid. (A,C)

## Standing design

/home/ivan/.claude/skills/chart-issues/assets/standing-design.md

- Proof is bun:test through the blocking test check. Each done-criterion's fixtures are its tests. There are no vanity tests and no mutation score. New behavior shows one deliberate break turning red.
- The QML-load criterion spawns /usr/lib/qt6/bin/qml offscreen from a bun test. That is a real-boundary check, not machinery, and it uses existing system binaries.
- No auth, secrets or outside calls are in scope.

## Leaf architecture

Owned paths: lib/*.mjs and lib/*.test.ts (bun:test). The interfaces below are the contract overlay-plugin builds against. (A,B,C)
- importLibrary(files: {path: string, text: string}[]): {prompts: Prompt[], errors: {path: string, line: number | null, message: string}[]}
- Prompt = {id (path), category, subcategory | null, fileName, title, description | null, tags: string[], body: string, segments: Segment[], names: string[], search: {title, fileName, tags: string[], category, subcategory | null, description | null, body}}. `search` holds the folded strings, computed once at import, so rank never re-folds the library per keystroke. (A,C)
- Segment = {kind: "text", text} | {kind: "token", name, raw}. An escape is a text segment holding the literal `{{NAME}}`. (A,B,C)
- rebuild(segments, values: Record<string, string>): {text: string, unset: string[]}
- fold(s: string): string
- rank(prompts, query: string, usage: UsageState, now: number): {id, score, matchedField, snippet | null}[]. A snippet is built only for body-only rows within the first DISPLAY_CHUNK results, by folding the original body around the match. (A,C)
- UsageState = {version: 1, entries: Record<promptId, {score: number, last: number}>}. All times are Unix epoch milliseconds. (A,B)
- recordCopy(usage, id, now): UsageState decays the stored score by 2^(-(now - last) / HALF_LIFE_MS), adds 1, and sets last = now. (A,B)
- resetUsage(): UsageState returns `{version: 1, entries: {}}`.
- parseUsage(text: string): {state: UsageState} | {error: string} rejects malformed or wrong-version JSON with a message and never resets silently. (A,B)
Constants: DISPLAY_CHUNK = 50 rows, HALF_LIFE_MS = 14 days. Both are exported. Exclusions: file reading, git, clipboard, QML.
Main step before the leaf opens (door): issues/config.yaml checks.test = "bun test --pass-with-no-tests".
