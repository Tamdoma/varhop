# look

## Question
Q1. Font (F2): which family and sizes should the overlay use? Today every text sets a hard-coded `font.pixelSize` 11-14 and no family. Omarchy exposes `Style.font` size tokens and `menuFamily` (/usr/share/omarchy/shell/Commons/Style.qml:323-340). The Emojis overlay uses `Style.font.menuFamily` (renders monospace) and tokens heading/display/title. Operator shell.toml sets `[font] base-size = 12`.
Q2. Theme (F3): which tokens should colors, border, radius and card size come from? Varhop reads global `Commons.Color.foreground/muted/accent` plus `menu.selectedBackground/selectedText/border`, a fixed radius 6, a 1px border and a fixed 560x480 card (Varhop.qml:62-70, :770-780). Emojis reads only `Commons.Color.menu.*` (text, border via `Border.surfaceSpec("menu", ...)`, scrim, selected*), `Style.cornerRadius`, `Style.spacing.*` and a `Style.space(...)` card (/usr/share/omarchy/shell/plugins/emojis/Emojis.qml:27-44).
Q3. Transparency (F4): the operator says the panel is opaque "not transparent like the operator's other Omarchy surfaces". Measured: the Emojis overlay is also opaque with the same background (screenshots below). The operator's translucency comes from Hyprland window opacity 0.93 (hypr/terminal-opacity.lua:1), which does not apply to shell layer surfaces. `Commons.Color.menu.background` composes `[menu] background-alpha` (default 1.0). Should varhop be translucent, and if so by which mechanism?

### Carries
- Merged map: slots/map-merged.md
- Disposal fork: forks/disposal.md
- Editor Taken: forks/editor.md (single PlainText text box with painted highlight pills; filled values keep a faint highlight; adjacent values render as touching pills, a look concern).
- Proof-bar Taken: every control Tab+Enter.

### Measurement 2026-10-13 (clears Fog)
- Command: `omarchy-shell shell summon ivan.varhop` then `grim -g "520,260 560x480"`, then `omarchy-shell shell toggle ivan.varhop`. Same for `omarchy.emojis` with `grim -g "600,250 400x500"`. Monitor HDMI-A-1 (2560x1600, scale 1.6). Shell pid 2419633 unchanged before and after. Both overlays closed after.
- Observed: forks/look-varhop.png (installed 0df6f48, editor view) and forks/look-emojis.png.
  - Both cards are opaque with the same dark-green background, so the background token is the theme's.
  - Varhop uses the Qt default sans family. Emojis uses the menu family, which renders monospace.
  - Varhop has a thin light-green border and radius 6. Emojis has the theme's multi-color border spec and the theme radius.
  - Varhop text sizes look close to Emojis' title and heading sizes. The difference people notice is the family and style.
- Limits: one theme (sage-terra), one monitor scale, still images only.

## Findings
Merged notes: slots/look-merged.md (rebuttals slots/look-rebuttal-B.md, slots/look-rebuttal-C.md).
- better-than-training · ImageMagick histograms of look-varhop.png and look-emojis.png, 2026-10-13 (C) · same #1F241E background. Varhop text is already theme colors. The border is one flat gradient stop.
- better-than-training · `fc-match monospace` / `fc-match sans`, 2026-10-13 (A,C) · the menu alias is JetBrainsMono Nerd Font, and varhop renders Liberation Sans.
- better-than-training · /usr/share/omarchy/shell/Commons/Style.qml:265-340 (A,B,C) · menuFamily, size tokens at base 12 equal today's 11-16.
- practitioner · Omarchy maintainers' Emojis.qml:25-44,176-184 and Clipboard.qml:26-40, 2026-10-13 (A,B,C) · the menu-surface recipe: menu tokens, Border.surfaceSpec plus BorderSurface, cornerRadius, Style.space card.
- practitioner · DHH, Omarchy manual "Fonts" learn.omacom.io/books/2/pages/94, 2026-10-13 (B) · the user picks one system font.
- better-than-training · Commons/Color.qml:101,171-175 (A,C) · menu.background composes [menu] background-alpha. User shell.toml overrides theme keys.
- better-than-training · active theme shell.toml [launcher] alpha 0.95, [menu] alpha 1.0, scrim 0.5 (A,C) · launcher tokens rejected (no shell reader). The scrim dims anything seen through the card.
- practitioner · Omarchy default/hypr/toggles/window-glassy.lua (C) · see-through shell surfaces use theme alpha plus a compositor blur layer rule.

## Taken
Operator 2026-10-13: `1a | 2a | 3a`.
- 1a: every text uses `Style.font.menuFamily` (alias binding) and Style.font tokens one step above today. Query, headings and editor body `heading`, titles and controls `title`, metadata and status `body`. Nothing essential below `body`. Heights derive from tokens. A component case at a larger base size shows no clipping.
- 2a: Emojis surface recipe. BorderSurface card with `menu.background` and `Border.surfaceSpec("menu","border",...)`, `Style.cornerRadius`, `menu.scrim`, `menu.text`, `menu.selected*`, `Style.spacing.*`, card `Style.space(560)` x `Style.space(480)` clamped by `Style.gapsOut`. muted, accent and urgent stay foundational. Colors and fonts are bound live, with no snapshot object. Done-criterion: under a contrasting test palette (menu.text differs from foreground), each open view adopts the new roles after a theme change. Adjacent pills get a paint-only inset.
- 3a: the card follows `menu.background` including its alpha. No varhop alpha code. A see-through look is the operator's own `[menu] background-alpha` in ~/.config/omarchy/shell.toml, outside the leaf. Successor proofs run at the theme value.
- Not taken: README blur, no_screen_share and no_anim layer-rule suggestions (C).
