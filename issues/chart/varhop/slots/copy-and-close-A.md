# copy-and-close: blind notes (slot A)

Read 2026-10-12. Tiers: [OP], [SRC], [DOC], [MK].

## Q1 What and how
Pick: copy the rebuilt body only (no title, no front matter) by running `wl-copy` with the text on stdin through a Quickshell `Process` (`stdinEnabled`, write, close), then hide. No auto-paste in v1. Reason: intake says "copy" and the user pastes into the target [OP INTAKE.md]; first-party copy is `printf %s <quoted> | wl-copy` (plugins/panels/tailscale/Service.qml:109, network/Panel.qml:495), but that puts the text in argv; stdin avoids argv size and process-list exposure. wl-copy forks and keeps serving after the overlay hides [MK]. Cost: one Process per copy; wl-copy must exist (Omarchy uses it everywhere).
Rejected:
- `Quickshell.clipboardText`. Wayland clipboard needs a live source; unclear if it survives the overlay surface unmapping without focus [MK, unproven]. Would need a proof.
- `omarchy-clipboard-paste-text`. Text in argv (:49-52) and pastes by default; `--copy-only` exists (:20) but still argv.
- Auto-paste (emoji style, plugins/emojis/Emojis.qml:152 → omarchy-menu-emoji-insert). Intake says copy and close; pasting into a terminal triggers Ctrl+Shift+V vs Shift+Insert differences. Offer later as a setting.

## Q2 Unset variables
Pick: copy anyway, with unset tokens as `{{NAME}}`; the footer shows "2 unfilled" before copying. Reason: partial prompts are valid; blocking adds a confirm step to the fastest path. Cost: an unfinished prompt can be pasted by mistake.

## Q3 Ctrl+C with a selection
Pick: Ctrl+C always copies the whole prompt and closes [OP]. Selection inside a value is not a copy source. Reason: the operator's spec is explicit and the value editor is the only editable area. Cost: copying part of a value needs a different route (none in v1).

## Q4 Esc, summon, lifetime
Pick: Esc in the editor goes back to search, draft kept for that prompt; Esc in search hides. Summon with a draft resumes the draft exactly (variable-editing 2a). Draft lives in memory only; shell reload or plugin update loses it. Reason: intake hide/resume is in-session; persistence adds a state file and a stale-draft rule. Cost: a theme change or shell restart mid-edit loses typed values.
Rejected: Esc discards the draft (loses work on a reflex key).

## Pitfalls
- P1 Clipboard history service captures prompts: acceptable, same as any copy.
- P2 Hide before wl-copy started: start copy, hide on Process start, not on exit.
- P3 Very large prompts: stdin has no argv limit.

## Questions not asked
- Q5 Should a second hotkey or Ctrl+Enter copy and also paste into the previous app?
