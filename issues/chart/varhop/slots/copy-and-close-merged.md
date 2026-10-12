# copy-and-close: merged notes (A)

Sources: slots/copy-and-close-A.md, -B.md, -C.md (2026-10-12).

## Agreed
- Q1 Copy only the rebuilt body (no title, front matter, labels, added newline) (A,B,C). Transport: a tracked Quickshell `Process` running `wl-copy` with an explicit plain-text type, text written on stdin, `stdinEnabled: false` sends EOF (A,B,C; Process docs, process.cpp:169-175). Hide and finish the draft only after exit 0; failed start, nonzero exit or timeout keep the draft and show the error (B,C; A conceded hide-on-start). Detect FailedToStart separately, since it emits no `exited` (B, process.cpp:290-298). Commit IME preedit before building the text (B,C). No auto-paste into the previous app (A,B,C). Not `Quickshell.clipboardText` (no result, owner tied to the shell process) and not `omarchy-clipboard-paste-text` (argv) (A,B,C). Copies land in Omarchy clipboard history like any copy; accepted, no `--sensitive` (A,B,C).
- Q2 Unset variables copy as `{{NAME}}`, no block, no confirm; an always-visible unset count while editing; empty values copy as nothing and are not counted (A,B,C). Count comes from the parsed name model, not the output text (B).
- Q4 Summon with a draft resumes it exactly; successful copy ends the draft; opening a different prompt replaces it without confirm; one in-memory draft (A,B,C). The host's `close()` on hide must never clear the draft (B,C; shell.qml:1213-1227). Draft survives hide and normal theme changes, not plugin reload, any plugin update (host reloads all panels), shell restart (A,B,C; shell.qml:1266-1271,1509-1518, omarchy-plugin-update:130-131). No draft persistence to disk (A,B,C).
- Search-stage Ctrl+C copies selected query text natively (B,C).

## Disagreements
- D-a Ctrl+C in the editor with a deliberate selection. A,B: always the whole prompt, as the operator specified. C: whole prompt when nothing or only the auto-selected stop is selected; a deliberate drag/shift selection copies just that text and stays open.
- D-b Esc in the editor. A,C: back to search, draft kept and marked on its row. B: Esc hides from every stage (same as the hotkey), plus a separate "Find another prompt" action to reach search.
- D-c Esc in search. C: clear the query if not empty, else hide (first-party habit, Clipboard.qml:355-358). A,B: hide.
- D-d Empty output. C: refuse with "nothing to copy", draft kept. B: copy empty text as valid output.
