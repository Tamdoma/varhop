# Prompt repo format

## Question
Q1. What folder layout does a prompt repo follow (fixed category/subcategory depth or any depth, where prompts live)?
Q2. What does a prompt file contain beyond the prompt text (front matter fields)?
Q3. What counts as a `{{VARIABLE}}`, how is a literal `{{` written, and can a variable carry a default or hint?
Q4. Does the repo carry a version marker or manifest file?

### Carries
- form-factor taken: Omarchy shell overlay plugin (forks/form-factor.md). Parsing runs in QML/JS inside the plugin.
- Operator: `{{VARIABLE}}` syntax; "every repo has to have a standard ... same categories and subcategories architecture" (INTAKE.md).
- Merged map slots/map-merged.md agreed: `<category>/<subcategory>/<slug>.md`, folder = category, optional YAML front matter, `\{{NAME}}` escape, Tab order from the original template.
- Open from the map: depth cap (C: 2), versioned root manifest (B), variable defaults/descriptions in front matter (B, C).

## Findings
Independent notes: slots/repo-format-A.md, -B.md, -C.md. Merged: slots/repo-format-merged.md. Rebuttals: slots/repo-format-rebuttal-B.md, -C.md.
- Evidence (A): VS Code prompt files use optional YAML front matter, `name` defaults to the file name (https://code.visualstudio.com/docs/copilot/customization/prompt-files, read 2026-10-12). Fabric: one folder per pattern, `system.md` (read 2026-10-12). No practitioner write-up on prompt-library repo layout found by any slot. Omarchy hand-parses TOML for user data in /usr/share/omarchy/shell/Commons/Color.qml:184-205 (strict at install, lenient at runtime: omarchy-plugin-add:125 vs Menu.qml:979-983).
- Agreed (A,C): two fixed levels, front matter, uppercase-friendly escape `\{{NAME}}`, lenient load with visible per-file errors. B differs: any depth, JSON sidecar, any-case names, required `varhop.json`, strict whole-revision rejection. C: optional `varhop.yaml` (format, root), reserved `vars` key. A: no marker; unknown front-matter keys ignored so later additions break nothing.
- Settled by all slots, not operator questions: root-level files and README never prompts; prompt id = path; values inserted literally; repeated names share a value (traversal order belongs to variable-editing); invalid `{{...}}` stays literal text (A,C; B would error).
- Remaining disagreement: B wants a version marker decided now; A,C see none/optional. B notes a body opening with `---` is read as front matter (authors start the body with a blank line).

## Taken

2026-10-12 operator: `| 1a | 2a | 3a | 4a |` (Q5, what the Notion prompts look like, not answered).
Taken so far: Q1 `prompts/<category>/<subcategory>/<name>.md`, subcategory optional, deeper files shown with an error note, README outside `prompts/` ignored, no version file in v1 (foreclosed: any depth). Q2 YAML-lines front matter in the same file, optional `title` (default file name), `description`, `tags`, unknown keys ignored, broken front matter still loads with an error shown (foreclosed: JSON sidecar, no metadata). Q3 uppercase-only `{{NAME}}` (A-Z, 0-9, underscore), anything else in braces is literal, `\{{NAME}}` for literal (foreclosed: any case). Q4 no defaults or hints in v1; unknown keys ignored so they can be added later (foreclosed: `vars` now).

2026-10-12 operator, Q5: `it doesn't matter, I will adapt them to the new version. I'll create a new repo from scratch. The only requirement is that they're in markdown format, and they can contain and types of spaces and signs, paragraphs, etc.`
Taken: Q1-Q4 as recorded above. Q5: no migration or import tool; the operator builds a new repo to this format. Binding: prompt bodies are arbitrary Markdown and are copied verbatim (any whitespace, symbols, paragraphs); only `{{NAME}}` tokens and the `\{{` escape are interpreted.
