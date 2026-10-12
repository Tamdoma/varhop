# settings-and-hotkey: merged (A, 2026-10-13)

Sources: settings-and-hotkey-{A,B,C}.md. Tags list the slots whose notes say the line.

## Agreed
- Hotkey ownership: varhop never writes Hyprland config and never reloads Hyprland. The user pastes one `o.bind(..., { panel = "ivan.varhop" })` line into ~/.config/hypr/bindings.lua. The README and settings show that line with a copy button (A,B,C). Users who want to take over a chord edit it to `o.rebind` themselves. varhop never generates that (B,C).
- Rejected: plugin writes bindings.lua, drop-in file (never loaded, C: hyprland.lua:16-20), runtime `hyprctl keyword` or GlobalShortcut, no suggested chord (A,B,C for writes; B,C for runtime).
- Conflict check: settings runs `hyprctl binds -j` for the chord in the field and warns when the modmask+key is already bound, naming its description (A,B,C). Settings does not claim to know the current varhop binding. Lua binds report dispatcher `__lua` (C; A re-verified 2026-10-13: Power = `__lua` arg 363), so "bound to ivan.varhop" cannot be detected. A concedes its "Hotkey: bound/not bound" status. The chord field is not persisted (B,C).
- Settings is a view inside the overlay, reached by Ctrl+, and a visible button (A,B,C). It holds: gh status plus fix, repo picker (`/user/repos` plus typed owner/repo), Sync now, last successful pull, last error, load errors, the hotkey section, and a usage reset (A,B,C). No token field, theme, font, animation or keymap controls (B,C).
- Summon routing: an existing draft resumes first (C, from copy-and-close Taken). Otherwise, with no repo selected, open settings at the picker (A,B,C). Otherwise open search.
- Rejected: an Omarchy menu entry (a third-party plugin cannot add itself), a second panel or bar widget (A,B,C).
- Settings saves the full object through `updateEntryInline` (B,C, sync Taken).
- Ctrl+P in the editor = Find another prompt, draft kept (A,B,C). Ctrl+, = settings (A,B,C). Ctrl+R = pull (A,B,C). Match exact modifier state, never "contains Control" (B,C).
- Lifecycle: varhop runs no automatic cleanup. Remove disables the plugin before deleting it, so varhop cannot run at uninstall (A,B,C; remove:96). The README names what is left behind: the bind line (a no-op after removal), ~/.cache/varhop, usage state (A,B,C).
- Customizable in v1: the global chord, the repo, and the inherited Omarchy theme. Nothing else (A,B,C).

## Correction to A
- Disable and remove both delete the whole shell.json plugin entry, repo selection included (B,C: PluginRegistry.qml:557; re-enable inserts a bare `{id}`, :541). A wrongly said the entry stays. Consequence (B,C): after disable then enable, the next summon is a first run into the picker.

## Disagreements
- D-a Suggested chord: SUPER+ALT+P (B,C: P for prompts, free on stock Omarchy and this machine) vs SUPER+CTRL+M (A). A concedes to B,C.
- D-b Resume key: Ctrl+Shift+P from search or settings (B,C) vs Ctrl+P flipping both ways (A). B: one key with two actions hides two actions behind one label. A concedes.
- D-c Esc in settings: back to the view it was opened from (B,C; C: first-run settings Esc hides) vs hide (A). C notes this is a third Esc rule. Open.
- D-d Ctrl+R scope: every stage including the editor (B,C; the draft is untouched by sync Taken) vs search and settings only (A). Inert inside picker text fields (C P7). Open, minor.
- D-e Usage reset: current repo only (A,B) vs the whole file with press-again confirm (C). Open, minor.

## New questions for the operator
- N1 Disable wipes the repo selection (host behavior). Accept it, or (C U4) pre-highlight the repo whose clone is still cached in the picker as a one-click reconfirm? (B,C)
- N2 (C U2) Add a "Delete local varhop data" button (both clone slots plus usage, keep the selection), or name the paths only in the README?
- N3 (C U3) Add a second chord or payload that opens straight into settings, or is Ctrl+, after summon enough?
- N4 (B) When the repo is replaced, the open draft keeps its original source and repo identity. Confirm.
- N5 (B) Find another prompt returns to the previous search query and selection, not a cleared field. Confirm.

## Proof items (A,B,C)
- Ctrl+, keysym on the hr layout (A P4).
- Every owed chord typed into every focusable field (C P7).
- Super+C/V over a browser and over a terminal with varhop focused (B).
- Disable/enable wipes and recreates the entry. Update keeps the selection. Remove leaves the listed files (B).
- `omarchy-shell shell summon ivan.varhop` as the no-bind fallback, inside the pending third-party overlay proof (B,C).
