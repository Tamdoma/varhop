# Look fork: blind notes, Slot B

Read 2026-10-13. Read only Question, Carries and Measurement in look.md, and viewed both named screenshots. No other slot's look notes read. No overlays summoned or desktop settings changed. Recommendations below are choices for the operator, not settled decisions.

## Q1. Font family and sizes

### Pick, reason and cost

Use `Commons.Style.font.menuFamily` throughout. Use `heading` for the search query, screen headings and the new single prompt editor, `title` for primary result names, settings inputs and controls, and `body` for metadata, status and help. At the operator's base size 12 these are 16, 14 and 12 logical pixels. This explicitly makes the prompt editor and small secondary text larger while following Omarchy's font setting. Do not merely replace each literal with a same-sized token and call the small-font complaint fixed.

Cost: the menu family and larger editor text change wrapping and show less content at once. Derive field and row heights from text metrics plus the existing style padding, and allow the editor and long lists to scroll. Keep the selected single-text-box editing model.

### Rejected options

- Keep the default sans family or name a particular Nerd Font: either bypasses the user's menu font choice.
- Apply `display` everywhere or increase the user's global base size: neither follows from this plugin complaint, and the latter changes unrelated surfaces.
- Preserve 10–11 pixel essential labels for density: conflicts with F2. Reserve small tokens for genuinely optional decoration, if any.

### Evidence, tier, source and date

