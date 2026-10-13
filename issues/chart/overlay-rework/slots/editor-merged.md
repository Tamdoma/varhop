# Editor fork, merged notes (A), 2026-10-13

Sources: editor-A.md, editor-B.md, editor-C.md. Tags name the slots whose own notes say the line.

## Shared ground
- The plugin is pure QML/JS. Adding a compiled extension for the editor is not proposed (B,C). This is a recommendation, not an operator lock (B rebuttal R1).
- QML TextDocument exposes no character formats or highlighter, so per-range styling inside one text item needs C++ (C, verified in qquicktextdocument.h). A's assumption is confirmed (A,C). B reached the same conclusion from Qt docs (B).
- The canvas is a PlainText TextEdit, never RichText or Markdown. Hostile text stays literal (A,B,C).
- Copy stays rebuilt from lib/tokens.mjs segments plus the values map, never from display text (A,B,C).
- Per-name undo stacks, Delete empty-then-unset and draft capture already exist in EditorBody.qml and are kept (A,B,C).
- Whole-body editable is rejected: it reopens the fixed-prose and copy-from-segments locks (A,B,C).
- A Flow of prose pieces and fields is rejected: prose reflows, newlines, indentation and code fences break (A,B,C).
- A prototype runs before handoff, scratch only, discarded after (A,B,C).

## Q1 mechanism: disagreement
- M1 guarded single TextEdit: whole prompt in one editable PlainText TextEdit, edits allowed only inside the active value range, mirrors rewritten in code, native undo kept unreachable, per-name undo kept (A,B).
  - Gain: one real text layout, native caret and selection everywhere, nothing covers the prose.
  - Risk: prose protection must catch paste, menu paste, cut, IME commits and middle-click, which do not all arrive as keys. A post-change verifier must revert bad edits without breaking IME composition (B,C). The context menu's Undo entry reaches Qt's native undo and bypasses per-name undo (C).
- M2 floating field: read-only PlainText TextEdit canvas, one native TextArea opened over the active occurrence's rectangle from positionToRectangle, typing writes through per keystroke so mirrors stay live (C).
  - Gain: prose is fixed by construction. IME, paste, menu, undo and Delete keep their existing field code paths (C).
  - Risk: the field covers following words for empty or long values. A value wrapping mid-line gets a rectangular field over a non-rectangular hole. Field and canvas font metrics must match or text jumps (A,B,C).
- On failure: A would switch to M2 (A). B would reconsider M2 as a new decision (B rebuttal R2). C returns Q1 to the operator with evidence, where M1, a hybrid or narrower inline scope are all open (C rebuttal 3).

## Q2 look: agreed
- Highlight rectangles painted behind token runs, computed per line from positionToRectangle (A,B,C).
- Unset: literal `{{NAME}}` on a muted highlight. Filled: value text, no braces, quieter highlight. Empty: a small marker, paint only, never a character in the text. Size and overlap with neighbours are measured in the prototype (B rebuttal R3). Active: strongest highlight plus caret or field (A,B,C).
- Rectangles recompute on text, width, font and theme change (B,C).

## Q3 prototype: agreed yes, box differs
- Box: 20 min (B), 45 min (A), 60 to 90 min (C).
- Target: M1 first (A,B), M2 first (C).
- Corpus: repeated name before the active one, explicit newlines, CRLF source, long wrapped value, empty name, hostile literal text, about 50 tokens (B,C).
- Must cover menu paste, menu Undo and IME composition, or record them unproved (B,C).
- Run at the real card size 560x480 and with the look fork's likely font (C).
- Drive with the uinput keyboard from the proof-bar probe (C).

## Questions surfaced
- Clicking a repeated occurrence edits that occurrence in place, Tab order stays by unique name (B,C).
- Filled values keep a highlight or read as plain prompt text (C).
- If only the multiline case fails, is a hybrid acceptable (C).
- Keyboard route between the editor's Tab cycle and the Tab+Enter toolbar controls (B). This belongs to the controls fork.
- Who watches the prototype: door alone or operator present (C).

## A's merged recommendation
Prototype both in one box of about 60 minutes, M1 first. M1 passes only if menu paste, menu Undo, cross-boundary selection replace and IME composition all keep prose fixed and per-name undo intact. Any fail moves to M2 in the same box. M2 passes only if the wrap, multiline and empty cases stay usable at 560x480. Both fail returns to the operator with screenshots.

## Rebuttal corrections (after B and C rebuttals)
- Order: C argues M2 first because it reuses the existing field code, so a fair test fits the box. A fair M1 test must build guard, verifier, mirror rewrite and undo interception first (C rebuttal 1). A now recommends M2 first.
- IME: this host's input method is keyboard-hr only, with no preedit engine, so M1's IME risk cannot be produced here. An M1 pass with IME unproved is not a pass (C rebuttal 2).
- M2 pass bar must include selection replace, menu Undo, mirror sync, per-name history and resume, not only geometry (B rebuttal R4).
- Failure returns the mechanism to the operator with evidence. No automatic switch (B,C).
