# Front matter boundary: blind notes, slot C (2026-10-13)

Tiers: operator = Taken sections; better-than-training = primary docs/source and inspected local code, read 2026-10-13.

## Facts inspected

- Established convention is positional and validity-based: Jekyll requires front matter to be "the first thing in the file" and "valid YAML set between triple-dashed lines" (https://jekyllrb.com/docs/front-matter/). gray-matter delegates the block to a real YAML engine (js-yaml, https://github.com/jonschlinkert/gray-matter/blob/master/lib/engines.js) and strips a BOM before parsing (lib/utils.js `toString`). CommonMark has no front matter; a `---` line is a thematic break (https://spec.commonmark.org/0.31.2/ §4.1), which is exactly the body case that must not be swallowed. [better-than-training]
- QML has no YAML parser (no yaml module under /usr/lib/qt6/qml; the only "yaml" hit in Omarchy shell QML/JS is a comment). The local hand-parser precedent, Commons/Color.qml:182-203 `parseShell`, is regex-per-line and silently `continue`s on any line it cannot match (:198). That silent-skip behavior is what repo-format's "error shown" rule forbids here, so varhop's parser must classify lines and report, not skip. [better-than-training]

## Q1 When a file has front matter

Pick: a block is front matter only when all four hold.
1. After one optional leading BOM (Q3), the first line is exactly `---` plus optional trailing spaces/tabs. A leading blank line or any leading spaces means no front matter, ever.
2. A closing line of the same shape exists within the next 64 lines.
3. Every line between is front-matter-shaped: blank, a `#` comment, a key line (`[A-Za-z][A-Za-z0-9_-]*:` followed by a space or end of line), a `- item` list line belonging to a preceding empty-value key, or an indented continuation of the previous key. One prose line, heading, fence line, or stray list item disqualifies the whole block.
4. At least one known key (`title`, `description`, `tags`, exact lowercase) is present.

Anything failing 1–4 is entirely body. No closing line within 64 lines: whole file is body; an error is shown only when the opening lines contain a known-key line ("looks like front matter, missing closing `---`, treated as body"), so a plain thematic break stays silent. An empty `---`/`---` pair fails rule 4 and is body. The documented author escape for a body that must start with `---` is a leading blank line.
Reason: position + closing + shape + one known key is the smallest rule that distinguishes the three real cases: thematic break then prose (fails 3), a YAML example using foreign keys (fails 4), and actual varhop metadata. Validity-gating is the Jekyll principle, narrowed to varhop's subset. The 64-line cap bounds the damage if a body made only of `key: value`-shaped lines ever met a later `---`.
Cost: a file with only unknown keys in its header shows that header in the prompt body. That failure is visible and lossless, the opposite of a silent swallow, and unknown-only headers do nothing in v1 anyway. A prompt whose body deliberately teaches front matter using `title:` will still be read as front matter; that case is indistinguishable in principle, and the blank-line escape covers it.

Rejected:
- First line `---` plus next `---` anywhere is front matter (naive delimiter scan). Reason: swallows everything between two thematic breaks in a long prompt, the C2 F4 failure in its purest form.
- No known-key requirement (any subset-shaped block counts). Reason: a body opening with a YAML config example (`---\nhost: x\nport: 9\n---`) becomes invisible metadata. Empty Jekyll-style front matter has no varhop meaning, so requiring a known key costs nothing real.
- Accept `...` or `--- # comment` as delimiters. Reason: more shapes, more body collisions; no author need stated.

## Q2 The accepted subset

Pick: a line grammar, parsed in one pass, with three outcomes per known key: parsed, ignored-with-error, or block-disqualifying (only the non-shaped lines in Q1 rule 3 disqualify).
- `title` / `description`: one single-line scalar. Plain: rest of line after `key: `, trimmed; an inline comment starts at a space followed by `#`; a value containing `: ` (colon-space) is unsupported (quote it). Empty, `~`, `null` mean absent. Single-quoted: `''` escapes a quote, must close on the line. Double-quoted: only `\\`, `\"`, `\n`, `\r`, `\t`, `\uXXXX` escapes; any other escape is unsupported. Trailing content after a closing quote other than spaces/comment is unsupported. Numbers and booleans are kept as their raw text.
- `tags`: a block list (`tags:` then `- item` lines, indented or indentless), an inline flow list `[a, "b c", d]` parsed quote-aware, or one plain/quoted scalar meaning a single tag. Items follow the same scalar rules. Duplicates are dropped keeping first order.
- Unsupported-but-YAML-shaped constructs (block scalars `|`/`>`, flow maps `{...}`, anchors/tags starting `&`/`*`/`!`, nested indented maps, multiline quotes, indented continuations): the block can still be front matter; the affected known key is ignored and one error names it (for example "description uses unsupported YAML, ignored"). Unknown keys with any of these are ignored silently, per repo-format's unknown-keys rule.
- Duplicate known key: first value wins, second is an error. Wrong-case `Title:` is an unknown key.
Reason: every construct either parses with the same result YAML would give, or produces a visible error. Nothing is approximated silently, which is the actual C2 F4 hazard; a full YAML engine would also satisfy this but gray-matter's answer is bundling js-yaml, a large dependency and update burden to read three scalar fields, with anchor/alias surface varhop does not need. Spawning ruby/python per file is a runtime dependency and a process per prompt for the same three fields.
Cost: authors used to real YAML must write the subset: quote titles containing `: `, keep descriptions to one line, no block scalars. The error messages are where they learn it, and the repo template/docs should show the three shapes once.

Rejected:
- "Value is the rest of the line" with no comment or colon rules (Color.qml-style permissiveness). Reason: `title: Foo # draft` silently becomes part of the title and `title: A: B` silently succeeds where YAML fails; both are silent misreads of valid-looking files.
- Comma-splitting a plain `tags: a, b`. Reason: YAML reads that as one scalar. Keeping it one tag matches YAML; the bracket and block forms are unambiguous.
- All-or-nothing: one unsupported key makes the whole file body. Reason: punishes a multiline description by also discarding a good title and dumping the header into the copied prompt, when ignoring that key with an error keeps the body clean.

## Q3 Which bytes are the body

Pick: the stored source is the file text as decoded at import, minus one leading U+FEFF when present (variable-editing's import rule). If no front matter is recognized, the body is that whole string. If front matter is recognized, the body is the exact substring starting immediately after the closing delimiter line's line break. Nothing is trimmed: a blank line after the close is the body's first line, closing line as the last line means an empty body, and the presence or absence of a final newline is preserved. Line scanning for delimiters recognizes LF, CRLF, and CR breaks, but the body is sliced by character offset from the original string, never split-and-rejoined, so CRLF bodies keep CRLF and a CRLF-closed header over an LF body (and vice versa) survives intact.
Reason: offset slicing is the only rule under which "copied verbatim" (repo-format Taken) and variable-editing's source-segment rebuild stay true; any normalization here silently rewrites prompts the sync fork already went to lengths to fetch byte-identical. The newline after the closing `---` belongs to the delimiter line, not the body; everything after it is the author's.
Cost: authors who habitually blank-line after front matter get a leading blank line in every copy. That is visible in the editor, consistent, and theirs to remove in the repo.

Rejected:
- Trim one leading blank line / leading whitespace from the body. Reason: a special case that makes "verbatim" mean "verbatim except at the start"; prompts that intentionally begin with a blank line lose it.
- Normalize the whole file to LF at import. Reason: contradicts the CRLF fixtures locked in sync-and-auth and variable-editing for zero gain, since the scanner handles mixed breaks by offset anyway.

## Pitfalls, as fixtures the leaf must pass

- P1 `---\nSome intro prose.\n---\nRest` → all body, no error (rule 3).
- P2 `---\nhost: example\nport: 9\n---\nBody` → all body, no error (rule 4).
- P3 `---\ntitle: "Email: follow up #2"\ntags:\n- cold\n- b2b\n---\nDear {{NAME}}` → title keeps colon and hash; body starts at `Dear`.
- P4 `---\ntitle: X` with no close in 64 lines → all body plus the missing-close error.
- P5 `---\ndescription: |\n  two\n  lines\ntitle: T\n---\nBody` → front matter, title `T`, description ignored with error, body `Body`.
- P6 BOM + CRLF header, body beginning with two blank lines and no final newline → body preserves both blank lines, its CRLF breaks, and the missing final newline.
- P7 `\n---\ntitle: X\n---\nBody` (leading blank line) → all body, copied verbatim including the first blank line. This is the documented escape hatch; it must be stated in the prompt-repo docs the chart ships, or the first author who needs it will debug it from scratch.
- P8 Invalid UTF-8 is already lossy-decoded before this parser sees the string (FileView text at import); this fork cannot detect or repair it. It inherits the sync fork's stance and should not pretend byte fidelity below the decode step.

## Questions the fork does not ask

- U1 Is 64 lines the right cap, or should the shape rules alone bound the scan (a disqualifying line stops candidacy anyway)? The cap only matters for a body made purely of key-shaped lines; if the operator finds any magic number suspect, dropping it loses little.
- U2 Should `description` grow a multiline form later (block scalar)? It is the one field authors will plausibly want paragraphs in, and it is also the field whose unsupported-use error they will hit first.
- U3 Do parse errors need line numbers ("line 3: description …") in the settings load-error list, or is file + key enough? Cheap to carry now (the parser knows), annoying to retrofit into the error model later.
