# Map A (opening)

## Facts inspected
- Omarchy's own instant search-and-copy popups are Quickshell overlay plugins: /usr/share/omarchy/shell/plugins/emojis/manifest.json (kinds overlay, keepLoaded true), clipboard/. Bound with `o.bind("SUPER + CTRL + E","Emojis",{panel="omarchy.emojis"})` /usr/share/omarchy/default/hypr/bindings/utilities.lua:3. (read 2026-10-12)
- Plugin theming: Emojis.qml uses Color.menu.* tokens, Style.*, so theme follows live with no code of our own (emojis/Emojis.qml:1-40).
- Layer rules for those overlays: no compositor animation, QML owns opacity/grow (default/hypr/apps/omarchy-shell.lua).
- Install/update path for third-party plugins: `omarchy plugin add <git-url>`, `update`, `remove`, `validate` (omarchy plugin --help). User plugins live in ~/.config/omarchy/plugins/<id>/ (exists: ivan.bar etc).
- Standalone app route: omarchy-app skill: C++/Qt Quick, qmake6, PKGBUILD, Theme class reads accent only from ~/.local/state/omarchy/current/theme/colors.toml (templates.md:115-220). Full palette is in colors.toml (background, foreground, selection, muted...).
- Installed apps: omacut/hype/monologue are pacman packages (/usr/bin, .desktop, icon).
- Tools: wl-copy, wtype present; gh authenticated (ivanjuras, scopes repo). layer-shell-qt 6.7.5, quickshell 0.3.1 present. Repo registered with akrogon: NO (repo: none).

## Forks
F1 Form factor: (a) Omarchy shell overlay plugin (QML, git-installed, themed, keepLoaded = instant) (b) standalone Qt Quick app via omarchy-app (own PKGBUILD, needs layer-shell or float rule, daemon for instant). Pick (a) provisionally: instant open, full theme tokens, keybinding via {panel=...}, update via `omarchy plugin update`. Cost: not an Arch package, no .desktop entry; depends on shell plugin API stability; heavy file IO/GitHub sync must be shell scripts or Quickshell Process. Reshapes F2,F3,F7. Settle first.
F2 Distribution/updates: plugin git repo (omarchy plugin add) vs PKGBUILD/AUR vs both. Follows F1.
F3 GitHub connection: reuse `gh` CLI token (already authed) vs own OAuth device flow vs plain git clone with deploy key. Secret storage. Public vs private repos.
F4 Prompt repo standard: dir tree = categories/subcategories, one prompt per .md file, YAML front matter (title, tags, description, variables defaults), body with {{VAR}}. Folder structure as category (no duplicate metadata) vs explicit category field. Needs a spec doc in the prompt repo itself and a validator.
F5 Sync model: clone to cache dir + git pull on open/interval/manual; offline always works from cache; conflict none (read-only).
F6 Variable-edit UX: whole prompt in one editable text surface; Tab selects next {{VAR}} token (incl braces), typing replaces; repeated same-name variable fills all occurrences or only one; variables with defaults; Ctrl+C with no text selection copies full prompt, with selection copies selection?? (conflict with "Ctrl+C copies entire prompt").
F7 Backgrounding: hide overlay keeping state vs keep visible non-modal; focus return; layer-shell keyboard mode (on-demand vs exclusive) decides whether user can click Chrome while it is open.
F8 Search: fuzzy over title, tags, category, body; ranking; instant at ~1-5k prompts (in-memory JS).
F9 Settings: repo URL/pick, sync interval, keybinding hint, open-in-editor. Keep minimal.
F10 Slicing: prompt-repo format spec; sync service; search+list UI; variable editor+copy; settings+auth; packaging/docs. Real dependency: format spec first.

## Pitfalls
R1 Plugin API is unversioned/young (schemaVersion 1): shell update may break plugin. Removal: pin to documented manifest contract, run `omarchy plugin validate` as a done-criterion.
R2 Ctrl+C meaning clash (copy selection vs copy prompt). Decide explicitly.
R3 Unmatched/malformed {{ }} and variables inside code blocks of prompts (JSON braces `{{`). Needs escape rule.
R4 Private repo token storage; do not write token to plugin dir.
R5 Hyprland binding must not collide with existing user binds (bindings.lua is personal).
R6 Cold-start latency if standalone (F1b) kills the "instant" intent.

## Fog
- Exact Quickshell Process/clone API for git sync from a plugin (not yet read).
- Whether the user wants cross-device sync of settings.

## First: F1 (form factor). It decides packaging, theming, instant-open, and the shape of every later leaf.
