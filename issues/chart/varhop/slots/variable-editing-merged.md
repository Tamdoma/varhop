# variable-editing: merged notes (A)

Sources: slots/variable-editing-A.md, -B.md, -C.md (2026-10-12).

## Agreed
- Q1 Values only; surrounding prose fixed (B,C). A conceded: intake says "focus on the variables" and "changes the variables really fast" (INTAKE.md:14,31), nothing asks to reword prose, and whole-body editing breaks source-based copy.
- Q2 One stop per unique name, first-appearance order, mirrors show the shared value, Tab wraps both ways, first stop selected on open, no final `$0` stop, zero-variable prompt opens ready to copy (A,B,C). Accept both Key_Backtab and Tab+Shift (B,C; ImagePicker.qml:708-713, PanelKeyCatcher.qml:59-62).
- Q3 A filled value shows in place without braces, stays marked and revisitable, revisit selects the whole value (A,B,C). Hide/resume restores the active stop and selection (B,C).
- Q4 Copy = rebuild from the original parsed segments plus values, never read from the editor (B,C; A conceded with Q1). Measured: QTextDocument plain text turns CRLF/CR/U+2028/U+2029 into LF and strips a BOM (C probe); NBSP becomes space (B, qtextdocument.cpp:1213-1251). Tokens inside code fences are still stops; escape is the way to show a literal example (A,B,C). Backslash removed only in front of a valid token; `\{{abc}}` copied as written (A,B,C). Typed or pasted `{{OTHER}}` in a value stays literal (A,B,C). Concatenate slices, never `String.replace` (`$&` hazard, C). Offsets for display and copy come from one segment list (B,C).

## Disagreements
- D-a Editor mechanism. C: one TextEdit showing the whole rendered prompt, guard keys outside the active range plus an onTextChanged verifier that restores the expected render. B: key-based guarding of a whole-prompt TextEdit cannot cover paste menu, mouse, IME; keep prose out of any writable model and give the active value its own native input; Keys.BeforeItem must be on the focused editor itself, not a parent (Qt Keys docs). Both: leaf proof with dead keys, IME, paste, multiline.
- D-b Clearing a value. C: Delete/Backspace on a selected value returns it to unset (token reappears); no empty values in v1; no reset key. B: deleting gives an intentional empty value; a separate "Reset variable" action restores unset. A: Ctrl+Z undo.
- D-c Enter. C: Enter = next stop, Shift+Enter newline in the value. B, A: not specified (A asked whether Enter at the last stop copies).
- D-d Name grammar. A: `[A-Z][A-Z0-9_]*`. C: `[A-Z_][A-Z0-9_]*` (`{{2024}}`, `{{404}}` stay literal). B: `[A-Z0-9_]+`, no first-char rule (repo-format lists the character set only).
- D-e Triple braces. A,C: `{{{NAME}}}` = literal `{` + token + literal `}`. B: whole run literal, never match an inner token from a longer brace run.
- D-f Undo. B: per-variable undo/redo including reset, updating mirrors. C: intercept Ctrl+Z, per-value history or ignored. A: Ctrl+Z.

## Raised, owned elsewhere
- Unset variables at Ctrl+C (B Q7: copy tokens as-is with a remaining count) → copy-and-close.
- Pasted value fidelity (B Q10: pasted CRLF/NBSP normalized by TextEdit too) → leaf proof or accept LF for values.
- Values remembered per prompt across sessions (C U3) → settings-and-hotkey.
- Click on prose: select for reading or snap to nearest stop (C U4).
