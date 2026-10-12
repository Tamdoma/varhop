# Copy and close

## Question
Q1. Ctrl+C: what is copied (rebuilt prompt only, never title or front matter), how it reaches the clipboard (Quickshell.clipboardText, wl-copy via stdin, first-party omarchy-clipboard helpers), and does the overlay then close only or also paste into the previously focused app?
Q2. Unset variables at Ctrl+C: copy their `{{NAME}}` tokens as-is, warn, or block?
Q3. Ctrl+C with ordinary text selected in the editor or search box: copy the selection or the whole prompt?
Q4. Keys and stages: what Esc does in the editor (back to search, hide with draft, discard) and in search (hide); what summoning does while a draft exists (resume vs fresh search); whether the draft survives a shell reload, plugin update or theme change.

### Carries
- Operator intake: Ctrl+C copies the whole prompt and closes; the app can be hidden mid-edit and resumed (INTAKE.md).
- variable-editing taken: copy rebuilt from source segments plus values; resume keeps exact cursor and selection; empty values copy as nothing, unset as `{{NAME}}` text in the rebuilt source (forks/variable-editing.md).
- sync-and-auth taken: refresh never changes the open draft; manual pull only (forks/sync-and-auth.md).
- C2 review M2 (slots/review-C2.md): `Quickshell.clipboardText` is settable (quickshell-core.qmltypes); omarchy-clipboard-paste-text takes text as argv (:49-52), exposing it in the process list and capping size.
- Moved from Fog: paste into the previously focused app vs copy only.

## Findings
Independent notes: slots/copy-and-close-A.md, -B.md, -C.md. Merged: slots/copy-and-close-merged.md. Rebuttals: slots/copy-and-close-rebuttal-B.md, -C.md.
- Settled after rebuttal: copy the rebuilt body only via a tracked `Process` running `wl-copy` with explicit plain-text type on stdin (EOF by `stdinEnabled: false`); hide and finish the draft only after exit 0; failed start (no `exited`, process.cpp:290-298), nonzero exit or timeout keep the draft and show the error; commit IME preedit first. No auto-paste. Copies enter Omarchy clipboard history (whitespace-only entries dropped, ClipboardHistory.js:8-10). Empty output is a valid copy (B; C conceded, wl-copy.c:243-299). Unset variables copy as `{{NAME}}`, no block, visible unset count from the name model. Ctrl+C in the editor always copies the whole prompt, regardless of selection (A,B; C conceded); search and settings fields keep native selection copy. Esc in the editor hides and keeps the draft (B; C conceded: Esc is never "back" in this shell, Menu.qml:1241-1249, PanelKeyCatcher.qml:56-57); a "Find another prompt" action reaches search with the draft kept, binding owned by settings-and-hotkey. Summon resumes the draft exactly; copy success ends it; choosing another prompt replaces it; resuming a draft after a pull keeps its original source (B F2). Draft survives hide and theme changes (B E10, shell.qml:1764-1777; A conceded), not plugin reload, any plugin update or shell restart; no disk persistence.
- Universal copy (C RC5, verified): Super+C sends Ctrl+C, or Ctrl+Shift+C when the active window is a terminal, to focused layer surfaces (/usr/share/omarchy/default/hypr/bindings/clipboard.lua:1-7,45). The editor treats Ctrl+Shift+C exactly like Ctrl+C; the variable-editing paste proof includes Ctrl+Shift+V from Super+V (:46).
- Open: Esc in search with a typed query. C: first Esc clears the query, second hides (Clipboard.qml:355-357, Emojis.qml:196-199, Menu.qml:1241-1243). B: hide at once and keep the query for the next summon.

## Taken

2026-10-12 operator: `1a`
- Esc in search: first Esc clears a non-empty query, Esc on an empty query hides (first-party habit; foreclosed: hide and keep the query).
- All Settled items in Findings stand as presented and not objected: wl-copy over stdin with exit-0 close, no auto-paste, history capture accepted, empty output valid, unset copied as `{{NAME}}` with a count, editor Ctrl+C and Ctrl+Shift+C always copy the whole prompt, editor Esc hides with the draft kept, "Find another prompt" binding owed to settings-and-hotkey, draft in memory only (survives hide and theme change, not plugin reload/update or shell restart).
