# Front matter boundary

## Question
Q1. When does a prompt file have front matter? The exact rule for where the front matter starts and ends, and what happens to a file whose body starts with `---` (a Markdown rule, a YAML example, a fence) or that has an opening `---` with no close.
Q2. Which YAML subset the hand parser accepts for `title`, `description` and `tags` (quoting, inline `[a, b]` lists vs block `- a` lists, multiline values, comments), and what it does with lines outside that subset without silently misreading valid YAML.
Q3. Which bytes are the body: what follows the closing line (the newline after `---`, a blank line), BOM and CRLF handling, so copy stays verbatim.

### Carries
- repo-format Taken: YAML-lines front matter in the same file, optional `title` (default file name), `description`, `tags`, unknown keys ignored, broken front matter still loads with an error shown, bodies copied verbatim (forks/repo-format.md:25).
- C2 F4 (slots/review-C2.md:20): a body opening with `---` or a YAML example is read as front matter; a missing close swallows the body; a hand parser that differs from YAML misreads silently.
- variable-editing Taken: copy rebuilt from source segments; CRLF/BOM/final-newline fixture (forks/variable-editing.md).
- sync-and-auth Taken: `$GIT_DIR/info/attributes` neutralizes transforms, CRLF fixture proven.
- search Taken: title, tags, description are scored fields.

## Taken (2026-10-13)
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
