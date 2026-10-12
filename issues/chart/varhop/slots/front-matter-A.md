# front-matter: blind notes (slot A)

Read 2026-10-13. Tiers: [OP], [SRC], [DOC], [MK] (model knowledge, not fetched).

## Q1 Boundary
Pick: a file has front matter only when all of these hold:
1. Line 1 is exactly `---`, after stripping an optional BOM and allowing trailing spaces or a CR.
2. A later line is exactly `---`. That line closes the block.
3. Every line in between is blank, a `#` comment, a `key:` line at column 0, or an indented `- item` or continuation line under a key.

Otherwise the whole file is body, unchanged.

One error case: line 1 is `---`, line 2 is `title:`, `description:` or `tags:`, and there is no close. Show an "unclosed front matter" error and keep the whole file as body. Authors can force body by starting the file with a blank line.

Reason: rules 1 and 2 are the Jekyll rule [MK]. Rule 3 stops a body that starts with a `---` rule and has a second rule further down from being swallowed (C2 F4). The fallback is always "keep the text", so the failure mode is visible metadata in the body, never a lost body.

Cost: a markdown rule, then prose lines, then a closing rule would be body, which is correct. A file whose body starts with a YAML example of only `key: value` lines between two `---` lines is read as front matter. The author adds a blank first line.

Rejected:
- gray-matter's rule. An open with no close makes everything matter [MK: gray-matter treats a missing close as end of file]. That swallows the body.
- A fixed N-line window. It is arbitrary, and long tag lists break it.

## Q2 Subset
Pick:
- Top-level `key: value`. The value is plain text (trimmed, a ` #` comment stripped), single-quoted (`''` escape), or double-quoted (`\"` and `\\` escapes).
- `tags` takes either a flow list `[a, "b c"]` or block `- item` lines.
- Full-line `#` comments are allowed.
- Anything else (`|`, `>`, nested maps, anchors, multi-line flow lists, duplicate known keys) gives a per-file error naming the line. That key is ignored and the file still loads.
- Unknown keys and their indented lines are skipped silently (repo-format Taken).

Reason: this covers every way an author writes title, description and tags, and it never guesses at YAML it doesn't parse. Cost: valid YAML like `description: >` fails with an error instead of working.

Rejected: vendoring a YAML library into the plugin. It's a dependency for three fields, and the plugin runs as plain QML/JS.

## Q3 Body bytes
Pick: the body starts right after the closing line's line ending, with leading blank lines removed. Without front matter, the body is the whole file minus a leading BOM. Line endings inside the body stay as they are (CRLF fixture, sync Taken). A trailing newline is kept.

Reason: authors put a blank line after `---`, and copying it would start every prompt with an empty line. The BOM is file encoding, not text.

Cost: a deliberate leading blank line in a prompt with front matter is lost. A prompt without front matter keeps it.

## Pitfalls
- P1 Swallowed body: rule 3 plus the keep-text fallback. Fixtures: a body opening with a rule, an unclosed `---`, and a YAML example body.
- P2 Silent misread: anything outside the subset is an error, never a guess. Fixture: `description: >`.
- P3 CRLF `---\r`: detection trims the CR. The fixture is the existing CRLF one.

## Questions not asked
- Q4 Should the error list show the file's line number? I recommend yes. It's cheap.
