# Merged opening map (A merges A, B, C). Tags = agreeing slots.

## Agreed (A,B,C)
- Settle F1 form factor first; it decides process model, hotkey, theme, animation, packaging, tests.
- F1 provisional pick: Omarchy shell overlay plugin (Quickshell, kind overlay, keepLoaded), not a standalone Qt app. Evidence: emojis/clipboard are exactly this shape (/usr/share/omarchy/shell/plugins/emojis/manifest.json; default/hypr/bindings/utilities.lua:3). Theme: Color.menu.* tokens give the full palette live (B: Commons/Color.qml:100-107). Animation: Style.duration() obeys the animations toggle; compositor anim is off for shell overlays and QML owns the fade/grow (apps/omarchy-shell.lua:4-13; Style.qml:350-358). Cost: depends on shell plugin API (schemaVersion 1); logic in QML/JS; no .desktop/launcher entry. Standalone Qt cost: cold start, single-instance IPC, theme re-implemented (accent only in template), toplevel not above layer-shell.
- Resident, hide (not minimize), draft kept in memory while hidden. Shown overlay takes exclusive keyboard focus (C: OverlayWindow.qml:7-54; B: KeyboardPanel.qml) so the user must hide it to use Chrome.
- GitHub through the `gh` login the user already has; app stores no token (gh authed as ivanjuras, scopes repo).
- Repo format: `<category>/<subcategory>/<slug>.md`, folder = category, optional YAML front matter (title, description, tags, per-variable default/description), body literal prompt text, `{{NAME}}` variables. Exact schema/depth cap to settle with operator.
- Variables: derive the Tab order from the original template plus a values map, never re-parse edited text (typing over a token deletes its marker). Tab/Shift+Tab selects the whole token incl braces, body order. Repeated name = one shared value (provisional). Literal braces escape `\{{NAME}}`.
- Ctrl+C in the editor copies the whole rendered prompt, even with a selection; use plain `wl-copy` (not --foreground) so the clipboard survives close.
- Search: local fuzzy, in-memory, pre-indexed, title > aliases/tags/category > description/body, stable tiebreak.
- Pitfalls: R-summon over fullscreen/right monitor, hidden-overlay parked 1x1 slide-in from corner (needs layer rule no_anim, already present for first-party namespaces only), hotkey collisions (check `omarchy menu keybindings --print`), sync latency (show cache, refresh in background), malformed repo files (show per-file errors, never silent skip), plugin API change on omarchy update.

## Differences
D1 Install/update path. A: plugin installs with `omarchy plugin add <git-url>` and updates with `omarchy plugin update` (inspected /usr/share/omarchy/bin/omarchy-plugin-add; list/remove/validate exist), so no pacman/mise needed. C: same idea via manual git clone (did not find the command), says mise is irrelevant. B: PKGBUILD first, AUR later (written for the Qt route; says a plugin would need a package-to-plugin-dir path). A,C vs B.
D2 Sync mechanism. A,C: clone with git/gh into a cache dir, pull in background. B: commit-pinned API snapshot, atomic publish, no git state. Open.
D3 Ctrl+C details. B: Ctrl+C always whole prompt; close only after clipboard success; unresolved variables keep editor open with reason. C: Ctrl+Shift+C copies selection only; Return = Ctrl+C; unresolved variables: first Ctrl+C jumps to first unfilled variable with a notice, second copies anyway. A: unresolved-variable policy is an operator question.
D4 Blur behavior. B: blur hides, keeps draft. C: hotkey toggles; Esc steps back one level; Ctrl+C copies, closes, resets draft. Open.
D5 Spike. C: 1-hour hello-world third-party overlay spike before other work (third-party `overlay` kind may not get shell/theme injection). A: shell.qml shows third-party plugins get a scoped `shell` (pluginShellFor) and may toggle their own id; theme singletons are imports (qs.Commons) so likely available; still needs one real call as operation proof. B: prove focus over fullscreen, right monitor, rapid hide/reopen in real Hyprland.
D6 Extra asks from C: paste into previously focused app via wtype (Omarchy idiom) is a cheap add; intake says copy only. Category depth cap 2 (C) vs agree depth with operator (B).

## Operator-owned open questions (no peer can answer)
Does a shell plugin count as the "native application" they want (vs launcher entry + own binary)? Actual prompt repo/Notion export structure and size; public/private/org; summon hotkey; unresolved-variable policy; paste-into-app or copy only.

## Not registered
varhop is not registered with akrogon (config repo: none); charting continues locally, handoff needs registration (outside the door).
