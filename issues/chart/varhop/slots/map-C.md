# varhop opening territory map (slot C)

Read 2026-10-12. Tiers: [OP] operator intake, [SRC] inspected file/source, [MK] own model knowledge.

## 1. Facts inspected

- intake.md: pop-up overlay, one focused search box, Google-style suggestions, Tab/Shift+Tab selects `{{VAR}}` incl. braces, Ctrl+C copies whole prompt and closes, app may go to background, settings = GitHub connect + repo pick, repo standard with categories/subcategories, subtle Omarchy animations. [OP]
- ~/.claude/skills/omarchy-app/SKILL.md:15-107: Omarchy apps are C++/Qt Quick, qmake6, QGuiApplication + Material dark, PKGBUILD via makepkg, Theme watches `~/.local/state/omarchy/current/theme/colors.toml`, keyboard-first conventions (`?`, `Q`, Space), tests via QtTest offscreen. [SRC]
- ~/.claude/skills/omarchy-app/templates.md:175-218: template Theme reads only `accent` by regex; 364-392: PKGBUILD depends qt6-base/declarative/wayland. [SRC]
- ~/.claude/skills/omarchy/hyprland.md:35-59: bindings in `~/.config/hypr/bindings.lua` via `o.bind(keys, desc, cmd | {launch=} | {menu=} | {panel=})`; panels not in the shortcuts file still work "through the command". 71-80: window rules via `o.window`, must fetch current wiki syntax. [SRC]
- ~/.claude/skills/omarchy/plugins.md:6-16, 44-46: shell is one long-running Quickshell process; user plugins in `~/.config/omarchy/plugins/<id>/`, hot-reload on save. [SRC]
- /usr/share/omarchy/shell/plugins/README.md:3-9, 14-20: third-party plugins use the same `manifest.json` contract; kinds include `overlay`; overlays loaded on demand, `keepLoaded: true` keeps the layer window alive between summons. Menu path keybind→IPC→visible costs ~30ms. [SRC]
- /usr/share/omarchy/shell/plugins/emojis/manifest.json: `kinds: ["overlay"]`, `keepLoaded: true`, entry `Emojis.qml`. Emojis.qml:1-7 imports Quickshell, Quickshell.Io, Quickshell.Wayland, qs.Commons, qs.Ui, plus a plain JS module; :54-61 closes via `root.shell.hide(id)`; :151 inserts via `Quickshell.execDetached([... omarchy-menu-emoji-insert])`; :160-180 `OverlayWindow { shown; WlrLayershell.namespace }` with scrim + centered `BorderSurface` card; :190-224 all keys handled in one `Keys.onPressed` (Escape clears then closes, Return confirms). [SRC]
- /usr/share/omarchy/shell/plugins/emojis/EmojiSearch.js:1-48: pure substring filter over keyword text, `module.exports` for node tests. [SRC]
- /usr/share/omarchy/shell/Ui/OverlayWindow.qml:7-54: closed overlay parks as 1x1 input-less layer on WlrLayer.Bottom; shown = WlrLayer.Overlay + exclusive keyboard focus, follows focused monitor. [SRC]
- /usr/share/omarchy/default/hypr/apps/omarchy-shell.lua:7-13: layer_rule `no_anim` for shell overlay namespaces because the parked 1x1 would otherwise slide in from the corner. [SRC]
- /usr/share/omarchy/default/omarchy/shortcuts: lists `panel omarchy.emojis` and `panel omarchy.clipboard` (both kind overlay) as global shortcuts; anything else binds through `omarchy-shell shell toggle`. [SRC]
- `omarchy-shell --help`: `omarchy-shell shell toggle <id> '<json>'`, summon, listPlugins, rescanPlugins. shell.qml:1143,1183,1213 define summon/hide/toggle(pluginId, payloadJson). [SRC]
- /usr/share/omarchy/shell/Commons/Style.qml:350-358: `Style.duration(ms)` returns 0 when `omarchy toggle animations` is off; shell animations must go through it. [SRC]
- /usr/share/omarchy/default/hypr/looknfeel.lua:68-87: window popin 87% easeOutQuint, layersIn fade; these apply to toplevel windows automatically. [SRC]
- /usr/share/omarchy/default/hypr/apps/system.lua:2-4, 30: floating-window tag = float+center+875x600; `omacalc` just `float = true`. No rules exist for hype/monologue/omacut. [SRC]
- ~/.local/state/omarchy/current/theme/colors.toml: full palette keys (accent, selection, muted, background*, foreground*, 8 colors + bright variants, hyprland borders). [SRC]
- omarchy-menu-emoji-insert and omarchy-clipboard-paste-text: Omarchy's copy/paste idiom is `wl-copy` then `wtype -M shift -k Insert -m shift`; wl-copy, wtype present, ydotool absent. [SRC]
- `gh auth status`: logged in as ivanjuras, token in keyring, scopes repo/read:org/gist/workflow. gh at ~/.local/bin/gh (user install, not pacman). yay present, mise present, paru absent. [SRC]
- pacman: hype 0.4.3, monologue 0.2.0 packaged by "Omarchy <pkgs@omarchy.org>" from `[omarchy] https://pkgs.omarchy.org/edge`; omacut "Unknown Packager" (local makepkg). quickshell 0.3.1 from extra. [SRC]
- ~/.config/omarchy/plugins has ivan.bar, ivan.clock, ivan.focus, ivan.monitor, ivan.notifications: operator already runs user shell plugins. [SRC]
- ~/.config/hypr/bindings.lua: operator uses SUPER+SHIFT+S, SUPER+CTRL+RETURN, SUPER+CTRL+T, ALT+END, CTRL+U (app-conditional). Default SUPER+<letter> taken: A C F G J K L O P Q S T V W X. [SRC]
- /home/ivan/Work/omarchy-customizations/varhop: README only, one commit. [SRC]

