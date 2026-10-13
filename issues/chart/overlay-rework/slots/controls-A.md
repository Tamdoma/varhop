# Controls notes, slot A

## Q1 placement and shape
Pick: one header row per view, same height as the query row (Omarchy menu headerHeight rule, Menu.qml:107). Editor and settings: a "‹ Back" text button at the left, the view title in the middle, "Settings" (editor only, gear glyph + word) at the right. Search: the query field plus a "Settings" button at the right. Text labels with glyphs, never glyph-only (F7 says "no visible settings entry", a lone gear is the same discoverability gap).
Rejected: footer hint bar only (Raycast style): shows keys but is not clickable, F6 asks for a visible control. Context menu: hidden again.
Evidence:
- primary · Omarchy menu has no visible back control, back is Backspace/Left on an empty filter (/usr/share/omarchy/shell/plugins/menu/Menu.qml:1248), header shows the current menu title (:1315). So copying Omarchy alone would not fix F6.
- practitioner · Raycast (manual.raycast.com, from training, search not run): back arrow at top left of every pushed view plus a footer action bar listing the primary key. Shows both a clickable back and a key hint.
Pitfalls: header steals vertical space at 480 card height -> header reuses the query row height, editor loses one row only.

## Q2 keyboard reach
Pick: controls are Tab stops outside the editor's variable cycle. In editor: Tab/Shift+Tab stay on variables (Taken). Keys stay as today: Esc back/hide, Ctrl+, settings. Each button shows its key in small muted text ("Esc", "Ctrl+,"). No new key. Settings Tab order: Back, then fields, as proof-bar Tab+Enter already requires.
Evidence: primary · EditorBody.qml:216-235, SettingsBody.qml:80-96, Varhop.qml:792, README:57-64.
Pitfalls: putting Back into the editor Tab cycle breaks the editor Taken (B editor R5). A focused button stealing Esc -> Esc handled at the view level as today.

## Q3 Esc in editor
Pick: keep Esc = hide in editor (draft kept, Ctrl+Shift+P resumes), Back button = return to list. Changing Esc to go back would change muscle memory and conflict with README. Ask the operator because F6 "discoverable back key" may mean Esc should go back.
Alternative: Esc goes back to list, second Esc hides (menu-like). Cost: two presses to dismiss from editor.
