# Editor notes, slot A

## Q1 mechanism
Pick: one flowing PlainText TextEdit showing the whole prompt (prose + values or `{{NAME}}`), with a range map from lib/tokens.mjs segments; edits allowed only inside the active value range (key guard on the TextEdit itself plus an onTextChanged verifier that restores any out-of-range change); mirrors rewritten programmatically; Qt's document undo disabled and the existing per-name undo stacks kept; copy still rebuilt from segments. Reason: only this gives a true inline shape with real caret, selection, wrap and Markdown whitespace preserved (F5 "the prompt always looks the same"). Cost: the guard is the hard part (paste, IME commit, selection spanning a boundary, Backspace at range edges); offsets shift with every value edit.
Rejected: Flow of pieces (re-wraps prose, loses indentation/code fences; looks inline only for short prose). Floating input over the active value (two text renderings, caret jumps, covers neighbours, multiline values break positioning). Whole-body editable (reopens values-only lock, and copy would read the edited doc).
Evidence:
- practitioner · Espanso forms docs (espanso.org/docs/matches/forms, read from training, search not run) render the form layout text with inline fields: proves inline fields in a template are a known UX, but Espanso uses short single-line layouts, which is where a Flow works.
- practitioner · VS Code snippet tab stops and mirrors (code.visualstudio.com/docs/editor/userdefinedsnippets): placeholders live inside one document, same-index placeholders mirror live, Tab walks them; this is the one-document model, but VS Code lets prose be edited too.
- better-than-training · Qt QML TextEdit: positionToRectangle(), cursorPosition/selectionStart, PlainText; per-range formatting needs C++ QSyntaxHighlighter on QQuickTextDocument, not reachable from a QML-only plugin (assumption, low confidence; C to verify).
Pitfalls: IME preedit inside guarded doc -> guard only on commit, verifier restores; hostile text -> PlainText only, highlights drawn as rectangles behind ranges from positionToRectangle.

## Q2 look
Pick: unset shows `{{NAME}}` in accent color with a faint pill behind; filled value shows its text with a faint pill (no braces); empty value shows a thin caret-width pill; active value has a stronger pill + caret. All drawn as rectangles behind PlainText, never RichText.

## Q3 prototype
Pick: yes, one 45-minute scratch prototype run by the door in qmltestrunner (QT_QPA_PLATFORM=wayland): a guarded TextEdit over a 3-variable prompt with a repeat, testing typing, Backspace at both edges, paste with newlines, selection across a boundary, Delete-reset, and highlight rectangles on wrapped lines. Pass -> lock mechanism in the brief; fail -> lock the floating-input mechanism. Reason: the old leaf burned 4 rounds; the mechanism is the biggest unknown left.
