# Proof-bar notes, slot A

## Q1 physical-only checks (OA2 cursor resume, OA3 Super+V/C over browser/terminal, OA4 clicks)
Pick: move them to a one-time post-merge operator checklist, same as the 4a precedent; agent-provable halves stay done-criteria (component tests under real Wayland for paste chords, selection restore via draft state, keyboard activation of controls). Reason: the old leaf died on exactly these; keeping them as merge gates repeats that failure unless the operator is scheduled inside the leaf. Cost: a bug in physical paste or click lands on main and is found by the operator after merge; it becomes a seed.
Rejected: keep as merge gates (needs the operator inside each fix round; one more fail-on-hands loop). Build machinery first: Omarchy ships `omarchy-dev-install-ydoo` ("Install and enable ydotool mouse automation for Omarchy development", /usr/share/omarchy/bin/omarchy-dev-install-ydoo:3), but the old leaf already registered a uinput virtual mouse via python-evdev (same kernel path) and five directed clicks never fired a MouseArea on the layer surface (archive report.md third round, I2). So ydotool is unlikely to help clicks; unknown cause. Low confidence on root cause.
Note: operator's own live test selected a repo by clicking a row (seed F1), so real clicks do work; only injection fails.
Pitfall: post-merge checklist forgotten -> door records it as a Pending step with owner operator and exact steps, and the seed close waits for it? No: seed #1 closes on F1-F7 delivery; the checklist is separate.

## Q2 second repo (OA1)
Pick: operator names one existing second repo the gh login can read (no creation), recorded in the successor's grant read-only; the switch-with-draft success stays agent-provable. Alternative: move to post-merge. Cost: a grant entry.
Rejected: door creates a throwaway repo (new write grant, cleanup obligations, for one check).

## Q3 keyboard-reachable controls
Pick: yes, every control also works from the keyboard (focusable button with Enter/Space, Omarchy Ui/Button.qml has this per map-B). Makes OA4 and all new Back/Settings buttons agent-provable and helps the keyboard-first operator. Cost: focus order must not steal Tab from the editor's variable cycle.
