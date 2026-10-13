# Inline editor

## Question
Q1. Which mechanism makes `{{NAME}}` values stay inline in the prompt text, so the prompt keeps its shape (F5), while keeping the locked rules: values only and prose fixed, one Tab stop per unique name with mirrors and wrap, Delete empties then restores `{{NAME}}`, per-variable undo, Enter inserts newline, exact cursor and selection resume, copy rebuilt from source segments?
 Candidates from the maps: one flowing TextEdit with guarded value ranges; read-only flowing text with one native input placed over the active value; a Flow of prose pieces and per-name fields; whole-body editable (reopens the values-only lock).
Q2. How does a value look inside the text (unset `{{NAME}}`, filled, empty, active), given views must render hostile strings as plain text (brief criterion 9)?
Q3. Is a short time-boxed prototype worth running before handoff to settle Q1 (scratch code discarded), or does the successor's plan decide it?

### Carries
- variable-editing Taken (issues/chart/varhop/forks/variable-editing.md): values only; unique-name Tab with wrap; first stop selected; mirrors; Delete empty then unset; Enter newline; per-variable undo/redo; exact resume; copy rebuilt from segments; grammar `{{[A-Z0-9_]+}}`; Qt paste normalization accepted; "Editor mechanism left to leaf design".
- Operator F5 verbatim (INTAKE.md seed): "The operator wants the variables to stay inline inside the prompt text so the prompt always looks the same, with no per-variable form fields."
- disposal Taken: successor `overlay-plugin` on 0df6f48; criterion-to-evidence table.
- proof-bar Taken + probe: uinput keyboard reaches the overlay; every control Tab+Enter; editor Tab cycle unchanged.
- Current editor: worktree qml/EditorBody.qml (Column + Repeater rows), lib/rebuild.mjs, lib/tokens.mjs.

## Findings
Merged notes: slots/editor-merged.md (rebuttals: slots/editor-rebuttal-B.md, slots/editor-rebuttal-C.md).
- better-than-training · /usr/include/qt6/QtQuick/qquicktextdocument.h and /usr/lib/qt6/qml/QtQuick/plugins.qmltypes, read 2026-10-13 (C) · QML TextDocument exposes no formats or highlighter. TextEdit has positionAt and positionToRectangle, plain Text has neither. Ruled out per-range styling in pure QML, so highlights are painted rectangles.
- better-than-training · doc.qt.io Qt 6.12 TextEdit and Text, read 2026-10-13 (B,C) · readOnly is whole-item, no protected subranges. Untrusted text should be PlainText. Decided PlainText canvas and made M1's guard a measured risk.
- practitioner · VS Code snippets docs code.visualstudio.com/docs/editing/userdefinedsnippets, read 2026-10-13 (A,B,C), CodeMirror snippet.ts (B) · linked tab stops in one document work, backed by a full editor model with range mapping and scoped undo. Qt QML lacks that model.
- practitioner · Espanso forms and Raycast snippets, read 2026-10-13 (C) · both ship per-variable form fields, the shape F5 rejected.
- better-than-training · worktree qml/EditorBody.qml, lib/tokens.mjs, lib/rebuild.mjs (A,B,C) · values map, per-name undo, draft capture and copy-from-segments are independent of the mechanism and kept.
- Split: M1 guarded single TextEdit (A,B) vs M2 floating field over read-only canvas (C). After rebuttals A recommends a prototype of M2 first, failure returns to the operator.
- Host input method is keyboard-hr only, no preedit engine (C rebuttal 2).

## Taken
Operator 2026-10-13: `1b | 2a | 3a | 4a`.
- 1b: the prototype tests the guarded single TextEdit (M1) first, about 45 minutes. Pass needs prose fixed under typing, paste, right-click paste, right-click Undo, middle-click, selection across a boundary, Backspace and Delete at both edges, mirrors, per-name undo, Delete empty then unset, and cursor resume. IME preedit is recorded unproved (host has keyboard-hr only). A fail or timeout returns the mechanism to the operator with evidence, with no automatic switch to M2.
- 2a: highlight rectangles behind PlainText. Unset `{{NAME}}` muted, filled faint, empty a small paint-only marker, active strongest.
- 3a: clicking any occurrence edits it in place, mirrors update, Tab order stays by unique name.
- 4a: the door runs the prototype alone with the uinput keyboard and shows screenshots cropped to the test window only.
- Not answered: `effort yes` (CLAUDE_CODE_EFFORT_LEVEL in the machine harness template). Left unchanged.

### Prototype result (operator 1b, 4a), 2026-10-13
- What: scratch M1 editor, one Controls TextArea (PlainText, wrap) with edits allowed only inside the active occurrence, mirrors rewritten, per-name undo, painted highlight rectangles. tokens.mjs copied from the worktree at 0df6f48. Scratch code deleted after this record.
- Runtime: Qt 6.12.0, qmltestrunner offscreen for 23 scripted checks, `/usr/lib/qt6/bin/qml` on Hyprland 0.56.2 for the live run. Identity: user ivan, uinput device `varhop-probe-kbd` (keyboard plus buttons), cursor placed with `hyprctl dispatch 'hl.dsp.cursor.move(...)'`.
- Result: pass. 23 of 23 scripted checks passed:
  - first open selects the first `{{NAME}}`
  - typing mirrors to every occurrence
  - typing, Backspace and menu Delete across a prose boundary are rejected
  - paste inside a value is accepted, including multi-line text
  - paste and cut across a boundary are rejected
  - native undo is unreachable (`canUndo` stays false)
  - the cursor stays put when a mirror before it grows
  - per-name undo and redo work across Tab, Delete empties then unsets, and undo of the reset works
  - Enter inserts a newline in the value
  - Backspace on an unset value keeps it unset
  - typed `{{OTHER}}<i>` stays literal
  - a wrapped value paints one highlight per line
  - clicking the second occurrence edits it in place
  - an empty value is reachable by Tab
  - 50 tokens cost about 4 ms per key
  - draft restore keeps values, history and a reverse selection
- Live run with real input: typing, Tab, Shift+Tab and Ctrl+Z (sent as the key the hr layout maps to Z) worked. Ctrl+V with a two-line clipboard filled the value. Ctrl+Home then a letter was rejected. A selection across a boundary then a letter was rejected. A middle-click paste of primary `MID` on prose was rejected. The right-click menu shows Undo and Redo disabled. Screenshot: forks/editor-prototype.png (prototype window only).
- Binding for the leaf: `cursorPositionChanged` fires before the `text` property updates. So the guard must handle both signals through one deferred `Qt.callLater` sync that compares text to the expected display. Reading text inside the cursor handler re-selects stale ranges and corrupts typing (observed, then fixed). An active unset value stays wholly selected so typing replaces `{{NAME}}`. Activation uses inclusive bounds, so one-character and empty values are clickable.
- Cleanup: clipboard and primary selection saved before and restored after, verified byte-equal with `cmp`. Prototype window closed. Scratch folder removed.
- Limits:
  - IME preedit is unproved (host has keyboard-hr only).
  - A rejected edit may show for one frame before it is reverted. No flash was seen in stills, and this was not measured per frame.
  - Menu Cut, Paste and Delete were proved through the methods the menu actions call, not by clicking menu items.
  - Adjacent values (`{{A}}{{B}}`) render as touching pills, which is a look-fork concern.
  - This does not prove the final build. The proof-bar final-build criteria still apply.
