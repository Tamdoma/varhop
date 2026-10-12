# front-matter: merged (A, 2026-10-13)

Sources: front-matter-{A,B,C}.md. Tags list the slots whose notes say the line.

## Agreed
- A header can only start on line 1 with an exact `---` line (after an optional BOM). A leading blank line means no header (A,B,C). CRLF on the delimiter lines is accepted (A,B,C).
- An opening `---` with no close: the whole file is body and the header is not swallowed. An "unclosed front matter" error is shown (A,B,C; A,C show it only when a known key sits on the opening lines, B always).
- Rejected: gray-matter's missing close meaning end of file (A,B,C); a delimiter search anywhere in the file (B,C); vendoring a YAML library (A,B,C).
- Never approximate YAML silently. Anything outside the subset gives a visible error naming the file and line (A,B,C).
- Body is sliced by offset from the source string, never split and rejoined. Line endings and the final newline are preserved (A,B,C). The newline ending the closing `---` line is framing, not body (A,B,C).
- Unknown keys are ignored (A,B,C, repo-format Taken).
- Error entries carry a line number (A Q4, C U3, B "file/line error").

## Disagreements
- D-a What makes a closed `---` block a header:
  - (B) Position only. Line 1 `---` plus a later `---` line is always a header. A malformed header shows an error, and the body is what follows the close. To make a body that starts with `---`, the author writes an empty header (`---` then `---`). No heuristics.
  - (A) Position plus shape. Every line between must look like header syntax, otherwise the whole file is body.
  - (C) Position plus shape plus at least one known key (title, description or tags), with the close required within 64 lines. A blank first line is the escape.
- D-b Value syntax:
  - (B) Values are JSON (`title: "X"`, `tags: ["a", "b"]`) decoded with `JSON.parse`. Exact, with nothing to hand-write. Bare text, single quotes and block lists are errors.
  - (A,C) YAML subset: plain, single-quoted and double-quoted scalars, plus flow `[a, b]` or block `- a` tags. C adds inline `#` comments, `: ` in a plain value being unsupported, and a single scalar tag.
- D-c Error scope: one bad key is ignored with an error and the other keys stay (A,C) vs any error discards all metadata (B). Duplicate known key: first wins with an error (C), ignored with an error (A), or all metadata discarded (B).
- D-d Leading blank lines after the close: kept verbatim (B,C) vs trimmed (A). A concedes to B,C: verbatim is the taken contract.
- D-e BOM: stripped from every file (A,C, variable-editing import rule) vs consumed only with a recognized header and kept when the whole file is body (B).

## Questions
- N1 (B) Encoding: require valid UTF-8 and report invalid files, or accept the decode step's replacement characters (C P8: FileView text already decodes lossily, so it can't be detected at this layer)?
- N2 (C U2) A multiline description later? Out of v1 by all slots.

## Fixtures (A,B,C, merged)
- A thematic break, then prose, then a second break.
- A YAML example body.
- An unclosed `---` with a title.
- A title containing `: ` and `#`.
- `description: |`.
- BOM plus a CRLF header, a body with leading blank lines and no final newline.
- An escape case per the rule chosen in D-a.
- A duplicate title.
- Mixed-type tags.
