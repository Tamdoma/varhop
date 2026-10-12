# Brief: overlay-plugin

## What
The `ivan.varhop` Omarchy shell plugin at the repo root:
- `manifest.json` with kind overlay and keepLoaded.
- QML views for search, editor and settings. The interactive components (search list, editor, settings body) import no Quickshell module, so `qmltestrunner` can load them. The plugin root passes them `Commons.Color` values and the shell API. (A,B,C)
- The usage-state file, copy through `wl-copy`, every locked key, and a README with the install steps, the bind line, the repo format, the shell-restart step after an update, and the leftover paths.

It consumes the `lib/*.mjs` functions from prompt-core and the `bin/varhop-sync` contract plus `library.json` from repo-sync, as pinned in their designs. It reimplements neither.

## Why
This is the destination. A hotkey summons a themed overlay, instant search opens a prompt, Tab walks the `{{NAME}}` values, and Ctrl+C copies and closes. The library comes from the operator's GitHub repo, and the overlay replaces Notion for prompts.

## Done-criteria
Live checks run in the operator's omarchy-shell. Component checks run `qmltestrunner` with `QT_QPA_PLATFORM=wayland` inside the blocking `test` check, where real Wayland clipboard paste and synthetic left and right clicks work (proofs-overlay.md row 16). (A,B,C)

1. Install, update and layering (live):
   - `omarchy-plugin-validate` passes on the repo root.
   - `omarchy plugin add file://<local clone> --enable --yes` installs it, and `omarchy-shell shell summon ivan.varhop` shows the overlay at layer level 3 on first open on each connected monitor.
   - Colors come from `Commons.Color`, and the shell log shows no QML errors for the plugin.
   - A new commit in the local clone, then `omarchy plugin update ivan.varhop --yes`, leaves the shell.json entry byte-identical. After `omarchy-restart-shell` the new code runs (proofs-overlay.md row 14). (A,B,C)
2. Load and first run (live):
   - With no selection, summon opens settings at the picker, and Esc there hides.
   - Choosing `Tamdoma/varhop-prompts` from the picker runs the first sync and shows search with every prompt. The shell.json entry reads back with repo, login, account id and repo id. The selection is saved after the import succeeds.
   - Typing `Tamdoma/varhop-prompts` in the typed field selects it through `varhop-sync repo`, and a malformed `owner/repo` is refused in the field. (A,C)
   - After `omarchy-restart-shell`, summon opens search from the saved selection and the existing `library.json`. The sha256 and `fetchedAt` of `library.json` are unchanged across the restart and summon. (A,C)
   - A `library.json` whose repo id differs from the saved selection is not loaded. Settings names the mismatch and offers Sync now. (A,B)
   - Killing the running `varhop-sync` (`pkill -f varhop-sync`) during Ctrl+R leaves `library.json`, the in-memory library and the selection unchanged, and shows the error. (A,B)
   - With the saved repo id changed in the `ivan.varhop` entry only (jq, temp+rename, every other byte identical), Ctrl+R gets `identity-mismatch`. The overlay shows the reconfirm prompt and saves nothing until it is confirmed. (A,B,C)
3. Settings (live unless marked):
   - Ctrl+, toggles settings. Esc returns to the view it came from.
   - Settings shows the gh login and scopes from `status`, and the last successful pull time.
   - Component check: a logged-out `status` renders the `gh auth login` fix. A failed pull renders its error. Load errors merge repo-sync errors without lines and prompt-core errors with lines. (A,C)
   - In settings text fields, Ctrl+V and Ctrl+Shift+V paste, and Ctrl+C and Ctrl+Shift+C copy the field's selection. (A,B)
   - The chord field warns for SUPER+CTRL+P, shows a ready line for SUPER+ALT+P, and refuses characters outside the chord vocabulary.
