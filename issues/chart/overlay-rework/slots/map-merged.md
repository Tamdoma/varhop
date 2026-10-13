# Merged opening map (A, B, C), 2026-10-13

## Facts all slots found
- Leaf failed on proof, not on a code defect: failed/blocked at check.fix after 4 fix rounds, reason OA1-OA4; last B re-check found no open product defect, check 77 pass (A,B,C).
- Branch overlay-plugin 0df6f48 holds the whole plugin (33 commits, 19 files, ~3300 lines) plus latency fixes in lib/search.mjs and lib/import.mjs needed for p95 50 ms at 5000 prompts (B,C).
- akrogon has no abandon/remove verb. Recovery = `akrogon phase overlay-plugin <phase>` without --slot, keeps fix_rounds (B,C). `park` moves the whole issues/open/varhop folder and refuses a leaf with tab/worktree (B,C). `close` is for GitHub sources only (B,C). A new leaf whose slug equals an existing branch adopts that branch (akrogon src/next.ts:325-333) (A).
- The plugin is currently installed and bound to Super+Alt+P (~/.config/hypr/bindings.lua:12) (C).
- F5 is structural: editor is a Column + Repeater, one row per segment (qml/EditorBody.qml:255-380) (A,B,C). It does not reopen chart locks: variable-editing left the mechanism to leaf design; values-only, unique-name Tab, mirrors, Delete reset, rebuild-from-source stay (B,C). Frozen tests address value<i>/mirror<j> (C).
- F1 structural: Repeater over root.repos, no filter (SettingsBody.qml:219) (A,B,C).
- F2: no font.family, hard-coded pixel sizes; Style.font tokens and menuFamily exist (Style.qml:323-335) (A,B,C). At base-size 12 tokens are not bigger than current sizes, so "too small" needs a size choice, not only tokens (C).
- F3: colors passed to views as a one-time snapshot (`item.colors = root.colors`, Varhop.qml:821/863/898), with hex fallbacks; root uses Color.foreground where first-party menus use Color.menu.text (B,C). Rendered cause unverified (A,B,C).
- F4: card uses Color.menu.background, same as Emojis/Clipboard; operator theme sets [menu] background-alpha 1.0, so opaque is what the theme asks for (A,C). Operator's translucent surfaces are Hyprland window opacity 0.93 (hypr/terminal-opacity.lua:1), which does not reach layer surfaces (A).
- F7 is a missed lock: settings-and-hotkey Taken says "Ctrl+, or a visible button" (C).
- OA4 exists only because Reset usage is a MouseArea; a keyboard-reachable control makes it agent-provable (B,C).

## Forks (order)
1. Disposal of the failed leaf and what "removed" means (A,B,C). Options: retire leaf, keep code as base (A,C lean); recover same leaf with revised contract (B listed, C: frozen tests fight F5); retire leaf and code, rebuild from main (all: largest cost, drops latency fix); drop the overlay product (all: abandons destination).
2. Proof bar for physical-only checks OA1-OA3 (A,B,C): keep as done-criteria / move to post-merge operator check (precedent 4a) (A,C lean) / build input machinery first (B listed).
3. Inline editor mechanism (A,B,C): one flowing TextEdit with guarded value ranges / read-only text + floating input / Flow of pieces (C: reflows Markdown) / whole-body editable (reopens lock).
4. Look: fonts size, theme binding, transparency (A,B,C). Needs a rendered-pixel comparison against Emojis first (C) — Fog until probed.
5. Picker filter and Enter semantics (A,B,C).
6. Visible back and settings controls: shared header vs per-view; keyboard-reachable (A,B,C).

## Pitfalls
- Old evidence lost on re-chart -> carry criterion-to-evidence table (B).
- Stale build tested -> verify deployed revision, restart shell (B,C).
- Theme snapshot -> bind every theme value, prove by switching theme open (B,C).
- Larger fonts clip fixed geometry -> derive heights from tokens (B,C).
- Mouse-only controls unprovable -> every control keyboard-reachable (A,B,C).
- Inline display as copy source -> keep rebuild from segments (B,C).
- Live runs share one desktop -> serialize live checks (B,C).
- Installed old plugin left bound after a removal decision -> explicit uninstall/update step (C).

## Split (provisional)
B: one completion owner (unmerged common base), internal areas U1 shell/picker/look, U2 inline editor, U3 final live acceptance. C: L1 look+nav, L2 picker, L3 inline editor, L4 proof close-out only if full bar kept; parallel branches conflict in SettingsBody/Varhop.qml. A: one leaf if branch reuse is chosen. Disagreement: one leaf vs several.
