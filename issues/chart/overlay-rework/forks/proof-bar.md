# Proof bar

## Question
Q1. Live checks no agent can perform on this machine: exact cursor and selection after hide and summon (OA2), paste and copy by Super+V/Super+C over a browser and a terminal (OA3), and any mouse click on the overlay (OA4; layer surfaces ignore synthetic clicks here). Do these stay merge-blocking done-criteria done by the operator, move to a post-merge operator checklist, or does a prerequisite deliver machinery that makes them agent-provable?
Q2. The repo-switch-with-draft success path (OA1) needs a second readable GitHub prompts repo under the gh login. Which repo, or does this check move off the merge gate?
Q3. Must every overlay control (rows, buttons, reset) also work from the keyboard, so mouse clicks are never the only path and OA4 becomes agent-provable?

### Carries
- disposal Taken (forks/disposal.md): successor `overlay-plugin` on 0df6f48, criterion-to-evidence table.
- Precedent: middle-click paste, dead keys, IME preedit moved to a one-time post-merge operator check (issues/chart/varhop/forks/variable-editing.md, handoff amendment operator 4a).
- Failed leaf evidence: archive/overlay-plugin/implementation/report.md (F15 rounds, OA1-OA4), archive/overlay-plugin/review-B.md (final OA list).
- Editor will be redesigned (F5), so OA2/OA3 editor halves test new code.

## Findings
Notes: slots/proof-bar-A.md, -B.md, -C.md. Merged: slots/proof-bar-merged.md. Rebuttals: slots/proof-bar-rebuttal-B.md, -C.md.
- Q1: A,C post-merge operator checklist for OA2/OA3 with component proofs before merge; B one attended pre-merge session (core workflow; diagnosis "delivery not code" unproven, review-B.md:455). C: the old lock asked for an agent key-state proof, not a physical one, so it does not require the operator inside the leaf. Machinery-first (ydotool) rejected by all as default.
- Physical MX Master 3S mouse and keyboard present now (hyprctl devices, B,C). uinput keyboard route never tried, python-evdev present, /dev/uinput ACL for ivan (C). Optional probe: Left, Shift+Left, Ctrl+V into the focused overlay; proves machinery only, not the redesigned editor (B).
- Q2: Tamdoma/varhop-prompts-b exists, private, id 1416586635, created 2026-10-13T06:46:10Z (C; A verified via gh api). Ownership and retention need operator confirmation (B,C).
- Q3: every mouse action also keyboard-activatable via the same action path (A,B,C); Tab+Enter path required, arrows optional (C); keyboard proof does not prove mouse delivery (B); mouse spot-check can ride the post-merge checklist (C).

## Taken
2026-10-13 operator: `1a | 2a | 3a | 4a`
- Q1 1a: OA2 (exact cursor/selection resume) and OA3 (physical Super+V/Super+C over browser and terminal) move to a one-time post-merge operator checklist on the installed merged build; their behavior is proven before merge at component level; a physical failure is filed as a seed. Foreclosed: pre-merge attended session (B's preference, recorded in Findings).
- Q2 2a: door runs the uinput keyboard probe now (Left, Shift+Left, Ctrl+V into the focused overlay); a pass promotes OA2/OA3 back to agent criteria on the final build. Result recorded below.
- Q3 3a: Tamdoma/varhop-prompts-b (id 1416586635) is a read-only, retained target in the successor grant until the successor merges; switch-success with draft discard stays an agent criterion; run ends switched back to Tamdoma/varhop-prompts with selection intact.
- Q4 4a: every mouse action is also reachable by Tab and activated by Enter (arrows optional), through the same action path; the editor's Tab cycle over variables is unchanged; reset isolation becomes an agent criterion via the keyboard route; a mouse spot-check rides the post-merge checklist.

### Probe 2a result (2026-10-13 10:25 CEST)
- Command: python3 + python-evdev `UInput` keyboard named `varhop-probe-kbd` (keys A B C X V LEFT LEFTSHIFT LEFTCTRL ESC), 1.5 s registration wait; `printf VHPROBE | wl-copy`; `omarchy-shell shell summon ivan.varhop`; sent a, b, c, Left, Shift+Left, x, Ctrl+V; `grim` screenshot; sent Esc, Esc.
- Identity: local user ivan, /dev/uinput via ACL `user:ivan:rw-`; no install, no sudo. Versions: Quickshell 0.3.2, Qt 6.12.0, plugin ivan.varhop at 0df6f48 (installed copy).
- Result: the search field read `axVHPROBEc`: Left moved the caret, Shift+Left selected `b`, `x` replaced the selection, Ctrl+V inserted the clipboard text. After Esc, Esc, `hyprctl layers` showed no varhop layer (hidden). PASS: a uinput keyboard delivers arrows, shift-selection and paste to the overlay layer surface on this host.
- Cleanup: virtual device closed; screenshot deleted (it showed other windows); clipboard cleared with `wl-copy --clear`. The pre-probe clipboard held no image/png at probe time (the 10:22 Quickshell crash had already emptied it), so there was nothing to restore. Deviation: the script restored an empty image/png offer before the clear.
- Limits: tested the search field of the current build, not the redesigned editor; did not test hide/summon cursor restore, Super+V/Super+C binds, or pointer clicks.
- Effect on Taken (operator 2a): OA2 (exact resume) and OA3 (Super+V/Super+C through the Hyprland binds) return to agent done-criteria on the final build, driven by a uinput keyboard. A physical-paste and mouse spot-check stays on the post-merge checklist.

### Handoff proofs (2026-10-13 12:01 CEST)
- Second repo read. Command: `env -u GH_TOKEN -u GITHUB_TOKEN git -c credential.helper= -c "credential.helper=!gh auth git-credential" clone --depth 1 https://github.com/Tamdoma/varhop-prompts-b.git`. Identity: gh keyring login ivanjuras. Versions: gh 2.102.0, git 2.56.0. Result: exit 0, head 5a334fa "Add starter prompt", files README.md and prompts/testing/second-repo.md. `gh api repos/Tamdoma/varhop-prompts-b` gives id 1416586635, private, default branch main, not archived. Cleanup: scratch clone deleted. Limits: does not prove varhop-sync's two-slot switch with a draft open, which stays a leaf criterion.
- Repoint of a plugin clone. Command on a scratch `git clone` of ~/.config/omarchy/plugins/ivan.varhop: `git remote set-url origin file:///home/ivan/.akrogon/worktrees/varhop/overlay-plugin; git fetch origin overlay-plugin; git reset --hard FETCH_HEAD`. Identity: local user ivan. Result: scratch HEAD 0df6f48, origin is the new URL. The installed clone's origin and clean status are unchanged. Cleanup: scratch deleted. Limits: a non-fast-forward target (rebased main) was not exercised. The shell only loads new code after omarchy-restart-shell (archive readiness proof rows 18-19).
