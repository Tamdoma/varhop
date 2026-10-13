# W4 live sweep (head 323d3f2, base b210f39)

1. Preflight 2026-10-13T14:02:45+02:00: Hyprland 0.56.2, no hyprlock, /dev/uinput writable, installed plugin at b210f39 with origin file:///home/ivan/Work/omarchy-customizations/varhop, entry ivan.varhop repo Tamdoma/varhop-prompts repoId 1416196860.
2. Backup: folder absent before. Copied cache, state and entry to scratch/varhop-backup. sha256 in files.sha256 and shell.json.sha256.
3. Move the install: origin file:///home/ivan/.akrogon/worktrees/varhop/overlay-rework, reset to 323d3f2, restart. The shell crash-looped (6 SIGSEGV at 14:02). Install reset to b210f39 and restarted; ping ok. Cause: QV4 WeakMap.get on a collected key in lib/search.mjs (gdb). Fixed in fa71cf0 (test e0081df). Install moved to fa71cf0, restarted, stable. Smoke screenshot: implementation/w4-card-search.png.
4. Ctrl+Tab on fa71cf0: {"result":"pass","observed":"x"}.
5. OA2 on fa71cf0: pass, clipboard "Summarize the text below in three bullets for abcx.\n\n{{TEXT}}\n". Screenshot implementation/w4-oa2-editor.png. The copy recorded usage for summarize (the backup restores it).
6. OA3 not valid. Run 1: the focus dispatch used pre-Lua syntax and failed. Run 2 (hl.dsp.focus) over Chrome 0x55dbf2320c60: dispatch ok but activewindow stayed elsewhere. super+v pasted nothing, super+c copied the rebuilt prompt with {{AUDIENCE}} unset. Direct ctrl+v (no bind) into a Cold email value also pasted nothing. The values held "prije" and "dfsfs", text no run sent: the operator was typing in the session, and each summon takes the keyboard. A run killed by timeout (wl-copy held the stdout pipe) skipped the clipboard restore. The clipboard was restored by hand to the newest Omarchy history image (14:21:01, sha256 d820d283...).
   State left: install at fa71cf0, origin the leaf worktree, enabled. Shell holds a Cold email draft with stray text. Backup intact in scratch/varhop-backup. Steps 7-9 not run.

# Resume pass (head fa71cf0, base b210f39), 2026-10-13 14:52-14:58

Screens are now HDMI-A-1 at 0,0, DP-2 at 1600,0 and DP-1 at 3200,0 (logical). The overlay opens on the focused monitor, so card shots are taken at monitor x+520, y+260.
6. OA3 pass.
   - Direct check, no bind: `ctrl+v ctrl+c` into the Summarize AUDIENCE value gave `Summarize the text below in three bullets for PASTEDV.\n\n{{TEXT}}\n`.
   - Terminal: focus foot 0x55dbf25e5dd0 (`hl.dsp.focus({ window = "address:..." })`, active true, tags terminal*). Then summon and `ctrl+a backspace s u m m enter super+v super+c`. The clipboard matched the same bytes.
   - Browser: focus Chrome 0x55dbf2320c60 (active true, tags chromium-based-browser*). The same keys gave the same bytes.
   - The clipboard was restored after every run (withClipboardRestored byte compare).
7. OA1 pass.
   - Draft: Summarize with AUDIENCE `abc`. Ctrl+, then filter `varhop`, Down Down, Enter on Tamdoma/varhop-prompts-b showed "reconfirm: switching repos discards the current draft" and Confirm reimport. Shift+Tab, Enter confirmed. b was marked current and the last pull time changed.
   - Summon landed on search with no draft resumed (implementation/w4-oa1-draft-gone.png). `s e c o n d enter x ctrl+c` gave `This prompt comes from x.\n`, an exact match.
   - Switched back to Tamdoma/varhop-prompts (no warning, no draft). The shell.json entry is equal to the backup entry.json (jq -S diff).
8. Reset isolation pass. In settings, Tab (field, Sync now, hotkey) to Reset, then Enter.
   - usage-1416196860.json: a6cf11bb... → 8e84b251... content `{"version":1,"entries":{}}`.
   - usage-1416586635.json: b02459e2... unchanged.
