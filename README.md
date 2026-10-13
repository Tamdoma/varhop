# varhop

`ivan.varhop` — an Omarchy shell overlay plugin that searches prompts from a
GitHub prompt library, walks `{{NAME}}` placeholders with Tab, and copies the
finished prompt to the clipboard.

## Install

```bash
omarchy plugin add file://<local clone of this repo> --enable --yes
```

A hotkey is suggested, not installed. Paste one line into
`~/.config/hypr/bindings.lua` (free on this machine, 2026-10-13 — re-check
`hyprctl binds -j` before pasting):

```lua
o.bind("SUPER + ALT + P", "Varhop prompts", { panel = "ivan.varhop" })
```

Without a bind: `omarchy-shell shell summon ivan.varhop`.

## Update

```bash
omarchy plugin update ivan.varhop --yes
omarchy-restart-shell
```

New code reaches the running shell only after `omarchy-restart-shell`
(proofs-overlay.md row 14): the update moves the plugin checkout, the running
shell keeps executing what it loaded until restarted.

## Prompt repo format

`prompts/<category>/[<subcategory>/]<name>.md`. Optional `---` front matter
with `title`, `description`, `tags`; `{{NAME}}` variables (uppercase, digits,
underscore); `\{{` escapes a literal; bodies copy verbatim. The starter library
is `Tamdoma/varhop-prompts`, read-only through the `gh` login.

## First run

Summon with no repo selected → settings opens at the picker. Pick a repo or
type `owner/repo` and Enter. The selection lives in
`~/.config/omarchy/shell.json` under `plugins[]`; the library cache lives in
`~/.cache/varhop`; usage frecency lives in `~/.local/state/varhop/usage-<repoId>.json`.

## Keys

| Key | Action |
|---|---|
| Type | filter prompts |
| Up / Down | move selection (wraps) |
| Enter | open prompt in editor |
| Tab / Shift+Tab | next / previous `{{NAME}}` (wraps) |
| Delete on a value | empty it; again restores `{{NAME}}` |
| Ctrl+C / Ctrl+Shift+C (editor) | copy rebuilt prompt, end draft, hide |
| Ctrl+C / Ctrl+Shift+C (fields) | copy the field's text selection |
| Ctrl+V / Ctrl+Shift+V | paste |
| Ctrl+P (editor) | back to previous query and selection, draft kept |
| Ctrl+Shift+P | resume draft (search, settings) |
| Ctrl+R | pull the library (inert inside picker fields) |
| Ctrl+, | toggle settings; Esc returns to the view it came from |
| Esc | clear query → hide; in editor/settings, back or hide |

## Removal

```bash
omarchy plugin remove ivan.varhop --yes
```

Remove deletes the plugin folder and its `shell.json` entry. Leftovers to
delete by hand: the `o.bind` line in `~/.config/hypr/bindings.lua` (a no-op
after removal), `~/.cache/varhop`, `~/.local/state/varhop`.
