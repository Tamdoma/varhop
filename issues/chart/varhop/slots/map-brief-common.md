# Opening territory map brief (slots B and C)

You are an independent peer in a charting exchange for the project "varhop" (working dir /home/ivan/Work/omarchy-customizations/varhop, a fresh repo containing only a README). Do NOT read the other peer's map or slot A's map. Do not write code and do not modify anything except your return file.

## Task
Produce an independent opening territory map of this work: the material forks (decisions that change the outcome), questions an experienced practitioner would ask, and pitfalls over the work's whole lifetime (what each option could break or invite later, not only now). Proportional to the work, not exhaustive. Mark which fork to settle first (the one whose answer reshapes the most other forks).

Intake (operator's verbatim request): /tmp/claude-1000/-home-ivan-Work-omarchy-customizations-varhop/65e222a2-93a4-41fa-aaad-8274a18132be/scratchpad/map/intake.md

## Live surface to inspect (read, do not guess)
- Omarchy app-building guide: /home/ivan/.claude/skills/omarchy-app/SKILL.md and /home/ivan/.claude/skills/omarchy-app/templates.md (C++/Qt Quick, qmake6, PKGBUILD, Theme class watching ~/.local/state/omarchy/current/theme/colors.toml)
- Omarchy skill: /home/ivan/.claude/skills/omarchy/SKILL.md, hyprland.md (keybindings via ~/.config/hypr/bindings.lua, window rules), plugins.md (Omarchy shell is Quickshell; plugins under ~/.config/omarchy/plugins), theming.md
- Installed Omarchy apps for comparison: hype, monologue, omacut (pacman -Ql <pkg>; upstream repos under github omacom-io / omacom). Omarchy sources: /usr/share/omarchy (read only), e.g. /usr/share/omarchy/default/hypr/apps/*.lua for window/layer rules, /usr/share/omarchy/shell for the Quickshell shell and its launcher/menu.
- Live theme: ~/.local/state/omarchy/current/theme/colors.toml
- Tools present: wl-copy, wtype (no ydotool). gh CLI is installed (check 'gh auth status').

## Things the map must at least consider (add your own)
Form factor (standalone Qt/QML app vs Omarchy shell/Quickshell plugin vs other); how an always-ready instant popup is achieved (daemon/single-instance vs cold start, Hyprland window/layer rules, keybinding via bindings.lua); GitHub connection and auth (gh CLI token vs OAuth device flow vs deploy key, secret storage), repo sync and offline cache; the standard prompt repo format (categories/subcategories, front matter, variable syntax {{VARIABLE}}, defaults/descriptions, multi-line, escaping); search (fuzzy, ranking, fields searched); the variable-editing UX (Tab/Shift+Tab selection of {{VAR}} tokens, how editing works in an editor surface, same variable repeated in several places); Ctrl+C semantic (copy whole prompt vs copy selected text; closing); backgrounding while the user fetches values elsewhere (hide vs minimize, state kept, focus return); packaging and updates (Arch PKGBUILD, AUR, repo, mise, how updates arrive); theme inheritance and live updates; settings contents; animations per Omarchy conventions; tests; scope split into deliverable pieces and their real dependencies.

## Evidence rules
Use the highest evidence tier available and label each claim: operator material > named practitioner with track record > primary docs/source/inspected files (cite path:line or URL and date read) > own model knowledge (say which searches found nothing stronger). Cite inspected file paths.

## Return format (markdown, written to your return file)
1. Facts inspected (path:line / URL + date each, one line each)
2. Forks (F-codes), each: the question, options with cost, your pick and reason, tier of evidence
3. Practitioner questions / pitfalls (R-codes) with what removes each
4. Fog (material work whose question is not yet sharp)
5. Which fork first and why
Keep it compact and plain. Write the file, then stop.
