# Look fork notes, slot C (blind), 2026-10-13

I cannot view the two screenshots as images in this pane, so I measured
them: ImageMagick histograms of forks/look-varhop.png and
forks/look-emojis.png (2026-10-13). Both are dominated by the identical
pixel #1F241E (669004 of 688128 pixels in varhop's crop, 417164 of
512000 in Emojis'), which is the current theme's [menu] background
(~/.local/state/omarchy/current/theme/shell.toml [menu] background,
background-alpha 1.0). Varhop's second color is #C3D1A8 (7192 pixels,
its flat border), the first stop of the theme's border gradient
"#C3D1A8 #E58B64 45deg" flattened to one color. Text pixels #E8DFC9 and
#A3B18A match the theme's foreground and accent. So the measured F3
residue is font family, border treatment and radius, exactly as the
fork's Measurement section says, not the background or text colors.

## Q1. Font family and sizes

### Pick
`Style.font.menuFamily` for every text in every view, bound as the alias
string (not a resolved family name), and sizes snapped to the nearest
`Style.font` token at today's pixels: query field heading (16), editor
canvas and search row titles title (14), text fields subtitle (13),
labels and body text body (12), detail, snippet, footer and error lines
bodySmall (11), the Draft marker caption (10). Heights stop being
constants: row and field heights derive from the tokens they contain,
the way Clipboard derives rowHeight from body plus caption plus padding
(/usr/share/omarchy/shell/plugins/clipboard/Clipboard.qml:40).

Reasons. menuFamily is Omarchy's definition of "the font summoned
popups use": Style.qml:315-320 resolves it from OMARCHY_MENU_FONT or
the shared fontconfig alias, and the comment at Style.qml:267-275 warns
to bind the alias so `omarchy font set` keeps working. On this machine
the alias resolves to JetBrainsMono Nerd Font (`fc-match monospace`,
2026-10-13), while varhop today falls back to the Qt default sans,
Liberation Sans (`fc-match sans`). That family swap is the visible F2
fix: the Measurement found varhop's sizes already sit near Emojis'
title and heading, and at base-size 12 the tokens reproduce today's
11-14px almost exactly (Style.qml:329-335), so snapping changes no size
today but makes every size follow `[font] base-size` and per-token
theme overrides tomorrow. One family in canvas and field also keeps the
editor prototype's pill geometry and caret metrics single-sourced
(editor Taken, prototype binding on one TextArea). A monospace canvas
additionally keeps code fences and indented prompt text aligned, which
a proportional family would not.

Cost: snapped tokens do not make anything bigger at base-size 12. If
the operator's "too small" meant literally bigger after the family
change, the remaining lever is global (raise base-size in user
shell.toml, every shell surface grows) or a one-step-up mapping in
varhop. This pick does not silently choose either; it makes the global
lever work and leaves the step-up as a stated option below.

### Rejected options
- Keep the Qt default sans for long prose, tokens only for chrome.
  Proportional text is easier on paragraphs, but it splits the product
  from every other summoned Omarchy surface, which is the complaint in
  F2 and F3, and it aligns code fences and token ranges on a different
  metric than the fields around them. Two families is also two places
  for the next theme mismatch to hide.
- `Style.font.family` instead of menuFamily. Identical today (both
  resolve to the monospace alias), but it ignores the user's
  OMARCHY_MENU_FONT override that menu, polkit, emojis and clipboard
  all honor (Style.qml:315-317 comment). Varhop is a summoned popup;
  it should follow the popup setting.
- Keep hard-coded pixels but add the family. Fixes half of F2 and
  leaves every size frozen at base-size 12 values; the first time the
  operator raises base-size, varhop becomes the one surface that did
  not grow, and fixed 26 to 44px row and field heights start clipping.
- Varhop-only size multiplier. Makes text bigger locally, composes
  unpredictably with token overrides, and re-creates "does not follow
  Omarchy font settings" with extra steps.

### Evidence
- practitioner · Omarchy shell maintainers' first-party overlays, read
  2026-10-13 · Emojis.qml:35 binds `Style.font.menuFamily` and sizes its
  header by Style.font.title (Emojis.qml:37); Clipboard.qml:34, :40,
  :439, :506 does the same with heading and title. This is the shipped
  pattern for exactly varhop's surface kind.
- better-than-training · /usr/share/omarchy/shell/Commons/Style.qml:
  267-275, 315-340 and ~/.config/omarchy/shell.toml, read 2026-10-13 ·
  alias binding rule, token values at base-size 12, user base-size 12.
  Sizes snap cleanly, no size change today.
