# settings-and-hotkey: blind notes (slot A)

Read 2026-10-12. Tiers: [OP] operator, [SRC] inspected code, [DOC], [MK] model knowledge.

## Q1 Hotkey
Pick: varhop never writes Hyprland config. The user adds one line to ~/.config/hypr/bindings.lua: `o.bind("SUPER + CTRL + M", "Prompts", { panel = "ivan.varhop" })`. The README and the settings view show this line with a copy button. Suggested chord: one free on this machine (SUPER+CTRL+M is free; SUPER+CTRL+P is taken). Settings shows "Hotkey: <chord>" or "Hotkey: not bound", read from `hyprctl binds -j` by matching the dispatcher that names ivan.varhop, and warns when the same chord has another bind. Reason: every first-party panel uses exactly this shape (utilities.lua:101-107, clipboard.lua:49). `panel` resolves to `omarchy-shell shell toggle <id>` (helpers.lua:99-100). The user's bindings.lua is user-owned and already hand-edited with many backups (~/.config/hypr/*.bak.*). Cost: one manual step at install.
Rejected: plugin writes or patches bindings.lua (edits a user file, needs Hyprland reload, races with the user's own edits, and plugin remove can't undo it); a separate generated lua file required from hyprland.lua (still edits a user file once); no default chord in the README (the user has to search for a free chord themselves).
Evidence: [SRC] helpers.lua:138-157 (o.bind, o.rebind = hl.unbind then bind); `hyprctl binds -j` on this machine, 2026-10-12. Free SUPER+CTRL letters: G J M U Y. Free SUPER letters: B D E H M N R U Y Z. Layout is hr.

## Q2 Settings surface
Pick: a second view inside the overlay, not an Omarchy menu entry. Holds: gh login status plus the fix command, repo picker, Sync now with last sync time and the last error, hotkey status (Q1), "Clear usage history" for the current repo. First run (no repo saved) opens straight into the repo picker. Reason: everything settings controls lives in varhop's own state, and one surface keeps the plugin self-contained. Cost: one more view in the overlay.
Rejected: an Omarchy menu entry (needs editing Omarchy menu files; no plugin hook found); a separate panel id (a second summon target and bind).

## Q3 Keys
Pick:
- Ctrl+P in the editor = "Find another prompt" (back to search, draft kept). Ctrl+P in search with a draft = "Resume draft". One key flips between the two views.
- The pinned "Resume draft" row is also clickable. It is never reached by Enter on the top result.
- Ctrl+R = pull, in search and settings.
- Ctrl+, = toggle settings. Esc hides everywhere, per copy-and-close.

Reason: no collision with Tab, Enter, Esc, Ctrl+C, Ctrl+Shift+C, Ctrl+Z, or the Super+C/V forwarding (clipboard.lua:45-47). Ctrl+P matches the "go to file" habit. Cost: Ctrl+P is not printed-shortcut obvious, so the footer shows the hints.
Rejected: Ctrl+F (means find-in-text inside an editor); Alt+Left back (no first-party precedent).

## Q4 Lifecycle and customization
Pick: varhop leaves cleanup to the user and documents it. `omarchy plugin remove` disables the plugin, then deletes or unlinks only ~/.config/omarchy/plugins/<id> (omarchy-plugin-remove:94-117) and has no plugin hook. It leaves behind: the user's bind line, which does nothing because shell toggle returns void (shell.qml:1243-1246 and 1910-1912; `omarchy-shell shell toggle ivan.nonexistent` exits 0 with no effect, tested 2026-10-12), ~/.cache/varhop, ~/.local/state/varhop, and the shell.json entry. The README lists them with one removal command. Customizable in v1 means only the chord and the repo. Cost: leftovers stay until the user deletes them.
Rejected: self-cleanup on disable (disable is not remove, and deleting the clone there would cost a re-clone).

## Pitfalls
- P1 A bind to a disabled or missing plugin fails silently: settings shows the bind status, and the README says to enable before binding.
- P2 Chord conflicts: Hyprland allows duplicate binds and runs both. The settings check in Q1 shows the conflict.
- P3 The hr layout has no semicolon or apostrophe keys, so suggest only letter chords.
- P4 Ctrl+, depends on the layout keysym: verify comma on hr in the leaf, or use Ctrl+S.

## Questions not asked
- Q5 Should the suggested line go in the README only, or does settings also offer "copy bind line"? I recommend both.