## 2. Forks

F1 Form factor (settle first)
- O1 Omarchy shell overlay plugin (QML under `~/.config/omarchy/plugins/ivan.varhop`, kind overlay, keepLoaded). Cost: plugin contract is schemaVersion 1, undocumented beyond README, can break on `omarchy update`; no launcher entry; logic in QML/JS only (git/gh via Process); no pacman package.
- O2 Standalone Qt Quick app per omarchy-app skill. Cost: cold start of a Qt Quick binary is hundreds of ms, so "instant" needs a resident process + single-instance IPC + hide/show; toplevel window needs o.window float/center/pin rules and still sits in the normal window stack, not above layer-shell; theme must be re-implemented from colors.toml; separate Hyprland animation path.
- O3 C++ daemon + thin shell overlay. Cost: two moving parts and an IPC seam for one user's tool.
- Pick: O1. It removes the whole class of problems the intake cares most about (instant, above everything, focused, theme-inherited, hotkey without spawning a process), all with inspected precedent (emojis, clipboard). Switch to O2 only if a 1-hour spike shows third-party `overlay` kind is not loaded/toggleable, or if the operator wants an app-launcher entry and pacman distribution more than instant popup. Tier: [SRC] for mechanics, [MK] for Qt cold-start cost.

F2 Instant popup and hotkey
- Under O1: `o.bind("SUPER + ...", "Prompts", { panel = "ivan.varhop" })`; not in the shortcuts file so it runs `omarchy-shell shell toggle` per press (one short process, acceptable). Add a user `hl.layer_rule` no_anim for the `ivan-varhop` namespace or the parked 1x1 slides in from the corner [SRC omarchy-shell.lua:7-13].
- Under O2: `omarchy-launch-or-focus` style or QLocalServer single instance; pin + float rules; still a toplevel.
- Pick: follows F1. Hotkey choice is operator's; free SUPER letters include B D E H I M N R U Y Z (check `omarchy menu keybindings --print` before binding). Tier [SRC].