- better-than-training · `fc-match monospace` and `fc-match sans`,
  2026-10-13 · menu alias is JetBrainsMono Nerd Font, Qt default is
  Liberation Sans. Names the actual rendered difference in the
  screenshots.
- better-than-training · histogram measurement above · varhop text
  pixels are already theme colors, so F2's residue is family, not
  palette.

### Pitfalls and what removes each
- Font values snapshotted into views the way colors are today
  (`item.colors = root.colors` plain assignments), so a font or theme
  change while open leaves stale text. Removed by passing family and
  sizes through Qt.binding from root properties bound to Style, and a
  done-criterion that switches theme while the overlay is open (carried
  from the maps; the uinput route plus theme switch is agent-runnable).
- Token sizes grow under fixed heights and text clips at larger
  base-size. Removed by deriving heights from tokens now (this pick),
  plus one component case rendered at a forced larger base size or
  explicit token sizes, asserting no clipped row text.
- Monospace at title size shows fewer characters per editor line than
  the current sans did, so long prompts wrap earlier. Accepted cost of
  the family; bounded by the card width choice in Q2, and the editor
  prototype already ran at card size, though not at the final font.

### Questions the fork does not ask
- If text still reads small after the family swap, does the operator
  want base-size raised globally, or varhop one token step up? The fork
  should ask with a screenshot pair, since measurement says sizes are
  already at first-party values.
- Bold: section headers are bold 14 today, first-party surfaces lean on
  size and color instead. Keep bold anywhere, and if so where?
- Icon glyphs for the coming back and settings controls (controls
  fork): JetBrainsMono Nerd Font carries them, a future menuFamily
  override might not. Words, glyphs, or both?

## Q2. Which tokens for colors, border, radius and card size?

### Pick
Copy the Emojis surface recipe whole. Card becomes a qs.Ui
BorderSurface with color `Commons.Color.menu.background` and
`borderSpec: Border.surfaceSpec("menu", "border", menu.border,
Math.max(1, Style.space(2)))` (Emojis.qml:30, :176-183), radius
`Style.cornerRadius`, scrim `menu.scrim`, primary text `menu.text`,
selection `menu.selectedBackground`, `menu.selectedText` and
`menu.selectedBorder`. Size becomes `Style.space(560)` by
`Style.space(480)` capped at panel minus `Style.gapsOut * 2`
(Emojis.qml:39-40 pattern), content margin
`Style.spacing.panelPadding`. The three semantic colors [menu] does not
have stay foundational: muted, accent and urgent from `Commons.Color`
(colors.toml layer, Color.qml:20-23), used only where they are already
used (secondary text, editor pills, errors). Editor pills per editor
Taken: unset muted, filled faint accent, active strongest, all derived
with alpha from those tokens, never hex. Focus rings for the new
Tab+Enter controls come from Style's control tokens
(`Style.focusBorderColor`, `Style.focusBorderWidth`, Style.qml:199 and
:82), computed at the root and bound into the views as flat values.

