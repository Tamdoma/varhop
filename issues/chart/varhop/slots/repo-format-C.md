# repo-format: blind notes (slot C)

Read 2026-10-12. Tiers: [OP] operator, [SRC] inspected file or primary doc with path/URL, [MK] own knowledge (searches named).

## Q1 Folder layout

Pick: fixed depth. `<category>/<subcategory>/<slug>.md` or `<category>/<slug>.md`. Category = first folder, subcategory = second folder or none. Any `.md` three or more folders deep is loaded and listed with an error row, not silently dropped or silently flattened. Root-level `.md` files (README, LICENSE) and dotfolders are not prompts. Prompt id = repo-relative path. Reason: the operator asked for one categories/subcategories architecture across repos [OP INTAKE.md "Details and UI"]; two fixed levels give the UI a stable shape (category chip, subcategory label) and the loader a one-line rule. Cost: a repo that wants a third level has to flatten; a team repo cannot nest by owner.

Rejected:
- Any depth, folder path = breadcrumb. Reason: UI has no fixed place to show it and search weighting of "category" becomes undefined. Shinkuro-style loaders do this but they have no category UI (glama.ai Shinkuro README, read 2026-10-12).
- Fabric style, folder per prompt with `system.md` inside (github.com/danielmiessler/fabric/tree/main/data/patterns/analyze_claims holds `system.md` + `user.md`, read 2026-10-12). Reason: one prompt per file is what Notion-to-repo migration naturally produces; folder-per-prompt doubles the tree for no gain here.
- `prompts/` subfolder as root (VS Code uses `.github/prompts`, Codex `~/.codex/prompts` top level only). Reason: adds a knob; a repo dedicated to prompts can use its root. Keep as an optional `root:` key in the marker file (Q4) so a mixed repo still works.

## Q2 File contents beyond the prompt

Pick: optional YAML-looking front matter between `---` lines at the very top, body = literal prompt text. Fields, all optional: `title` (default: slug with `-`/`_` to spaces, Title Case), `description`, `tags` (inline `[a, b]` or `- a` list), `aliases` (extra search terms), `vars` (map NAME → `default`, `hint`). Parsed by a hand-written flat+one-level parser in JS (strings, numbers, inline lists, one nested map), the same approach the shell already takes for TOML in /usr/share/omarchy/shell/Commons/Color.qml:184-205 (`parseShell`: line regexes, no library). Reason: every surveyed prompt-file format uses YAML front matter + body (VS Code `.prompt.md`: description/name/argument-hint, code.visualstudio.com/docs/copilot/customization/prompt-files; dotprompt: `---` YAML with `input.schema`/`input.default`, google.github.io/dotprompt/reference/frontmatter; Hugo accepts `---` YAML, `+++` TOML, `{}` JSON, gohugo.io/content-management/front-matter; all read 2026-10-12). Authors already know it. Cost: ~60 lines of parser and its node-free tests (QML/JS only, no node in the plugin: /home/ivan/.claude/skills/omarchy/plugins.md:6-7). No full YAML: anchors, multi-line scalars, nested lists are rejected with an error row.

