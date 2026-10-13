# Varhop

A prompt picker for Omarchy. Press a hotkey, search your prompt library, fill in
the blanks right inside the prompt text, and copy the finished prompt to the
clipboard.

Your prompts live as Markdown files in a GitHub repository. Varhop pulls them
with your `gh` login, so private repositories work too. The overlay uses your
Omarchy theme colors and fonts.

## Requirements

- Omarchy with the Omarchy shell
- GitHub CLI (`gh`), logged in with `gh auth login`
- `git` and `wl-clipboard` (`wl-copy`)

## Install

```bash
git clone https://github.com/Tamdoma/varhop.git
omarchy plugin add file://$PWD/varhop --enable --yes
```

Add a hotkey by pasting this line into `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + ALT + P", "Varhop prompts", { panel = "ivan.varhop" })
```

Check first that the chord is free with `hyprctl binds -j`. Settings can also
build this line for any chord you type (see [Settings](#settings)).

Without a hotkey, open it with `omarchy-shell shell summon ivan.varhop`.

## First run

1. Open Varhop. With no repository chosen yet, it opens at settings.
2. Pick a repository from the list, or type `owner/repo` and press Enter.
3. Varhop downloads the prompts and shows the search.

To try it out, use the starter library `Tamdoma/varhop-prompts`.

## Using it

1. **Search.** Type to filter. Results match title, file name, tags, category
   and description. Prompts you use often rank higher. With an empty search,
   your 10 most recent prompts come first.
2. **Open.** Use Up and Down to choose, then press Enter.
3. **Fill in.** The whole prompt shows as one block of text. Each `{{NAME}}` is
   a blank you fill in place. The current blank is selected, so just type.
   Tab and Shift+Tab move between blanks. A blank used several times updates
   everywhere at once. The rest of the prompt text is locked so you can't
   change it by accident.
4. **Copy.** Press Ctrl+C. Varhop copies the finished prompt and closes. Paste
   it wherever you need it. A prompt with no blanks copies as soon as you open
   it.

The counter at the bottom right shows how many blanks are still unfilled.

### Drafts

If you close Varhop before copying, your half-filled prompt is kept as a draft.
Press Ctrl+Shift+P in search or settings to get back to it. Drafts last until
the shell restarts.

### Getting around

The header has a **Back** button and a **Settings** button. Ctrl+P goes back
from the editor to your search, and keeps your draft. Ctrl+, opens and closes
settings. Esc goes back one step or closes Varhop.

## Keys

| Key | Action |
|---|---|
| Type | Filter prompts |
| Up / Down | Move the selection |
| Enter | Open the selected prompt |
| Tab / Shift+Tab | Next / previous blank |
| Delete on a filled blank | Empty it. Press again to restore `{{NAME}}` |
| Ctrl+Z / Ctrl+Y | Undo / redo changes to the current blank |
| Ctrl+C (editor) | Copy the finished prompt and close |
| Ctrl+C (text fields) | Copy the selected text |
| Ctrl+V | Paste |
| Ctrl+P (editor) | Back to search, keeping the draft |
| Ctrl+Shift+P | Resume the draft (from search or settings) |
| Ctrl+R | Pull the latest prompts from GitHub |
| Ctrl+, | Open or close settings |
| Ctrl+Tab | Move focus between the page and the header buttons |
| Esc | Clear the search, go back, or close |

## Settings

Open with Ctrl+, or the Settings button.

- **GitHub**: shows the account you're logged in as. If you're not logged in,
  it shows the command to fix it.
- **Repository**: filter your repositories or type `owner/repo`. Switching
  repositories discards the current draft, and Varhop warns you first.
- **Sync now**: pulls the latest prompts. Shows when the last pull happened.
  Varhop doesn't sync on its own, so pull after you change your prompts on
  GitHub (Ctrl+R does the same).
- **Load errors**: lists prompt files that couldn't be read, and why.
- **Hotkey**: type a chord and Varhop builds the `bindings.lua` line for you to
  copy.
- **Reset usage**: clears the "used often" ranking for this repository.

## Writing prompts

Put each prompt in its own Markdown file:

```
prompts/<category>/<name>.md
prompts/<category>/<subcategory>/<name>.md
```

A prompt file looks like this:

```markdown
---
title: Code review
description: Review a diff for bugs
tags: [review, code]
---
Review this {{LANGUAGE}} change for bugs. Focus on {{FOCUS}}.

Explain each {{LANGUAGE}} issue in one sentence.
```

- The front matter is optional. Only `title`, `description` and `tags` are
  used. Without a title, the file name is used.
- Blanks are `{{NAME}}` using capital letters, digits and `_`.
- To show a literal `{{`, write `\{{`.
- Everything else is copied exactly as written.

## Update

```bash
omarchy plugin update ivan.varhop --yes
omarchy-restart-shell
```

The restart is needed. The running shell keeps the old version until then.

## Uninstall

```bash
omarchy plugin remove ivan.varhop --yes
```

Then delete these by hand:

- the `o.bind` line in `~/.config/hypr/bindings.lua`
- `~/.cache/varhop` (downloaded prompts)
- `~/.local/state/varhop` (usage history)