9. Restore pass.
   - rsync --delete of backup cache/ and state/. `diff -r` equal, files.sha256 all match. shell.json sha256 dfa6df0d... equals the backup.
   - omarchy-restart-shell (unlocked), ping ok, no coredumps. Smoke summon showed the restored library. Esc hid it.
   - Backup deleted. Last step: `git remote set-url origin file:///home/ivan/Work/omarchy-customizations/varhop`, with no fetch. The install HEAD is fa71cf0 and enabled.

# check.fix pass (head 0be8ca4, base b210f39), 2026-10-13 21:15-

1. Preflight: no hyprlock, /dev/uinput writable, Hyprland 0.56.2, install at fa71cf0 with origin file:///home/ivan/Work/omarchy-customizations/varhop.
2. Backup to scratch/varhop-backup: cache, state (usage-1416196860.json only), entry.json, shell.json sha256 dfa6df0d..., files.sha256 (39 files).
3. Install moved: origin set to the leaf worktree, fetch overlay-rework, reset to 0be8ca4, omarchy-restart-shell (unlocked), ping ok.
4. Ctrl+Tab: `ctrl+tab space x` read field → {"result":"pass","observed":"x"}.
   B/F1 live: `s u tab esc m` read field → {"result":"pass","observed":"sum"}. Esc did not clear the query, so plain Tab reached the header and Esc returned to the query field.
5. OA2 runs 1-3 not valid. The overlay hid mid-run (12 of 30 key events unsent) and between calls. Cursor moves between probes (790,500 → 2038,688 → 2311,519) show the operator is active, and their clicks hide the overlay. One clipboard read returned the operator's own text (not recorded). Waiting for 2 idle minutes before rerunning.
   Idle: 120 s with no cursor or active-window change reached at 21:29 (watcher, 511 s).
5. OA2 pass (run 4, clean editor with AUDIENCE unset): `a b c d e f shift+left shift+left esc`, overlay hidden, summon, `shift+left x ctrl+c` → `Summarize the text below in three bullets for abcx.\n\n{{TEXT}}\n`.
   B/F2 live: wrapper saves the clipboard, seeds SENTINEL, summons and sends `ctrl+a backspace s u m m enter a b c ctrl+home shift+end shift+delete`. Clipboard read SENTINEL (pass). A follow-up `ctrl+c` gave `...for abc.\n\n{{TEXT}}\n`, so the prose stayed and the value was kept.
6. OA3 pass. Wrapper seeds PASTEDV, focuses the window (`hl.dsp.focus`), summons, `ctrl+a backspace s u m m enter super+v super+c`.
   - foot 0x55dbf275bec0 (terminal*): `...for PASTEDV.\n\n{{TEXT}}\n`.
   - google-chrome 0x55dbf1fe1ea0 (chromium-based-browser*): same bytes.
   - Focus returned to 0x55dbf275bec0.
7. OA1 pass. Draft Summarize AUDIENCE `abc`, Ctrl+, filter `varhop`, Down Down, Enter on Tamdoma/varhop-prompts-b showed "reconfirm: switching repos discards the current draft" and Confirm reimport. Shift+Tab, Enter: entry repo Tamdoma/varhop-prompts-b repoId 1416586635, last pull 19:24. Summon landed on search with no draft (implementation/w4-oa1-draft-gone.png). `s e c o n d enter x ctrl+c` → `This prompt comes from x.\n`. Switched back with Up, Enter: entry equal to backup entry.json (jq -S diff).
8. Reset isolation pass, and A/F1 live. With the filter cleared, the full 8-row list pushed Hotkey and Reset below the card. After `tab tab tab` the view scrolled and the focused Reset button was fully visible. Enter: usage-1416196860.json 39b61d07... → 8e84b251... `{"version":1,"entries":{}}`. usage-1416586635.json 9b76bb7f... unchanged. Screens showing the operator's repo list were deleted.
   One `esc` run's primary-selection restore failed its byte compare (operator selection or overlay Esc changed primary mid-run). The regular clipboard restores all passed.
9. Restore pass. rsync --delete of backup cache/ and state/, `diff -r` equal, files.sha256 all match, shell.json sha256 dfa6df0d... equal. omarchy-restart-shell (unlocked), ping ok, no quickshell coredumps. Smoke summon showed the restored library (implementation/w4-card-search.png). Backup deleted. Last step: origin set back to file:///home/ivan/Work/omarchy-customizations/varhop, no fetch. Install HEAD 0be8ca4, enabled.
   Screens that caught another monitor (private content) were deleted. w4-oa2-editor.png stays from fa71cf0.