4. Search (live, on a synthetic `library.json` written with the saved repo id, then Ctrl+R to restore the real one):
   - Typing selects the expected top prompt. Query edits reset to the top. Up and Down wrap. Enter opens the editor with the first stop selected. (A,B,C)
   - Rows show the title, then the category path and description, plus the file name when the title does not identify the file, and a Draft marker on a prompt with a draft. A body-only hit shows a one-line snippet. (A,B,C)
   - With a draft, a pinned "Resume draft" row shows above the results with its chord. Component check: clicking it resumes. Clicking a result row opens it. (A,B,C)
   - After Ctrl+R the selected prompt stays selected by id, or the top row is selected when its id is gone. (A,B,C)
   - The first Esc clears a non-empty query, and Esc on an empty query hides.
   - In the search field, Ctrl+V and Ctrl+Shift+V paste, and Ctrl+C and Ctrl+Shift+C copy the field's selection without exporting a prompt. (A,B)
   - Latency: at 500, 2000 and 5000 prompts, half of them with 20 KB bodies, 200 keystrokes each, p95 ≤ 50 ms from the key event to the first frame showing the updated results. Any slower size fails. (A,B,C)
5. Editor (live unless marked):
   - Tab and Shift+Tab walk the unique names with wrap. A typed value mirrors to every occurrence. A zero-variable prompt opens ready and copies. (A,C)
   - Typing, Backspace, Delete and paste in prose leave the prose unchanged. Enter in a value inserts a newline, and a multiline value copies intact. (A,B,C)
   - Delete on a selected value empties it, and Delete again restores unset `{{NAME}}`. Per-variable undo and redo step through edits and that reset, and mirrors follow. (A,B,C)
   - Paste into a value by Ctrl+V and Ctrl+Shift+V lands as literal text. Component check: right-click menu paste lands in the value, clicking a mirror makes it the active value, and the next Tab goes to the next unique name. (A,B,C)
   - `č` sent through `hl.dsp.send_key_state` (the fcitx5 path) lands in a value. Before copying, the copy calls `Qt.inputMethod.commit()` (proofs-overlay.md row 17). (A,B,C)
   - Hide, then summon, resumes the draft with the exact cursor and selection. (A,B,C)
6. Copy (live unless marked):
   - Ctrl+C and Ctrl+Shift+C put exactly the rebuilt text on the clipboard (`wl-paste` byte compare), end the draft, then hide. Unset names copy as `{{NAME}}`, with the count shown. An all-empty prompt copies an empty string as a valid copy. (A,B)
   - With varhop focused over a browser and over a terminal-tagged window, the agent sends the key-state sequence the Super+C/V binds send (clipboard.lua:8-47) through `hyprctl dispatch`. Paste lands in the focused value or search field, and copy exports the prompt from the editor (operator 1a). (A,B)
   - `Copier.qml` run by `quickshell -p` with its command set to `false`, a missing binary, and `sleep 10` past its timeout reports a failure each time (proofs-overlay.md row 21). Component check: a reported copy failure keeps the draft and shows the error. (A,B)
7. Draft and navigation (live):
   - Ctrl+P returns to the previous query and selection. Ctrl+Shift+P resumes and does nothing without a draft.
   - Ctrl+R pulls in every view and leaves the draft unchanged. Inside the picker's text fields it is inert. (A,B)
   - Switching the repo with a draft warns, and discards the draft only after a successful import. A failed switch keeps it.
8. Usage (live): a successful copy moves that prompt into the empty-query recent list. "Reset usage for this repository" clears only that repo's entries. A usage write failure and a malformed usage file are shown, and the file is never reset silently. (A,B)
9. Plain text (component check): a prompt title, description, body, repo name and error containing `<b>x</b>` and `<img src="http://127.0.0.1:9/x">` render as literal text, and no request is made. (A,B)
10. Lifecycle (live): disable then enable leads to the picker on the next summon. `omarchy plugin remove ivan.varhop --yes` leaves exactly the README-listed paths.