F3 Prompt repo standard (settle second, independent of F1)
- O1 Directory tree: `category/subcategory/slug.md`, YAML front matter (title, description, tags, optional `variables:` with default/description), body is the prompt. Cost: need a front-matter parser (small, JS or C++).
- O2 Single index file (prompts.yaml/json). Cost: merge conflicts, unreadable in Notion-replacement sense, one bad line kills all prompts.
- O3 Plain `.md` with no front matter, title = filename. Cost: no descriptions/tags for search.
- Pick: O1 with O3 as the degenerate case (front matter optional, defaults from path/filename). Variable syntax fixed as `{{NAME}}` [OP]; same name repeated = one linked value filled everywhere; literal braces escaped as `\{{`. Category depth capped at 2 so the UI has a stable shape. Tier [OP]+[MK].

F4 GitHub connection, auth, sync
- O1 Reuse `gh`: `gh repo list` for the picker, `gh repo clone` / `git pull` into `~/.local/share/varhop/repo`. App stores zero secrets; the clone is the offline cache. Cost: hard dependency on gh being installed and logged in (here it is a user-local binary, not a package).
- O2 OAuth device flow + GitHub API in-app, token in keyring. Cost: own secret storage, token refresh, rate limits, a GitHub OAuth app registration.
- O3 Any git URL + ssh deploy key. Cost: no repo picker, manual setup.
- Pick: O1, falling back to O3 (any URL) when gh is absent, with the missing tool reported in the window per Omarchy convention. Sync on open (debounced, background) + manual refresh key. Tier [SRC gh status]+[MK].

F5 Search
- O1 Substring filter like EmojiSearch.js. O2 Fuzzy subsequence with scoring (title > path/tags > body). Pick: O2, in a pure JS module with node tests (precedent: EmojiSearch.js exports). Library is hundreds of prompts, in-memory is enough. Tier [SRC]+[MK].

F6 Variable editing surface
- O1 Real editable TextEdit of the whole prompt; Tab/Shift+Tab move selection across `{{VAR}}` ranges recomputed from current text. Cost: once the user types over a token the marker is gone, so the token list must be derived from the original template plus a per-variable value map, not re-parsed from the edited text.
- O2 Read-only rendered prompt + a form of fields. Cost: breaks the "edit in place" feel the intake asks for.
- Pick: O1 implemented as template + values model that re-renders; Tab order = first appearance; repeated names linked. Tier [OP]+[MK].

F7 Ctrl+C semantics
- Intake: Ctrl+C copies whole rendered prompt and closes [OP]. Pitfall: with a variable selected, standard Ctrl+C would copy the selection. Pick: Ctrl+C = whole prompt via `wl-copy` (plain, not --foreground/--sensitive, so it outlives the call) then hide; Ctrl+Shift+C = copy selection only; Return on the prompt view does the same as Ctrl+C. Optional later: `wtype shift+Insert` to paste into the previously focused app (Omarchy idiom). Tier [SRC]+[OP].

F8 Backgrounding
- O1 Hide overlay but keep state (keepLoaded + in-memory draft); same hotkey brings the half-filled draft back. O2 Standalone window stays pinned on screen while the user works in Chrome. Pick: O1 under F1-O1; Esc = back one level, hotkey = hide/show, Ctrl+C = copy, close, reset. Draft survives until copied or explicitly cleared. Tier [SRC OverlayWindow]+[OP].

F9 Packaging and updates
- Under O1: git repo cloned into `~/.config/omarchy/plugins/ivan.varhop`; update = `git pull`, shell hot-reloads. No pacman, no mise. mise manages language runtimes and is irrelevant to a QML plugin or a Qt binary; flag this to the operator.
- Under O2: PKGBUILD + makepkg (local), optionally AUR via yay for updates; the `[omarchy]` repo is Omarchy-team only.
- Pick: follows F1; document install as two commands. Tier [SRC].