- **Operator**, `issues/chart/overlay-rework/INTAKE.md:25,46`, read 2026-10-13: text is too small and should follow Omarchy font settings. The size increase is my design recommendation, not a measured preferred size.
- **Practitioner**, DHH, creator of Omarchy, [Fonts in the Omarchy manual](https://learn.omacom.io/books/2/pages/94), read 2026-10-13: documents a user-chosen system/terminal font. This supports inheriting the user's choice. It does not establish this installed shell's precise token behavior.
- **Better-than-training**, `/usr/share/omarchy/shell/Commons/Style.qml:314-340`, `/usr/share/omarchy/shell/plugins/emojis/Emojis.qml:35,253-254`, and `/home/ivan/.config/omarchy/shell.toml:1-2`, read 2026-10-13: menu family has its own resolution, heading/title/body derive from base size, and Emojis consumes those values. The local source supplies the implementation-specific answer that the general manual cannot.
- **Better-than-training**, the supplied `forks/look-varhop.png` and `forks/look-emojis.png`, viewed 2026-10-13: the family difference is visible. Neither image proves a preferred larger size. Also, `qml/SearchBody.qml:109` already uses 16, so the question's “every text 11–14” is incomplete.

### Pitfalls and their removal

Font-size inheritance alone leaves fixed-height fields clipped. Leaf acceptance must cover search, editor and settings at base 12 and a larger base size, including scrolling to the focused control. Pass reactive font properties from the shell adapter into plain QtQuick views rather than coupling those views to shell imports. Do not multiply by monitor scale: use Style's logical sizes and normal Qt rendering. Recheck editor highlight geometry after font changes because the painted ranges must follow the actual text layout.

### Missing question

Does the operator want larger prompt text than today's editor, or only the native menu family and density? Recommend the concrete 16/14/12 mapping above so the answer settles readability, not just token names.

## Q2. Theme roles, border, radius and dimensions

### Pick, reason and cost

Use the menu surface consistently: `menu.text`, `menu.background`, `menu.scrim`, `menu.selectedBackground` and `menu.selectedText`. Use `Border.surfaceSpec("menu", "border", menu.border, Math.max(1, Style.space(2)))` with the installed `BorderSurface`, `Style.cornerRadius`, and the existing spacing tokens. Keep semantic error color for errors rather than forcing every state into the selection color.

Retain Varhop's 560 by 480 base footprint, expressed through `Style.space(560)` and `Style.space(480)` and clamped to the available panel dimensions with `Style.gapsOut`. Emojis supplies the styling mechanism, not the correct dimensions for a prompt editor. Account for border content insets and padding when sizing the content.

Keep filled variable highlights faint, unset values distinct and the active occurrence strongest, as the editor fork requires. Separate touching highlights through paint-only edge/inset treatment within the text ranges. Do not insert spaces, extra widgets or invisible characters into the prompt to produce a visual gap.

Cost: theme radius and gradient borders may look quite different from the current card. Larger fonts reduce visible rows. Very short adjacent values cannot always have generous visual spacing without changing text layout.

### Rejected options

- Replace the entire palette with hand-picked sage-terra colors: fixes one screenshot and fails the next theme.
- Keep a plain one-color Rectangle border and only change its color: discards gradient and per-side border data already supported by the host.
- Copy Emojis' 400 by 500 footprint: its grid is not evidence that prompt text needs that width.
- Rebuild the editor to separate pills: reopens a settled mechanism for a paint concern.

### Evidence, tier, source and date

- **Operator**, INTAKE F3 and the carried editor decision, read 2026-10-13: theme following and retained filled-value highlighting are required.
- **Practitioner context**, Omarchy's own team maintains the reference overlay in this same shell. Its shipped implementation is the directly relevant example. No separate practitioner claim establishes a universal correct card size.
- **Better-than-training**, `/usr/share/omarchy/shell/plugins/emojis/Emojis.qml:27-44,176-184`, `/usr/share/omarchy/shell/Commons/Border.qml:108-153`, and `/usr/share/omarchy/shell/Ui/BorderSurface.qml:1-39`, read 2026-10-13: the reference consumes menu roles and structured borders, and the surface exposes border-aware content insets. Reuse these facilities rather than duplicate their rules.
- **Better-than-training**, worktree `/home/ivan/.akrogon/worktrees/varhop/overlay-plugin/Varhop.qml:63-70,769-777,821,863,898`, read 2026-10-13: mixes global text roles with menu roles, fixes radius and border width, and assigns view colors during Loader initialization. Those assignments are a static-update concern, not proof that the initial screenshots used hex fallbacks.
- **Better-than-training**, supplied screenshots, viewed 2026-10-13: background already matches. Border and font visibly differ. One theme cannot prove all palette roles behave correctly.

### Pitfalls and their removal

Make adapter-to-view styling reactive, including loaded views, so replacing the root palette does not strand them with an old object. Leaf verification should change the injected palette while a view is loaded, then exercise the chosen live theme-change path during the already authorized proof session. Include an alternative palette with contrasting menu/global text and a gradient border to reveal incorrect role use. Check keyboard focus remains visible on every control and selection remains readable under both palettes. This covers the carried Tab+Enter requirement without changing variable traversal.

### Missing question

No additional theme mechanism question. Carry adjacent-highlight distinguishability as a visual acceptance criterion, including empty, one-character, repeated and wrapped values. Do not promise a literal gap between every adjacent pill.

## Q3. Transparency

### Pick, reason and cost

Follow `Commons.Color.menu.background` including its alpha, with the card itself and its text at full item opacity. Retain the theme's `menu.scrim`. This is the simplest implementation of the intake's requirement to follow active theme settings, and it matches the measured first-party overlay.

Cost: **this remains opaque in the measured theme**. It must not be described as satisfying an unconditional demand for visible transparency. The operator must choose whether consistency with the actual menu theme resolves F4 or whether translucency takes precedence. If the latter, offer an explicit Varhop-only background-alpha choice, with 0.93 as a proposed starting value, and record that it overrides theme alpha. Do not silently add a cap, multiplier or extra settings control.

### Rejected options

- Set the entire overlay/card `opacity` to 0.93: also fades text and controls and does not express background-only translucency.
- Copy the Hyprland window rule: the measurement identifies a shell layer surface, not an ordinary tagged window.
- Automatically write `[menu] background-alpha = 0.93` to user configuration: that affects other menu consumers and expands a Varhop change into a desktop preference change. It is a legitimate separately selected operator option, not a plugin fix.
- Force local 0.93 while claiming theme-alpha inheritance: those are conflicting policies. A local override is viable only as an explicit choice.

### Evidence, tier, source and date

- **Operator**, INTAKE F4 and desired outcome at line 46, read 2026-10-13: asks both for translucency and following theme settings. The measurement exposes a choice between those outcomes on this theme.
- **Practitioner context**, Omarchy maintainers' Emojis uses the shared menu background directly, as shown by the installed implementation below. That supports consistency but cannot decide the operator's preference.
- **Better-than-training**, `/usr/share/omarchy/shell/Commons/Color.qml:75-76,100-107,205-214`, `Commons/Util.qml:31-39`, and `plugins/emojis/Emojis.qml:27-34`, read 2026-10-13: menu alpha defaults to 1, the shared scrim defaults to 0.5, the helper sets color alpha, and user shell overrides win over theme values. No new opacity mechanism is needed to honor these tokens.
- **Better-than-training**, supplied look Measurement and both screenshots, read/viewed 2026-10-13: both cards are opaque. This rebuts “all other Omarchy overlays are translucent,” not the user's request for translucency.
- **Better-than-training**, `/home/ivan/.config/hypr/terminal-opacity.lua:1-8`, read 2026-10-13: 0.93 applies to `default-opacity` windows, while terminals explicitly use compositor opacity 1 and provide background translucency themselves. Do not generalize the first line to all windows or terminals.

### Pitfalls and their removal

Use background color alpha without fading foreground content. A translucent card sits over the scrim, so local alpha 0.93 does not guarantee the same visible result as a window at 0.93. If translucency is selected, leaf visual proof must show the result over a known contrasting background with the retained scrim, and check text, selection and highlights. The current still images do not prove blur or compositing behavior for that future choice. Do not introduce blur or compositor rules as an unasked feature.

### Missing question

Which scope should win: follow menu theme alpha even when opaque, deliberately override only Varhop's background alpha, or explicitly change the shared menu setting? Recommend the first for consistency, but require an affirmative operator answer before treating F4 as resolved. None of these choices was applied in this pass.
