# Controls merged (A, B, C), 2026-10-13

## Agreed
- One fixed header row at the top of the card, not a footer and not inside the scrolling body (A,B,C). Header height follows the Omarchy menu headerHeight rule (A,C).
- Text labels plus the shortcut printed in muted text on the button. A glyph is optional and never used alone (A,B,C).
- Search: Settings on the right, no Back (A,B,C). Editor: Back on the left, Settings on the right (A,B,C).
- Editor Back = today's Ctrl+P path: draft kept, previous query and selection restored (B,C). A said "Esc" here, which was wrong: editor Esc hides. A corrects to Ctrl+P.
- Esc meaning unchanged everywhere: search clears then hides, editor hides and keeps the draft, settings clears the picker filter then goes back (A,B,C).
- One root function per action, so a click, Enter on a focused button and the shortcut run the same path and capture the draft before the settings Loader destroys the editor. A component case compares button and shortcut results (B,C).
- The editor's variable Tab cycle cannot be left with Tab (EditorBody.qml:199-208 wraps). Controls need a separate focus key (B,C). A's "Tab stops outside the cycle" works in search and settings but not in the editor. A accepts the key.
- Icon-only and hint-only options rejected (A,B,C).

## Disagreements
- D1 focus key: F6 toggles body/header, Tab walks inside the header (B) vs Ctrl+Tab enters header, Esc or Ctrl+Tab returns (C). C notes F6 is unknown to most users and hard to hint on a button. B cites VS Code's Tab-trap escape.
- D2 settings header: title "Settings", no Settings button (B) vs Settings button shown inert in active state (C).
- D3 first-run settings with nowhere to go back: button labelled "Close" (B) vs "Back" that hides (C, and C rejects Close).
- D4 Back label in editor: "Back to prompts" (B) vs "Back" with header title naming the view (C,A).
- D5 header title: C wants a middle title (Prompts, prompt title, Settings). B only titles settings.
- D6 search Tab reach: B lets search and settings reach the header by normal Tab too. C uses only the focus key everywhere (C says Tab from the query should not leave filtering).

## Unasked, raised
- Header stays navigation only, no Sync button (C).
- C proposes qs.Ui Button at the root (Ui/Button.qml:66-69 handles Return, Enter, Space, focus ring) so views stay Quickshell-free.
- Mismatch routing: Back in settings must not open a search with no valid library (B,C).

## Rebuttal corrections
- "Esc unchanged everywhere" holds only while focus is in the view body. With focus on a header button, Esc returns focus to the body without hiding (B,C).
- D1: B's Tab inside the header continues back into the body, and F6 jumps straight back to saved body focus (B).
- D6: B says requiring the focus key in search and settings goes beyond the editor exception and needs an explicit operator choice. C says one entry key everywhere is the only rule a single hint can state.
- D2: C says a fixed row should not lose its right button in one view. The active state marks "you are here" and stays out of focus.
- D3: B says the label should match what happens (Close hides). C says one label per slot is learnable and the title shows where you landed.
