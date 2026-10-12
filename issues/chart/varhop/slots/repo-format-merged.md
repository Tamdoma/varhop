# repo-format merged notes (A merges A, B, C)

## Q1 Layout
- Fixed two folder levels `<category>/<subcategory>/<slug>.md` (A,C); subcategory optional so `<category>/<slug>.md` also loads (C). Any depth >=1 (B). Cost of fixed: no third level; cost of any depth: UI has no fixed place for the breadcrumb (C), forced filler subcategories otherwise (B).
- Content root: `prompts/` folder at repo root (A,B) vs repo root with optional `root:` key (C). Reason for `prompts/`: README/docs never become prompts (A,B).
- Pitfalls: README imported as a prompt (removed by reserved root or root-level ignore); path is the prompt id, same slug in two categories allowed (A,B,C); symlinks/path escape rejected (B).
- Asked by all: what does the operator's real Notion/prompt set look like (count, depth) (A,B,C).

## Q2 Metadata
- YAML front matter between `---` lines, all fields optional: title (default from filename), description, tags (A,C); C adds aliases and `vars`. Hand-written JS subset parser (A,C; precedent /usr/share/omarchy/shell/Commons/Color.qml:184-205 hand-rolled TOML subset). Cost: ~60 lines of parser, no full YAML (anchors, block scalars rejected with an error row).
- Sidecar `<slug>.meta.json` parsed with JSON.parse, body stays pure text (B). Reason: QML has no YAML library, so YAML means a hand-written parser; sidecar costs two files per prompt and paired renames. B withdrew its earlier front-matter preference after the QML/JS lock.
- Pitfalls: `---` horizontal rule in a body mistaken for front matter (front matter only when line 1 is exactly `---`) (C); CRLF/BOM from exports stripped before parsing (C); typo'd metadata keys: report, do not silently drop (B,C).

## Q3 Variables
- Token `{{NAME}}`, escape `\{{NAME}}` for literal (A,B,C). Anything that is not a valid token stays literal (A,C); B instead errors on an invalid unescaped `{{`.
- Name rule: letters/digits/underscore any case (A,B, B case-sensitive) vs uppercase only `[A-Z][A-Z0-9_]*` (C). C's reason: uppercase-only means lowercase Jinja/Mustache examples inside prompts need no escape. A conceded toward C in this merge.
- Repeated name = one shared value, Tab order = first appearance (A,B,C). Values inserted literally, never re-parsed (B,C).
- Defaults/hints: none in v1 (A) vs front matter `vars` / `variables[]` with default and hint (B,C). Inline `{{NAME|default}}` rejected (A,B,C).

## Q4 Marker
- None in v1; the `prompts/` folder is the marker (A). Required `varhop.json` {"schemaVersion":1} (B, strict). Optional `varhop.yaml` with `format` and `root` (C). Cost of none: a future v2 detects v1 by absence.

## Strictness (not a fork question yet)
- Lenient load with a per-file error list in settings, bad file still shows with defaults (A,C). Strict, whole new revision rejected if any file is invalid (B). Cost of strict: one bad edit holds the whole update.

## Operator-owned
Fixed depth vs any; YAML front matter vs JSON sidecar; variable name case; defaults yes/no; strictness; what the real prompts look like.