F10 Theme and animation
- Under O1 the shell palette/Style singletons give the full colors.toml palette and `Style.duration()` reduce-motion for free. Under O2 extend the template Theme to parse the whole palette. Animations: short fade/scale on card open, list item highlight, selection move, all through `Style.duration` (O1) or a Behavior with a single shared duration constant (O2). Tier [SRC].

F11 Settings contents
- Minimum: repo (owner/name or URL), local clone path (default), sync-on-open toggle, hotkey hint (read-only, since the binding lives in bindings.lua). Pick: a small settings view inside the overlay plus a JSON file under `~/.config/varhop/`. Tier [OP]+[MK].

F12 Tests
- O1: JS modules (front-matter parse, variable tokenizer/renderer, fuzzy scorer) tested with node; QML smoke by `omarchy-shell shell toggle`. O2: QtTest per skill. Tier [SRC].

## 3. Practitioner questions / pitfalls

- R1 Third-party `overlay` kind may not get `shell`, `manifest`, or theme injection the way first-party ones do. Remove: 1-hour hello-world overlay spike before any other work.
- R2 Shell plugin API changes on `omarchy update` break the tool silently. Remove: pin against inspected imports (qs.Ui OverlayWindow, qs.Commons Style/Color), keep plugin tiny, keep logic in plain JS modules that survive a QML rewrite.
- R3 Parked 1x1 overlay animates as a corner slide. Remove: user layer_rule no_anim for the namespace in `~/.config/hypr/`.
- R4 Editing destroys `{{VAR}}` markers so Tab loses its targets. Remove: template + values model (F6).
- R5 Ctrl+C copies selection, not prompt, or wl-copy dies with the caller. Remove: explicit key handling in `Keys.onPressed`, plain `wl-copy` without --foreground.
- R6 Unfilled variables copied by accident. Remove: Ctrl+C with unfilled vars jumps to the first unfilled one and shows a one-line notice; second Ctrl+C copies anyway.
- R7 gh missing or logged out on another machine. Remove: report in-window with the exact command to run; allow plain git URL.
- R8 Repo format drift (someone adds depth 3, odd front matter). Remove: lenient loader with per-file error list shown in settings, never a silent skip.
- R9 Sync on every open adds network latency to an "instant" tool. Remove: show cached index immediately, pull in background, re-index on completion.
- R10 Hotkey collides with a default or app shortcut. Remove: check `omarchy menu keybindings --print`, use `o.bind` not `o.rebind` unless intended.
- R11 Multi-monitor: overlay must appear on the focused monitor. Covered by OverlayWindow following Hyprland.focusedMonitor; verify in spike.
- R12 Operator expects pacman/mise-managed install. Remove: state clearly which install/update path F1 implies before building.

## 4. Fog

- Whether a user plugin can be summoned with `{ panel = "ivan.varhop" }` or only via the toggle command, and how payload/injected `shell` reach third-party overlays (R1 spike answers both).
- Exact keyboard contract inside the editor: does Tab leave the editor, does Return insert a newline or copy, how to type a literal Tab. Needs a 10-minute decision table with the operator.
- Whether the operator wants paste-into-previous-app (wtype) or copy only. Intake says copy only; the Omarchy idiom suggests paste is a cheap add.
- Repo picker scope: own repos only, or orgs too. Affects `gh repo list` flags only.
- Whether anyone else will use the repo standard (team) or just the operator. Changes how strict F3 should be.

## 5. Which fork first

F1. It decides the runtime (Quickshell vs Qt app), hotkey mechanism, theme path, animation path, packaging, test strategy, and backgrounding model. Every other fork except F3 and F5 changes shape with it. Settle F1 by the R1 spike, run F3 in parallel since it is independent, then the rest follows.