Reasons. The measurement shows the background was never wrong (same
#1F241E dominant in both crops) and neither was the text color:
sage-terra sets [menu] text and colors.toml foreground to the same
#E8DFC9, so varhop's `Commons.Color.foreground` (Varhop.qml:64) passes
today by coincidence. A theme that separates them exposes it, which is
why first-party menu surfaces read menu.text (Emojis.qml:28 with the
comment at :25-26, "themes that style the menu also style emojis").
The border is the one measured mismatch: varhop paints flat #C3D1A8,
the gradient's first stop, because `Commons.Color.menu.border` composes
a single flat color, while Border.surfaceSpec carries color, gradient
and per-side widths from shell.toml (Border.qml surfaceSpec) and
BorderSurface renders the gradient path when needed
(Ui/BorderSurface.qml:25-37). Radius 6 hard-coded ignores
Style.cornerRadius, which mirrors Hyprland's decoration:rounding
(Style.qml:13, :33) and is why the varhop card's corners differ from
Emojis' in the screenshots. Style.space() card dimensions scale with
spacing and font (Style.qml:210-221), so the card grows with the Q1
sizes instead of squeezing them.

Cost: the card now depends on qs.Ui's BorderSurface at the root. That
is root-only code, so the Quickshell-free views and their component
tests are untouched, but it is one more first-party component whose
contract Omarchy can change under the plugin. Snapshotting must die
with this change: root properties bound to Commons tokens, Qt.binding
into loaders, replacing the colors object at Varhop.qml:63-71 and its
three plain assignments.

### Rejected options
- Keep global foreground, muted, accent as the main palette. Works on
  sage-terra by the measured coincidence, fails on any theme that
  styles [menu] separately from colors.toml, which is the dimension
  themes are explicitly invited to tune ("Clipboard and emojis inherit
  these tokens", theme shell.toml [menu] comment).
- Keep the flat border color and 1px width. Permanently flattens the
  theme's border gradient and width; it is the visible difference in
  the two crops.
- Keep fixed 560x480 and radius 6. Radius stops following Hyprland
  rounding, card stops following spacing and font scale, and Q1's
  derived heights eventually fill a fixed card and force scrolling
  changes.
- All-menu purity: drop muted and urgent by deriving them from
  menu.text with alpha. Loses the theme author's one muted and one
  error color, which colors.toml carries deliberately (Color.qml
  header comment), and makes errors a shade of text instead of the
  theme's red.

### Evidence
- practitioner · Emojis.qml:25-44 and :176-183, Clipboard.qml:26-40,
  read 2026-10-13 · the shipped menu-surface recipe: menu tokens,
  Border.surfaceSpec plus BorderSurface, cornerRadius, Style.space
  card, spacing tokens.
- better-than-training · Commons/Border.qml (surfaceSpec, controlSpec)
  and Ui/BorderSurface.qml:25-37, read 2026-10-13 · specs carry
  gradient and widths; the surface chooses native or overlay rendering.
- better-than-training · Commons/Style.qml:13, :33, :79-94, :193-200,
  :210-221, read 2026-10-13 · cornerRadius mirrors Hyprland rounding,
  control focus tokens exist, space() scales with spacing and font.
- better-than-training · histogram measurement above and theme files,
  2026-10-13 · background identical, border is a flattened gradient
  stop, menu.text equals foreground only in this theme.

### Pitfalls and what removes each
- Binding through the old snapshot object survives the rewrite in one
  of the three loaders. Removed by one done-criterion: with the
  overlay open on each view in turn, switch theme and read the new
  background and text pixel from a screenshot; all three views must
  change. Agent-runnable (summon plus grim, as the Measurement did).
- BorderSurface's overlay path draws outside the rectangle and could
  clip against the card's parent Item margins. Removed by mirroring
  Emojis' structure (BorderSurface as the card itself with padding),
  already proven in the same shell.
- Pills for adjacent values touching, flagged in the editor prototype.
  Removed here, as look work: inset each line-run rectangle by a
  Style.space(1) class gap on the sides where another run of a
  different name touches, and give pills a small radius from
  Style.cornerRadius capped small, recorded as a leaf done-criterion
  with a `{{A}}{{B}}` screenshot case.
- Selected row vs active pill vs focus ring all reading as the same
  highlight. Bounded by token choice above (menu.selected for rows and
  active pill, Style.focus for control rings); a screenshot case with
  all three visible belongs to the controls fork's proofs.

### Questions the fork does not ask
- Varhop's layer namespace is "varhop" (Varhop.qml:746), absent from
  Omarchy's hypr layer-rule lists (omarchy-shell.lua names
  omarchy-emojis, omarchy-clipboard and siblings for no_anim). So the
  varhop surface animates on open where first-party overlays are
  instant. Should the README suggest a user layer rule for the
  namespace, as it already suggests the bind line? (Varhop never writes
  Hyprland config, locked.)
- Field text selection colors: fields currently take selectedBackground
  as selection color. [controls] has a selection fill token
  (selection-fill-alpha in theme shell.toml) with Style helpers. Fields
  follow menu.selected or controls selection?
- Scrollbars: when search or editor content overflows, themed or
  invisible? First-party overlays largely hide them; nobody has stated
  varhop's.

## Q3. Should varhop be translucent, and by which mechanism?

### Pick
No varhop-specific translucency in code. The card keeps
`Commons.Color.menu.background`, which already composes the theme's
[menu] background-alpha (Color.qml:101). If the operator wants
see-through menu surfaces, the lever is theirs and global: set
`[menu] background-alpha` below 1 in ~/.config/omarchy/shell.toml,
whose user values override the theme's (Color.qml mergeShell, user
keys win), and Emojis, Clipboard, Menu and varhop become translucent
together. For blur behind a see-through card, the README can suggest
adding the "varhop" namespace to a glassy-style Hyprland layer rule
(blur with ignore_alpha) in the user's own Hyprland config, the same
pattern Omarchy ships for its own surfaces in
default/hypr/toggles/window-glassy.lua. Varhop writes no Hyprland
config (locked), so this is a documented suggestion, like the bind
line.

