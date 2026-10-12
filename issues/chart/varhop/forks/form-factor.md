# Form factor and install path

## Question
Q1. Is an Omarchy shell (Quickshell) overlay plugin the app, or a standalone Qt Quick app? The answer fixes how it opens, themes, installs and updates.

### Carries
- Operator: native Omarchy app, overlay above everything, theme inherited, "compatible with the ecosystem... something like Mise and Pacman" for updates (INTAKE.md).
- No other locks.

## Findings
- (A,B,C) Plugin pick. Emojis/clipboard are the same shape: /usr/share/omarchy/shell/plugins/emojis/manifest.json (overlay, keepLoaded), bound by `{ panel = ... }` (default/hypr/bindings/utilities.lua:3).
- (A,C) Install/update: `omarchy plugin add <git-url>`, `omarchy plugin update` (/usr/share/omarchy/bin/omarchy-plugin-add:120-137). B withdrew PKGBUILD-first for the plugin route.
- Third-party overlays are supported with a scoped shell (shell.qml:223,726-731). Proof still due: own-id hide/toggle and `{ panel = "ivan.varhop" }` binding.
- Shown overlay holds keyboard focus until hidden (OverlayWindow.qml:18,46); B: focus policy is a choice to prove (KeyboardPanel.qml:9-19).
- Full map and rebuttals: slots/map-merged.md, slots/rebuttal-B.md, slots/rebuttal-C.md.

## Taken
2026-10-12 operator: `1a | Note: also check why these overlays appear below everything on my Omarchy system and fix it if it's a small fix. This is after the update, and it's irritationg me. Even the super + space is showing below these windows most of the time.`

Taken: Omarchy shell overlay plugin, installed with `omarchy plugin add` and updated with `omarchy plugin update`. Foreclosed: standalone Qt app, PKGBUILD-first distribution, mise.

Carry: the operator reports existing Omarchy overlays (including Super+Space) render below windows since the last update. A varhop overlay depends on the same layering, so the cause is investigated and fixed here if small (a system-level side task outside the varhop leaves).

Finding (A, 2026-10-12, inspected on the operator's machine): first open of a shell overlay after the focused monitor changes lands on the Bottom layer (below windows); later opens on the same monitor land on Overlay. Reproduced with Super+Space via wtype on HDMI-A-1, DP-1, DP-2 (hyprctl layers: `level1 1600x1000` on first open per monitor, `level3` after). Cause: /usr/share/omarchy/shell/Ui/OverlayWindow.qml parks closed overlays on WlrLayer.Bottom and raises them on open while also switching `screen`. Upstream basecamp/omarchy commit 0a55a3c5 (2026-10-07, "Keep overlays sharp without parked surfaces") rewrites OverlayWindow.qml and adds overlay-monitor-test.sh; installed Omarchy f45461a is 111 commits behind it. Carry: a varhop overlay uses the same OverlayWindow, so the varhop shell leaf proves first-open layer on every monitor.

Finding (A, 2026-10-12): Qt 6.12 added a QtQuick `Color` type that shadows Omarchy's unqualified `Color` palette singleton; this is why the operator rolled back Qt on 2026-10-08 (session ~/.claude/projects/-home-ivan-Work/b899c323-d220-4eab-84ad-d93d4cf4df88.jsonl, rollback hold = `IgnorePkg` in /etc/pacman.conf line 4). Upstream: basecamp/omarchy #14553 (2026-10-08) qualifies palette references as `Commons.Color` and documents that third-party plugins need the explicit namespace; #14845 (2026-10-10) forces QtQuick imports to 6.11 in omarchy-pkgs. Carry: the varhop plugin imports `qs.Commons as Commons` and uses `Commons.Color`, and its proof runs on the operator's pinned Qt 6.11.2.

Update (A, 2026-10-12, after the operator's system update; raised by C2 slots/review-C2.md F1): installed omarchy-dev r6912.gdefbf90 already has the rewritten OverlayWindow.qml (fresh surface per open, no parked Bottom layer, :6-9) and Qt 6.12.0-2 with quickshell 0.3.2-4; `IgnorePkg` is gone. A re-tested Super+Space on HDMI-A-1, DP-1, DP-2: level 3 on each. Carries now: varhop uses `Commons.Color`; its leaf re-verifies first-open layer per monitor on current Omarchy/Qt 6.12 (not 6.11.2).
