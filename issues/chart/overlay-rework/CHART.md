# Chart: overlay-rework

## Destination
The varhop overlay is pleasant for daily use: the picker filters as you type, fonts, colors and transparency follow Omarchy, variables stay inline in the prompt text, Back and Settings are visible, and the failed overlay-plugin leaf is retired with its tested code carried forward. Closes Tamdoma/varhop#1.

Route: lifecycle (debate no)

## Forks taken
- [disposal](forks/disposal.md): retire the failed leaf, archive it here, keep the installed copy, successor reuses slug `overlay-plugin` on the existing code.
- [proof-bar](forks/proof-bar.md): uinput keyboard probe passed, so cursor resume and Super+V/C paste are agent criteria on the final build; Tamdoma/varhop-prompts-b is the read-only second repo; every control works by Tab+Enter; physical paste and mouse spot-check go on a post-merge operator checklist.
- [editor](forks/editor.md): one guarded PlainText text box (prototype passed 23/23 plus a live uinput run), filled values keep a faint highlight, clicks edit the clicked copy in place.
- [look](forks/look.md): Omarchy menu font one size step up, Emojis surface recipe bound live, card follows the shared menu alpha (solid in this theme).
- [picker](forks/picker.md): substring filter in stable A-Z order, Enter takes the visible highlight, empty Enter does nothing, zero matches offer the typed lookup, picker is one Tab control with arrow rows.
- [controls](forks/controls.md): fixed top header with worded buttons and printed shortcuts, Ctrl+Tab reaches it from any view and Tab also in search and settings, settings shows Back or Close and no Settings button, a middle title names the view.
- [split](forks/split.md): two leaves under the new issue overlay-rework: overlay-plugin lands today's code plus a proven uinput helper, then overlay-rework (blocked-by it) does the five forks and carries Tamdoma/varhop#1.

## Open forks
- none

## Handoff choices
- Handoff review (operator 2026-10-13): `1a | 2a | 3a`. Two leaves as drafted, debate no, both live-change grants confirmed. Direct unavailable (direct: false).
- Seats (operator 2026-10-13): slot A is Claude Code with claude-opus-5-5, effort medium, with Opus 5.5 subagents at medium. Written at handoff as a `slots:` front-matter block `a: {harness: claude, model: claude-opus-5-5, effort: medium}` at the top of issues/open/overlay-rework/ISSUE.md (operator 1a after varhop closed), before any leaf state.yaml. Subagent model follows the seat through the `claude` harness template (CLAUDE_CODE_SUBAGENT_MODEL={model}, FORCE=1).

## Fog
- none

## Off route
- None yet.

## Pending steps
- Done 2026-10-13: old leaf folder copied to archive/overlay-plugin/ (43 files, diff -r clean), original removed, `akrogon status` shows no overlay-plugin line, old tab wK:t7 closed. Worktree and branch overlay-plugin at 0df6f48 kept for the successor.
- Waiting on each merge (overlay-plugin, then overlay-rework), owner: the door (or the operator if the door is closed). The leaf leaves origin set to the root (B,C). Move the installed clone to merged main and load it: `git -C ~/.config/omarchy/plugins/ivan.varhop remote set-url origin file:///home/ivan/Work/omarchy-customizations/varhop`, `git -C ~/.config/omarchy/plugins/ivan.varhop fetch origin main`, `git -C ~/.config/omarchy/plugins/ivan.varhop reset --hard FETCH_HEAD`, `omarchy-restart-shell`. Check: the clone HEAD equals main, `omarchy plugin update ivan.varhop --yes` reports up to date, summon shows the overlay, and the shell.json ivan.varhop entry is byte-identical to its value before the step.
Handed off 2026-10-13
