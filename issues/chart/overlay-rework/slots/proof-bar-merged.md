# Proof-bar merged notes (A, B, C), 2026-10-13

## Q1 OA2 exact resume, OA3 physical paste/copy, OA4 clicks
- Post-merge one-time operator checklist for OA2/OA3, component proofs before merge (A,C). Reason: same failure class as the 4a precedent (input delivery to a layer surface, not code); the redesigned editor gets tested once on the installed merged build. Cost: physical paste or resume could be broken on main until the checklist; failure becomes a seed.
- Keep OA2/OA3 pre-merge with one attended operator acceptance session on the final build (B). Reason: these are the core edit/paste workflow, the 4a precedent covered only middle-click, dead keys and IME; old lock settings-and-hotkey.md:59 kept browser/terminal key-state proof merge-blocking. Cost: operator must be present inside the leaf before merge.
- Machinery first via omarchy-dev-install-ydoo (rejected A,B,C as default): needs pkexec, input group, udev rule; its pointer half is the same uinput class that failed on the layer (report.md:191-194) (A,C).
- OA4 is removed by Q3 (keyboard path) as an agent criterion (A,B,C); keyboard proof does not prove mouse delivery (B).
- Evidence: a physical mouse MX Master 3S and keyboard now exist (`hyprctl devices`, B,C); archive claim "no physical pointer" is stale. /dev/uinput has an ivan ACL and python-evdev imports (C); an evdev KEYBOARD route was never tried, only an evdev mouse (C).
- Optional probe (C): uinput keyboard sending Left, Shift+Left, Ctrl+V to the focused overlay; if it works, OA2/OA3 become agent criteria. Types into the live desktop, so needs operator approval.

## Q2 OA1 second repo
- `Tamdoma/varhop-prompts-b` exists: private, id 1416586635, created 2026-10-13, holds prompts/testing/second-repo.md (C, gh api). Name it read-only and retained in the successor grant; keep switch-success as an agent criterion (B,C; A same shape with operator-named repo). Switch back to Tamdoma/varhop-prompts at the end, selection intact (B,C).
- Creating a repo rejected (A,B,C). Moving OA1 off the gate rejected unless no target (B,C).
- Open: who made varhop-prompts-b and may it be kept as a fixture (C). The confirm-reimport control is mouse-only today, so OA1 also depends on Q3 (C).

## Q3 keyboard-reachable controls
- Yes, binding: every mouse action also reachable and activatable by keyboard, via the same action path (A,B,C). Mouse-only today: SettingsBody repo rows, Sync now, confirm-reimport, copy-bind, Reset usage (C, SettingsBody.qml:179,233,248,362,386).
- Must not steal editor Tab cycle (A,B,C); prefer Tab+Enter since arrows were not delivered live (C); rows may use Up/Down/Enter (B).
- Q3 replaces only OA4's activation route; mouse acceptance stays a separate row (B).

## Where slots differ
- Q1: B pre-merge attended session vs A,C post-merge checklist.
- Q1: C proposes a keyboard-injection probe before deciding.
