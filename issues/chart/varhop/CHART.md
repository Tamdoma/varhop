# Chart: varhop

## Destination
Pressing a custom hotkey shows a themed search overlay over everything. Typing suggests prompts from a connected GitHub prompt repo. Opening one lets Tab/Shift+Tab jump through `{{VARIABLE}}` tokens, and Ctrl+C copies the finished prompt and closes. The overlay can be hidden mid-edit and resumed. Replaces Notion for prompts.

Route: lifecycle, debate no (handoff review 2026-10-13, operator `1a | 2a | 3a | 4a`)

## Forks taken
- [form-factor](forks/form-factor.md): Omarchy shell overlay plugin, `omarchy plugin add`/`update`; no standalone Qt app, no mise.
- [repo-format](forks/repo-format.md): `prompts/<category>/[<subcategory>/]<name>.md`, optional front matter (title, description, tags), uppercase `{{NAME}}`, `\{{` escape, no defaults, bodies copied verbatim.
- [sync-and-auth](forks/sync-and-auth.md): reuse `gh` login, shallow clone in ~/.cache/varhop with two slots swapped on success, manual pull only (Ctrl+R / Sync now), one repo, old library kept until a new one imports, account/repo ids checked.
- [variable-editing](forks/variable-editing.md): values only, one Tab stop per unique name with mirrors and wrap, Enter is newline, Delete empties then restores `{{NAME}}`, resume keeps cursor, copy rebuilt from source, `{{[A-Z0-9_]+}}`.
- [copy-and-close](forks/copy-and-close.md): Ctrl+C (and Super+C) copies the whole rebuilt prompt via wl-copy stdin and closes on success, no auto-paste, unset copied as `{{NAME}}`, editor Esc hides with draft kept, search Esc clears then hides, draft in memory only.
- [search](forks/search.md): scored subsequence over title, file name, tags, category, description, body substring last; č/đ folding; copy-frecency after relevance; empty query = 10 recent then all by category; pinned Resume draft.
- [settings-and-hotkey](forks/settings-and-hotkey.md): user pastes `o.bind("SUPER + ALT + P", …, { panel = "ivan.varhop" })` with a live conflict check, settings view in the overlay (Ctrl+,), Ctrl+P find / Ctrl+Shift+P resume / Ctrl+R pull, no auto cleanup, disable wipes selection, repo switch discards draft after warning.
- [front-matter](forks/front-matter.md): line-1 `---` to next `---` is the header (empty header escapes), YAML-style subset for title/description/tags, bad key ignored with line error, body sliced verbatim, BOM stripped, invalid UTF-8 errors.

## Open forks
- None.

## Fog
- Exact animation set (open, selection move, close) beyond "subtle, through Style.duration": left to leaf design, not material.

## Off route
- Importing or converting Notion prompts: operator builds a new repo (repo-format Q5).
- Authoring or migrating prompts from Notion into the repo (not requested).

## Pending steps
- Done 2026-10-13: third-party overlay proof (summon/hide/toggle by its own id, typing focus, physical Super+Alt+P bind, draft kept across hide, clean removal) in [proofs-overlay.md](proofs-overlay.md).
- Done 2026-10-13: GitHub sync and wl-copy proofs against the retained private `Tamdoma/varhop-prompts` in [proofs-sync.md](proofs-sync.md).
- Split agreed: L1 core logic and L2 GitHub sync in parallel, then L3 overlay.
- Done 2026-10-13: varhop registered with akrogon. The test check passes on an empty tree.
- Done 2026-10-13: handoff draft review by B and C, with fixes applied. Git install and update, Super+C/V key-state route, shell restart loading new code, and component test runner proofs are in [proofs-overlay.md](proofs-overlay.md) Proofs 2-4. gh status is S8-S9 in [proofs-sync.md](proofs-sync.md).
- Operator check after the overlay-plugin merge (operator 4a): middle-click paste, dead-key letter and IME preedit, with steps in the overlay-plugin design. Owner: operator. Pending until that leaf merges.

Handed off 2026-10-13
