# controls

## Question
Q1. Where do visible Back and Settings controls go, and how are they keyboard-reachable (F6, F7)?

### Carries
- Merged map: slots/map-merged.md
- Disposal fork: forks/disposal.md
- Operator F6, F7 verbatim (INTAKE.md:29-30). Today back and settings exist only as keys (EditorBody.qml:222-229 Esc hides, Ctrl+P finds another, README Ctrl+,).
- Proof-bar Taken: every mouse action also works by Tab+Enter through the same action path. The editor's variable Tab cycle is unchanged (forks/proof-bar.md). Picker Taken 4a: a composite list counts as one Tab control.
- Editor Taken: one guarded text box. Tab and Shift+Tab walk unique variable names with wrap. B's editor note R5: controls need a separate reachable focus context, not insertion into the variable cycle.
- Look Taken: menu font one step up, menu tokens, Style focus tokens.
- Picker Taken: forks/picker.md.

## Findings
Notes: slots/controls-A.md, -B.md, -C.md, merged slots/controls-merged.md, rebuttals slots/controls-rebuttal-B.md, -C.md.
- A fixed header row at the top of the card with text buttons and printed shortcuts. Search: Settings. Editor: Back (Ctrl+P path, draft kept) and Settings. Esc in the body is unchanged (A,B,C).
- Click, Enter on a focused button and the shortcut call one root function per action. A component case compares their results (B,C).
- The editor's Tab wraps over variables (EditorBody.qml:199-208), so Tab alone cannot reach the header there. A separate focus key is required. In the header, Esc returns focus to the body (B,C).
- Open: which focus key (F6 or Ctrl+Tab), whether Tab also reaches the header in search and settings, what the settings view shows on the right, and the label when settings has nowhere to go back to.
- Omarchy's own menu has no visible back button. Back is Backspace or Left on an empty filter (Menu.qml:1248). It is not a precedent for F6.

## Taken
Operator 2026-10-13: `1a | 2a | 3a | 4a`.
- 1a: Ctrl+Tab moves focus from the view body to the header in every view. In search and settings, plain Tab also reaches the header in the normal focus order. In the header, Tab and Shift+Tab move between visible buttons, and Enter, Return or Space presses one. Esc or Ctrl+Tab in the header returns focus to the body with caret, selection, active variable and picker highlight untouched, and does not hide. The editor's variable Tab cycle is unchanged. The live keyboard proof must show Ctrl+Tab reaching the overlay. Hyprland binds Ctrl+Tab only inside the capture submap (/usr/share/omarchy/default/hypr/bindings/utilities.lua:64).
- 2a: inside settings the header's right side is empty. There is no Settings button there, and the title says "Settings".
- 3a: the settings left button says "Back" when a return view exists and "Close" when the existing backRequested branch hides (no cameFrom and no selection, Varhop.qml:923-932). Its label follows that same condition.
- 4a: a middle title names the view: "Prompts" in search, the prompt title in the editor (PlainText, elided first when space is short), "Settings" in settings. The editor button says "Back".
- Locked from the Findings: one fixed header row at the top of the card, outside the view loaders. Text buttons show their shortcut in muted text ("Back  Ctrl+P", "Settings  Ctrl+,"). A glyph is optional and never alone. Search has no Back. Editor Back runs the Ctrl+P findAnother path with the draft kept. Settings in search and editor runs the Ctrl+, path, capturing the draft first. Esc in the body keeps its current meaning. One root function per action serves click, focused-button Enter and shortcut, and a component case compares their results, including the settings-to-editor round trip and the library-mismatch route. Nothing gives a header button the initial focus. A view change driven by the root returns focus to the new view's body. Header stays navigation only, with no Sync button.
- Not decided here, implementer's choice within the look tokens: whether to use qs.Ui Button at the root (C's suggestion) or a plain button with the same focus tokens.

