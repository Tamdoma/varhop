# Look fork, merged notes (A), 2026-10-13

Sources: look-A.md, look-B.md, look-C.md.

## Measured ground
- Both cards render the theme's opaque menu background #1F241E. Text pixels are already theme colors. Varhop's border is one flat color, the first stop of the theme's gradient (C, histogram). The remaining F2 and F3 gap is font family, border and radius (A,B,C).
- Fonts: the menu alias resolves to JetBrainsMono Nerd Font, while varhop falls back to the Qt default sans, Liberation Sans (A,C). Varhop sizes 11-16 already sit at the token values for base-size 12 (B,C).
- User ~/.config/omarchy/shell.toml keys override theme shell.toml keys (C, Color.qml:171-175 mergeShell, A verified).

## Q1 font
- Every text binds `Style.font.menuFamily` (the alias, not a resolved name) and a `Style.font` token. Row and field heights derive from tokens, following the Clipboard pattern (A,B,C).
- Sizes split:
  - B steps the main text up: query, headings and editor body `heading` 16, titles and controls `title` 14, metadata `body` 12. Nothing essential stays at 10-11 (B).
  - C snaps to the nearest token at today's pixels, so nothing grows today. If text still reads small, the operator either raises base-size globally or varhop moves one step up (C).
  - A mapped to today's sizes, with the editor body perhaps one step up (A).
- Rejected: Style.font.family (ignores OMARCHY_MENU_FONT), hard-coded pixels, a varhop size multiplier, a raise of global base-size as part of this leaf (A,B,C).
- Pitfalls: fonts bound by snapshot go stale, so pass them through bindings (B,C). Fixed heights clip at larger sizes, so add a component case at a larger base size (B,C). Monospace wraps earlier in the editor (A,B,C).

## Q2 theme
- Emojis recipe: card is a BorderSurface with `menu.background` and `Border.surfaceSpec("menu","border",menu.border,Math.max(1,Style.space(2)))`, radius `Style.cornerRadius`, scrim `menu.scrim`, text `menu.text`, selection `menu.selectedBackground/selectedText/selectedBorder`, padding `Style.spacing.*` (A,B,C).
- Card keeps the 560x480 footprint as `Style.space(560)` x `Style.space(480)`, clamped by `Style.gapsOut` (B,C, A said Style.space).
- muted, accent and urgent stay foundational (colors.toml) for secondary text, editor pills and errors (A,C). B keeps a semantic error color (B).
- Drop the `colors` snapshot object and its plain assignments. Bind through Qt.binding. Done-criterion: switch theme while each view is open, and the screenshot must change (B,C).
- Adjacent pills get a small paint-only inset where two names touch, checked with a `{{A}}{{B}}` screenshot case (B,C).
- Focus rings use Style focus tokens (C).

## Q3 transparency: split
- A: compose the card from `[launcher]` tokens (alpha 0.95 in this theme) via Commons.Color.composed (A).
- B: follow menu alpha (opaque here). If the operator wants translucency anyway, offer a varhop-only background alpha as an explicit choice (B).
- C: follow menu alpha in code. The operator's lever is `[menu] background-alpha` in user shell.toml, which makes all menu surfaces translucent together. Optionally, the README suggests a blur layer rule (C).
- Against launcher tokens: no shell code reads [launcher], and relabeling misdirects theme authors (C).
- Against a code alpha: it double-composes with a theme alpha below 1 and diverges from Emojis and Clipboard (C). It also fades text unless only the background alpha changes (B).
- Scrim: the card sits over menu.scrim at 0.5, so a translucent card shows a dimmed desktop, not the desktop itself (C).

## A after merge
A drops launcher tokens. Recommendation: varhop follows `menu.background` alpha (B,C). With operator approval, A adds `[menu] background-alpha = 0.95` to ~/.config/omarchy/shell.toml (the launcher's own value in this theme) and shows a screenshot. Emojis, Clipboard and Menu turn translucent too (C).

## Questions surfaced
- Bigger text or same size (B,C).
- Blur and no_screen_share layer-rule suggestion in the README (C). This widens scope, so it is offered to the operator, not assumed.
- Varhop's layer animates where first-party overlays do not (C). This is Hyprland user config, outside varhop's lock.

## Rebuttal corrections
- The measured differences are family, border and radius. Readability, menu text roles and live theme updates remain requirements (B rebuttal F1).
- Theme criterion: each open view adopts the new resolved roles under a contrasting test palette where menu.text differs from foreground. Any pixel change alone does not count (B rebuttal F2).
- A varhop-only background alpha that replaces the alpha does not double-compose. Its cost is overriding theme policy (B rebuttal F3).
- C did not reject a global base-size raise. C keeps it as the operator's own lever outside the leaf (C rebuttal 2).
- C wants sizes snapped to today first, with a step up only on the operator's word. The reasons: it isolates the family change from a size change, and heading 16 monospace wraps more (C rebuttal 1).
- C objects to A writing [menu] alpha during charting. At 0.95 over a 0.5 scrim the change is barely visible, and it would make successor proofs depend on a personal tweak (C rebuttal 3). A withdraws the step.