Reasons. The premise of F4 is measured wrong: Emojis is pixel-identical
opaque #1F241E under this theme. The operator's translucent surfaces
are Hyprland *windows* at 0.93 (~/.config/hypr/terminal-opacity.lua:1),
and window rules do not reach layer-shell surfaces. The same file also
records the operator's own rule that the compositor must not fade text:
terminal translucency is applied by each terminal to its background
only, "so glyph colors remain exact". A varhop-only alpha would make
varhop the one menu surface that disagrees with its siblings in the
next side-by-side screenshot, re-opening F3's complaint in reverse.
It would also show little: the card sits on the menu.scrim at alpha
0.5 (theme [menu] scrim-alpha), so a 0.93 card mostly blends toward
scrim color, not toward the desktop the operator is picturing.

Cost: F4 closes as "not a varhop bug". If the operator genuinely wants
this one overlay glassy while other menus stay solid, this pick says
no, and that preference has to be stated against the sibling-consistency
argument.

### Rejected options
- Multiply the card color's alpha in code (about 0.93 to match
  windows). Double-composes the day any theme sets background-alpha
  below 1 (0.8 becomes about 0.74), diverges from Emojis and Clipboard
  on the same theme, and bakes one operator's current window opacity
  into shipped code.
- Hyprland layer rule setting opacity on the "varhop" namespace. Fades
  the whole surface including glyphs, against the operator's own
  text-crisp rule quoted above, and lives in user Hyprland config that
  varhop is locked out of writing. As a personal user tweak it works;
  as a shipped mechanism it does not exist.
- Read [launcher] tokens instead (background-alpha 0.95 in this
  theme). Commons.Color exposes no launcher object (checked in the map
  phase), and relabeling the surface misdirects theme authors who
  style [menu] expecting clipboard-class surfaces to follow.
- Ship blur from inside the plugin. There is nothing to ship: backdrop
  blur is a compositor layer rule (window-glassy.lua pattern), not
  something a layer surface requests for itself.

### Evidence
- better-than-training · histogram measurement above and theme
  shell.toml [menu], 2026-10-13 · both overlays render the theme's
  opaque menu background; alpha 1.0 is what this theme asks for.
- better-than-training · ~/.config/hypr/terminal-opacity.lua:1 and its
  comment, read 2026-10-13 · 0.93 is a window rule, and it deliberately
  keeps glyph colors exact by making terminals draw their own
  translucency.
- practitioner · Omarchy's glassy toggles, default/hypr/toggles/
  window-glassy.lua and bar-glassy.lua, read 2026-10-13 · the shipped
  recipe for see-through shell surfaces is surface alpha from the
  theme plus an hl.layer_rule blur with ignore_alpha 0.3 over named
  namespaces. Varhop's namespace is absent from those lists, hence the
  README suggestion.
- better-than-training · Commons/Color.qml:101 and mergeShell, read
  2026-10-13 · menu.background already composes background-alpha, and
  user shell.toml keys override theme keys. The global lever needs no
  code.

### Pitfalls and what removes each
- Operator lowers [menu] alpha globally, then blames varhop when
  Emojis goes translucent too. Removed by saying in the round and the
  README, in one line, that the alpha lever is shell-wide for all menu
  surfaces.
- Translucent card over a bright desktop drops text contrast below
  what the theme promised. Bounded by the scrim (0.5) under the card
  and by the operator choosing the alpha; the successor leaf's look
  screenshots should include one capture at a lowered alpha if the
  operator takes that lever before handoff.
- The glassy blur rule with ignore_alpha interacts with pill
  highlights (translucent rectangles inside the surface do not affect
  backdrop blur, which keys off the surface's own alpha). No action;
  stated so nobody designs pills expecting blur inside the card.

### Questions the fork does not ask
- Privacy on screen share: Omarchy marks some namespaces
  no_screen_share (screenshot-selection.lua pattern). Prompts can hold
  sensitive text; should the README's suggested layer rule for
  "varhop" include no_screen_share alongside blur and no_anim?
- If the operator does set [menu] background-alpha below 1, is that a
  leaf input (successor proofs run at that alpha) or a personal tweak
  outside the leaf's evidence?
