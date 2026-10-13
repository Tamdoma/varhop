# picker

## Question
Q1. How does the repo picker filter as you type, and what does Enter select (F1)?

### Carries
- Merged map: slots/map-merged.md
- Disposal fork: forks/disposal.md
- Operator F1 (INTAKE.md:24): typing in the `owner/repo` field does not filter the list. Only an exact typed `owner/repo` plus Enter, or a click, selects.
- Proof-bar Taken: every control works by Tab+Enter. Tamdoma/varhop-prompts-b is the read-only second repo, and the run ends switched back to Tamdoma/varhop-prompts.
- Look Taken: menu tokens, menu.selected* for selection, Style.font tokens.
- Editor Taken: single text box. Its Tab cycle is unchanged.

## Findings
Merged notes: slots/picker-merged.md (rebuttals slots/picker-rebuttal-B.md, slots/picker-rebuttal-C.md).
- better-than-training · `gh api '/user/repos?per_page=100' --paginate`, 2026-10-13 (C) · 161 repos across many owners. The alphabetical first is apphutdev/aiva.
- better-than-training · GitHub REST "List repositories for the authenticated user", 2026-10-13 (B,C) · owned, collaborator and org repos, default sort full_name. Not every accessible repo, so the typed lookup stays.
- practitioner · Omarchy maintainers' EmojiSearch.js, Emojis.qml:76-102,208-221, Menu.qml:1251-1266, Clipboard.qml:366-386 (B,C) · substring filter, selection resets to top on filter change, arrows wrap, Return activates the selection, rows are not focusable.
- practitioner · VS Code Quick Picks UX guidelines, fzf manual (B,C) · ranked fuzzy suits large unknown-name sets. Declined for 161 known names.
- better-than-training · worktree SettingsBody.qml:188-234, Varhop.qml:308,328-338,583-601,900-910 (A,B,C) · unfiltered Repeater, Enter sends raw text, chosen vs typed paths, draft-discard warning, silent empty list on failure.

## Taken
Operator 2026-10-13: `1a | 2a | 3a | 4a`.
- 1a: case- and accent-insensitive literal substring of the trimmed field on fullName. A to Z by lowercased fullName, never reordered by the query. After each text change, the highlight goes to the exact listed match if any, else the first match.
- 2a: no highlight until the operator types or presses an arrow. Enter on an empty field does nothing.
- 3a: with zero matches, a line says Enter looks up `owner/repo`. Enter runs the existing validated lookup (repoRe plus `varhop-sync repo`). The result applies only if the field still holds the submitted text. No synthetic lookup row.
- 4a: the picker is one keyboard control. Tab reaches the field, Up and Down (wrapping) and Enter reach every row, and a click uses the same `repoChosen` path. This amends proof-bar Q4 for list rows only.
- Binding (agreed, not asked):
  - a bounded ListView about 8 rows with the highlight kept in view
  - distinct loading, could-not-list and no-match lines, with the failure state taken from reposProc's exit, not list length
  - after a background refresh the highlight follows the repo ID, or clears if the repo is gone
  - a "current" marker on the selected repo
  - Esc clears a non-empty filter first