Rejected:
- JSON front matter (`JSON.parse`, zero parser). Reason: humans editing prompts in an editor; quoting and commas are the thing Notion users will get wrong; Raycast's import JSON (`name`,`text`,`keyword`, manual.raycast.com/snippets) is an export format, not an authoring one.
- Full YAML via a bundled js-yaml (present only in ~/.bun cache, not in Qt's JS engine as a module). Reason: QML's JS has no `require`; vendoring 1000+ lines for three fields.
- Metadata in filename only (Fabric, Obsidian templates). Reason: no description/tags for search; Obsidian templates (obsidian.md/help/plugins/templates) carry no metadata at all.
- Body inside a code fence (Lullabot prompt library convention, found via search). Reason: extra ceremony; fences in a prompt body are also legitimate content.

## Q3 Variables, literal braces, defaults

Pick: a variable is exactly `{{NAME}}` with `NAME` matching `[A-Z][A-Z0-9_]*`, optional spaces inside the braces. Anything else between `{{ }}` is literal text and never a variable, so most `{{` collisions (Mustache sections, lowercase Jinja/Handlebars examples inside a prompt about templating) need no escape at all. Literal uppercase form: `\{{NAME}}` renders `{{NAME}}`. Same NAME repeated = one shared value, Tab order = first appearance. Defaults and hints live only in front matter `vars`, no inline syntax. Variables are substituted in the body only, not in front matter. Reason: the operator fixed the syntax and casing [OP "{{VARIABLE}}"]; uppercase-only makes the token set unambiguous; Mustache itself has no escape and relies on delimiter switching (mustache.github.io/mustache.5.html Set Delimiter, read 2026-10-12), which is worse for a copy tool. Defaults in front matter follows dotprompt `input.default` and Espanso `vars:` (espanso.org/docs/matches/basics, read 2026-10-12). Cost: a prompt whose variable names are lowercase in Notion must be upper-cased when migrated; one regex, one escape rule to document.

Rejected:
- Inline default `{{NAME|default}}` or Raycast-style `{argument name="x" default="y"}`. Reason: adds a grammar to the body, the thing the user reads and copies; a default that is long breaks the prompt's readability.
- VS Code `${input:name:placeholder}`. Reason: contradicts the operator's syntax.
- Any-case names `[A-Za-z_]\w*`. Reason: turns `{{#if}}`-adjacent and lowercase examples into false variables and forces escapes everywhere.

## Q4 Version marker / manifest

Pick: optional `varhop.yaml` at the repo root with `format: 1` and optional `root: <folder>`. Absent file = format 1, root = repo root. A `format` higher than the plugin supports is one error shown at the top of the list, prompts still load best-effort. No per-prompt index file. Reason: the only job of a marker is to let a future format bump be detected and to let a mixed repo point at its prompt folder; both cost one small file and no API call. The tree itself is the index; a generated INDEX.md (Smart Prompts MCP convention) drifts from the files. Cost: one more rule to document.

Rejected:
- Mandatory manifest listing prompts. Reason: every new prompt needs two edits; merge conflicts in a team; dropped files vanish silently when the index is stale.
- No marker at all (my earlier map position). Reason: changed; the `root:` key is the cheapest way to support a repo that also holds notes, and a format bump with no marker means guessing.

## Loader strictness

Pick: lenient load, loud report. Every `.md` with non-empty body in depth 1-2 becomes a prompt; bad front matter → defaults plus an error row; depth ≥3, empty body, unknown `format` → error rows. Errors are visible in the settings view and as a count in the overlay footer. Reason: the operator authors alone today and loses time to Notion; a strict loader that hides a prompt over a stray colon recreates the pain. A team would add a CI validator in the repo, not a stricter client. Cost: the same malformed file nags until fixed.

## Evidence

- [OP] INTAKE.md: `{{VARIABLE}}`, Tab/Shift+Tab select braces too, "same categories and subcategories architecture", settings pick one repo.
- [SRC] forks/form-factor.md Taken: plugin in QML/JS; no node/Python in-process.
- [SRC] /usr/share/omarchy/shell/Commons/Color.qml:184-205: hand-rolled TOML subset parser in QML JS, precedent for a hand-rolled front matter parser.
- [SRC] /usr/share/omarchy/shell/plugins/image-picker/ImagePicker.qml:329-331: `Process { command: [...] }` to list rows from a shell command; precedent for `git -C <clone> ls-files -z -- '*.md'` to enumerate prompt files, then `FileView` per file.
- [SRC] /usr/lib/qt6/qml/Qt/labs/folderlistmodel present as an alternative enumerator; Quickshell.Io ships FileView only.
- [SRC] VS Code prompt files, code.visualstudio.com/docs/copilot/customization/prompt-files, 2026-10-12: `.prompt.md`, optional YAML header, `${input:name:placeholder}`, no escape documented.
- [SRC] dotprompt, google.github.io/dotprompt/reference/frontmatter, 2026-10-12: `---` YAML, `name` inferred from filename, `input.schema`, `input.default`.
- [SRC] Hugo, gohugo.io/content-management/front-matter, 2026-10-12: `---`/`+++`/`{}` delimiters.
- [SRC] Espanso, espanso.org/docs/matches/basics, 2026-10-12: YAML matches, `{{name}}` in `replace`, `vars:` list with `name/type/params`, no `{{` escape documented.
- [SRC] Raycast, manual.raycast.com/snippets, 2026-10-12: inline `{cursor}`, `{date}`, `{clipboard}`; import JSON `name/text/keyword`.
- [SRC] Alfred, alfredapp.com/help/features/clipboard/dynamic-placeholders, 2026-10-12 (search result): `{clipboard}`, `{cursor}`, `{date +7d}`.
- [SRC] Mustache, mustache.github.io/mustache.5.html, 2026-10-12: no escape, Set Delimiter only.
- [SRC] Obsidian templates, obsidian.md/help/plugins/templates, 2026-10-12: `{{title}}`, `{{date:FORMAT}}`, no escape or metadata.
- [SRC] Fabric, github.com/danielmiessler/fabric/tree/main/data/patterns/analyze_claims, 2026-10-12: folder per pattern with `system.md` + `user.md`; `{{input}}` variable syntax is [MK], the patterns README fetch returned 404.
- [MK] One web search ("prompt library repository markdown front matter ...") surfaced Shinkuro, Smart Prompts MCP, Lullabot library; conventions: category folders, YAML front matter, optional INDEX.md.

## Pitfalls and what removes each

- P1 `---` as a Markdown rule inside a body mistaken for front matter. Remove: front matter only when line 1 is exactly `---`; closing `---` is the next such line; everything after is body verbatim.
- P2 CRLF or BOM from a Windows or Notion export breaks the regexes. Remove: strip BOM and `\r` before parsing; test fixture with both.
- P3 Tabs vs spaces in the nested `vars` map. Remove: indentation = any leading whitespace; nesting by "more than the parent" rule only.
- P4 Typing over a token destroys the marker. Remove: template + values model (carried from the merged map), tokens computed once from the original body.
- P5 `{{NAME}}` inside a code fence in the body. Remove: by design it is still a variable; document it; the uppercase rule already excludes most code examples.
- P6 Same slug in two categories. Remove: id is the path, title may repeat; search shows the category label.
- P7 Variable named in `vars` but absent from the body, or present in body but absent from `vars`. Remove: `vars` is advisory; body wins; mismatch is an error row, never a load failure.
- P8 A future `format: 2` repo opened by an old plugin. Remove: the one-line top error plus best-effort load, so the user still gets prompts.
- P9 Non-UTF-8 file. Remove: FileView text() decode as UTF-8; replacement characters are shown, file flagged.
- P10 Hundreds of FileView loads on open. Remove: load once per sync into an in-memory index (JSON cache under `~/.cache/varhop/`), the overlay never reads the tree on summon.

## Questions the fork does not ask

- Q5 Does Ctrl+C copy the body only, or title plus body? Affects whether `title` is metadata or content.
- Q6 What do the operator's Notion prompts look like today: count, whether pages hold several prompts, whether they already have descriptions. Decides how much front matter the first repo needs and whether a one-off export script is worth adding to the standard's README.
- Q7 Is a subcategory required or optional? My pick says optional; a team might want it required.
- Q8 One repo or several? Front matter and layout are the same either way, but the id scheme (`repo/path`) changes if several.
- Q9 Should the standard ship as a template repo (README, `varhop.yaml`, two example prompts) that `gh repo create --template` can clone? Cheap and makes "the standard" concrete for anyone else.
