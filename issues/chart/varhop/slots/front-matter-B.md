# Front matter: blind notes B

Recommendations only. Read the brief, intake, fork Question/Carries and related Taken sections. No other slot's front-matter notes read. Sources below read **2026-10-13**. Research was read-only. Examples are proposed fixtures, not executed parser proofs.

## Q1. Recognizing a header

**Pick, reason, cost.** Reserve an exact first line `---` for a header, allowing one file-start UTF-8 BOM before it. Close at the first subsequent exact `---` line, including one at EOF. Lines use LF or CRLF; neither delimiter admits indentation, trailing spaces or comments. An empty header is valid. This follows familiar front-matter structure without guessing intent from field names. Cost: a body starting with the reserved line needs an empty header before it. No heuristic can distinguish a literal YAML example from identical intended metadata.

No closing line: show “unclosed front matter,” use filename/default metadata, and retain the **entire original file** as body. With a closing line but malformed/unsupported metadata: show the error, use default metadata, and keep the body suffix after the close. Do not make validity change the boundary of a structurally closed header.

**Rejected.** Searching for delimiters anywhere eats fenced examples. Treating everything through EOF as metadata loses an unclosed prompt. Recognizing only known keys misclassifies unknown-only headers and cannot resolve a literal `title:` example. A new marker adds a separate convention without removing the existing format choice.

**Evidence.** Tier `operator`: repo-format Taken requires optional in-file metadata and loading broken headers with an error. Tier `better-than-training`: [Jekyll](https://jekyllrb.com/docs/front-matter/) uses first-position triple-dash boundaries and allows empty headers. [Hugo](https://gohugo.io/content-management/front-matter/) selects formats by delimiters. [VS Code prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files) use an optional YAML header. [Obsidian](https://obsidian.md/help/properties) reserves file-start `---` for properties. [CommonMark](https://spec.commonmark.org/0.31.2/#thematic-breaks) and [GFM](https://github.github.com/gfm/#thematic-breaks) also make `---` a thematic break. None establishes the author's intent for ambiguous bytes.

**Pitfalls removed.** Fixtures: `---\nExplain this\n` must remain whole with an error. `---\ntitle: "Example"\n---\nDiscuss it` is necessarily metadata under this convention, even if intended as a YAML example. Prefixing `---\n---\n` makes that entire example literal body. A file starting with a fenced YAML block has no header. `--- \n` is body, not an opener.

**Missing question.** Explicitly approve the empty-header escape and its authoring cost. Arbitrary Markdown bodies remain representable, but not every headerless leading-dash file is unambiguous.

## Q2. The supported YAML subset

**Pick, reason, cost.** Use one-line top-level `key: JSON-value` entries. Keys are unquoted ASCII identifiers (`[A-Za-z_][A-Za-z0-9_-]*`), unique and separated from values by at least one space. `title`/`description` require JSON double-quoted strings; `tags` requires a JSON array of strings. Unknown keys accept the same JSON-value syntax and are then ignored. Empty strings and `[]` are valid. Blank lines and whole-line `#` comments are allowed. Decode values with QML's built-in `JSON.parse`, then validate the known fields once. This is a declared subset of YAML, not JSON sidecar storage or a claim to support all YAML. Cost: quote text and list members, and keep each value on one physical line.

Single quotes, bare text, inline comments, block lists, folded/literal multiline values, anchors, aliases and YAML-specific escapes are unsupported. Syntax/type errors or duplicate keys discard **all** metadata with a file/line error; the already located body still loads. Unknown keys are ignored within the supported grammar, not used to sneak arbitrary multiline YAML past the boundary parser.

**Rejected.** Splitting tags on commas breaks `tags: ["sales, enterprise", "ai"]`. Removing text after `#` breaks `title: "C#"`. Stripping surrounding quotes does not decode escapes. Expanding a hand parser toward full YAML creates a second language implementation. A new YAML dependency reopens the hand-parser choice rather than answering its subset.

**Evidence.** Tier `practitioner`: [Jon Schlinkert's gray-matter rationale](https://github.com/jonschlinkert/gray-matter#why-use-gray-matter), a widely used front-matter parser's author, recommends a dependable YAML library and rejects regex-only parsing. My recommendation differs because this fork specifies a hand parser: restrict the grammar instead of approximating YAML. Tier `better-than-training`: [YAML 1.2.2](https://yaml.org/spec/1.2.2/) establishes JSON compatibility, quoted-scalar semantics and unique mapping keys. [Qt's built-in objects](https://doc.qt.io/qt-6/qtqml-javascript-functionlist.html) include JSON. `/usr/share/omarchy/shell/Commons/Color.qml:182-202` parses a TOML subset, not YAML; `shell/plugins/bar/widgets/KeyboardLayoutModel.js:15-33` extracts fields from a known YAML producer. Neither safely parses arbitrary repository headers.

**Pitfalls removed.** Required cases: quoted commas/hash/colon/backslashes/escaped quotes, `tags: []`, duplicate `title`, numeric `title`, and mixed-type tags. Valid YAML such as `description: |`, `tags:\n  - ai`, `title: 'It''s fine'`, or `title: Draft # note` must report **unsupported syntax**, never become misleading literal search metadata. Obsidian's block tags and VS Code's single-quoted examples consequently need adaptation.

**Missing question.** Is this quoting cost acceptable, or is compatibility with those tools' emitted YAML required? Also approve whole-header metadata rejection rather than retaining a misleading partially parsed title/tags combination.

## Q3. Exact body bytes

**Pick, reason, cost.** Body begins after the closing delimiter's complete line ending. Consume that LF or CRLF as framing, preserve every following blank line, space, CRLF and final newline, and never trim or split/rejoin the body. A close at EOF yields an empty body. Retain original source plus offsets for variable reconstruction. Ignore a BOM only for header recognition: consume it with a recognized header, but retain it when the whole file is body, including the unclosed-header case. Cost: the loader/export path must prove fidelity instead of relying on editor text.

**Rejected.** Normalizing CRLF, globally removing BOMs, trimming blank lines, or copying a TextEdit document violates the taken source-based export contract. Jekyll's prohibition on BOM files is not a reason to silently delete this operator's bytes.

**Evidence.** Tier `operator`: repo-format/variable-editing/sync Taken preserve source bodies and neutralize checkout transforms. Tier `better-than-training`: [gray-matter source](https://raw.githubusercontent.com/jonschlinkert/gray-matter/master/index.js), lines 86-114, removes the close's line ending, but treats a missing close as EOF and returns empty content. Adopt the former rule, reject the latter. `/usr/lib/qt6/qml/Quickshell/Io/FileView.qml:32-51` exposes separate text/data access; [FileView documentation](https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/FileView/) does not prove the chosen decoding/BOM/export path is byte-preserving.

**Pitfalls removed.** For `---\r\ntitle: "X"\r\n---\r\n\r\nA\r\n`, expect exactly `\r\nA\r\n`. Cover BOM with/without header, mixed line endings, no final newline, empty body, and unclosed header. Compare unchanged source segments through actual clipboard export. No fidelity claim from source inspection alone.

**Missing question.** Define repository text encoding. Recommend valid UTF-8, with invalid encoding reported rather than replacement-character decoding presented as verbatim. This needs an explicit policy if no prior lock covers it.
