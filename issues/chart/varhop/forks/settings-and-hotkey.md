# Settings and hotkey

## Question
Q1. Global hotkey: default chord (if any), and who writes the Hyprland binding: the user pastes a line from settings, the plugin writes a bindings file and reloads Hyprland, or another Omarchy-native mechanism; how conflicts with existing bindings are detected and shown.
Q2. Settings surface: where it lives (inside the overlay as a view, or an Omarchy menu/panel entry), what it holds (gh status, repo picker, Sync now, last sync, load errors, hotkey, usage reset), and first-run routing (hotkey with no repo opens the picker).
Q3. In-overlay keys still owed: "Find another prompt" (editor → search, draft kept), "Resume draft" (pinned action key), manual pull (Ctrl+R?), open settings; must not collide with Tab, Ctrl+C, Ctrl+Shift+C, Esc, Enter, Ctrl+Z, Super+C/V forwarding.
Q4. Lifecycle: what `omarchy plugin remove` leaves behind (binding, ~/.cache/varhop clone, usage state, shell.json entry) and whether varhop cleans any of it; what "customizable" from the intake covers in v1.

### Carries
- Operator intake: custom keyboard shortcut; settings connect GitHub and choose a repo; lightweight, customizable, compatible with Omarchy updates (INTAKE.md).
- form-factor taken: overlay plugin, `omarchy plugin add`/`update`; binding shape `o.bind(keys, desc, { panel = "ivan.varhop" })` (forks/form-factor.md).
- sync-and-auth taken: selection saved via `shell.updateEntryInline` (full object) in shell.json; volatile state in a state-dir file; Ctrl+R and "Sync now" manual pull; gh login status and fix shown in settings (forks/sync-and-auth.md).
- copy-and-close and search taken: owed keys "Find another prompt" and "Resume draft"; usage store exists and may need a reset (forks/copy-and-close.md, forks/search.md).
- C2 review M4: who writes the bind, conflicts, what plugin remove leaves, first run opens the picker.
- Pending step: prove a third-party overlay plugin with own-id summon/hide/toggle and the panel binding (CHART.md).

## Taken (2026-10-13)
Operator answer: `1a | 2a | 3a | 4a`. Defaults presented and not objected to are recorded below as taken. Sources: slots/settings-and-hotkey-{A,B,C,merged,rebuttal-B,rebuttal-C}.md.

Hotkey
- varhop never writes Hyprland config and never reloads Hyprland.
- The user pastes one line into ~/.config/hypr/bindings.lua: `o.bind("SUPER + ALT + P", "Varhop prompts", { panel = "ivan.varhop" })`. SUPER+ALT+P was free on this machine on 2026-10-13. It is a suggestion, not an installed default.
- Settings has a chord field, the rendered line and a copy button. The chord field accepts only a validated modifier-plus-key vocabulary and never interpolates free text into Lua. It is not persisted.
- Conflict check: query the live binds (parser is a leaf detail; `hyprctl binds -j` can emit invalid JSON, omarchy-menu-keybindings:300-303). Warn with the existing description and submap. A known collision means the line is not shown as ready. If the layout, keycode or catch-all check is incomplete, say so instead of "free". varhop never generates `o.rebind`.
- varhop does not claim to know its current binding, because Lua binds report `__lua`.
- `omarchy-shell shell summon ivan.varhop` is the documented no-bind fallback, inside the pending third-party overlay proof.

Settings
- Settings is a view inside the overlay, opened with Ctrl+, or a visible button.
- It holds: gh status plus the fix, the repo picker, Sync now, the last successful pull, the last error, load errors, the hotkey section, and "Reset usage for this repository" (the current repo id only). Nothing else.
- Saves go through `updateEntryInline` with the full object. False can mean unchanged, and true is not a durability acknowledgement, so the save proof reads it back.
- Summon routing: an existing draft resumes first. With no repo selected, varhop opens settings at the picker. Otherwise it opens search.
- Esc in settings returns to the view settings was opened from. With no earlier view (first run), Esc hides (1a).

Keys
- Ctrl+P in the editor = Find another prompt. It returns to the previous query and selection, and the draft is kept.
- Ctrl+Shift+P in search or settings = Resume draft. It does nothing without a draft. The pinned row shows the chord.
- Ctrl+R pulls in every view, including the editor, and never changes the draft. It is inert inside the picker's text fields. Only one import or pull runs at a time.
- Ctrl+, toggles settings.
- Keys match exact modifier state.
- In search and settings fields, Ctrl+V and Ctrl+Shift+V paste natively, and both copy variants copy the text selection without triggering the editor's export.

Lifecycle
- No automatic cleanup. Remove disables the plugin before deleting it, so varhop never runs at uninstall.
- The README lists the leftovers and the paths to delete by hand: the bind line (a no-op after removal), ~/.cache/varhop, and the usage state (3a).
- Disable and remove delete the whole shell.json entry, including the repo selection (PluginRegistry.qml:541,557).
- After re-enable, the user picks from the normal empty picker. varhop never infers a repo from the cache (2a).
- Changing the repo while a draft exists warns that a successful switch discards the draft. A failed or cancelled import keeps it. Library, draft, markers and usage always share one repo identity (4a).
- Customizable in v1: the global chord, the repo, and the inherited Omarchy theme.
- There is no second chord into settings.

Proof items for the leaf
- Ctrl+, keysym on the hr layout.
- Every owed chord typed into every focusable field.
- Super+C/V over a browser and a terminal with varhop focused.
- Disable/enable wipes and recreates the entry. Update keeps the selection. Remove leaves the listed files.
- Settings save with read-back.

Handoff review amendment (2026-10-13, operator `1a`; raised by B F5): the Super+C/V proof item is a done-criterion proven by the agent. It sends the exact key-state sequence the binds send (`hl.dsp.send_key_state`, clipboard.lua:8-47) through `hyprctl dispatch`, over a browser and over a terminal-tagged window. The physical Super key press is not proven (proofs-overlay.md rows 13-14). Foreclosed: operator presses during the build, and post-merge acceptance.

Handoff review amendment (2026-10-13, operator `3a`): the overlay-plugin leaf may run `omarchy-restart-shell` before a live run to load new plugin code (proofs-overlay.md rows 14, 18-19). The README tells users to restart the shell after `omarchy plugin update`.
