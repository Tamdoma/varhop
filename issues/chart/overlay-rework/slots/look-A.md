# Look notes, slot A (blind), 2026-10-13

## Q1 font
Pick: every text binds `font.family: Style.font.menuFamily` and a `Style.font` size token (bodySmall 11, body 12, subtitle 13, title 14, heading 16 at base 12), replacing the hard-coded 11-14. Reason: menu-type first-party overlays (menu, clipboard, emojis, polkit, reminders) all use menuFamily (grep of /usr/share/omarchy/shell/plugins, 2026-10-13). The operator's monospace resolves to JetBrainsMono Nerd Font (`fc-match monospace`), and base-size 12 comes from ~/.config/omarchy/shell.toml. Tokens follow `omarchy font set` and base-size changes. Cost: monospace is wider, so a 560-wide card fits fewer characters per line. The editor body may want subtitle or title for reading.
Rejected: `Style.font.family` (ignores OMARCHY_MENU_FONT and is the bar's choice), bigger hard-coded sizes (still ignore base-size), and the Qt default sans (what F2 complains about).
Evidence: better-than-training · /usr/share/omarchy/shell/Commons/Style.qml:265-340 (fontFamily "monospace" alias, menuFontFamily, tokens) and plugin grep, read 2026-10-13.
Pitfall: the old tests compare pixel sizes. Criteria must name tokens, not pixels.

## Q2 theme
Pick: the Emojis/Clipboard surface contract. Card `Commons.Color.menu.background`, text `menu.text`, border `Border.surfaceSpec("menu", "border", ...)`, radius `Style.cornerRadius`, padding `Style.spacing.*`, card size from `Style.space(...)`, selection `menu.selectedBackground/selectedText`. Drop the `c(name, fallback)` hex fallbacks, because Commons.Color always supplies a value. Editor pills: active uses menu.selectedBackground with selectedBorder, filled uses accent at low alpha, unset uses muted at low alpha.
Rejected: keeping global foreground and muted for body text (a theme that styles [menu] would not reach varhop).
Evidence: Emojis.qml:20-44. Color.qml:101-107 composes menu tokens with alpha. The screenshot shows the same background but a different border and font.

## Q3 transparency
Pick: compose the card background from the theme's `[launcher]` tokens, `Commons.Color.composed("launcher.background", "launcher.background-alpha", Commons.Color.menu.background, 1.0)`. The active theme sets launcher alpha 0.95 (~/.local/state/omarchy/current/theme/shell.toml:154-171, "card at 0.95 to preserve the legacy translucency"). Varhop is a launcher-type overlay, so it gets the same translucency the theme gives the launcher and follows theme switches. Cost: no shell plugin reads [launcher] today, so Omarchy may rename it. composed() falls back to menu.background, so a rename returns varhop to opaque without breaking.
Rejected:
- Hard-coded alpha on menu.background (ignores the theme).
- Editing [menu] background-alpha in the operator's theme. It changes Emojis and Clipboard too, it lives outside the repo, and the generated shell.toml is rewritten on every theme switch.
- Staying opaque (F4 stays unfixed).
Evidence: Color.qml:73-76 composed(). Theme shell.toml [launcher] and [menu] sections. Hyprland 0.93 opacity applies to windows only (terminal-opacity.lua).
Pitfall: text over a translucent card loses contrast on bright wallpapers. 0.95 is the theme's own choice. The scrim stays menu.scrim.
