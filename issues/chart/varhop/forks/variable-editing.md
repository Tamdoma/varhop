# Variable editing

## Question
Q1. What can the user edit after opening a prompt: only variable values, or the whole body with variables as tab stops?
Q2. Tab/Shift+Tab: one stop per unique variable name (all occurrences update together) or one stop per occurrence; what happens at the last stop and after the last stop?
Q3. When the user types over a selected `{{NAME}}`, what is the visible state (filled value shown in place, still marked as a variable, revisitable with Tab), and can a filled variable be reset?
Q4. How is the copied text produced (rebuilt from the original body plus values, or read back from the editor), and which exact token grammar edge cases are pinned (first char digit or underscore, `{{{NAME}}}`, tokens inside code fences, `\{{abc}}` with a non-token name, pasted text containing `{{OTHER}}`)?

### Carries
- form-factor taken: Omarchy shell overlay plugin in QML/JS (forks/form-factor.md).
- repo-format taken: uppercase `{{NAME}}` (A-Z, 0-9, underscore), anything else in braces literal, `\{{NAME}}` for a literal token, no defaults or hints in v1, repeated names share one value, bodies are arbitrary Markdown copied verbatim (forks/repo-format.md).
- Operator intake: Tab and Shift+Tab select `{{VARIABLE}}` tokens including the braces; Ctrl+C copies the whole prompt and closes (INTAKE.md).
- Merged map: derive Tab order from the original template plus a values map, never re-parse edited text (slots/map-merged.md line 9).
- C2 review (slots/review-C2.md M1, F5): copy rebuilt from stored body plus values, not from a TextEdit document (CRLF and final newline); typed or pasted `{{OTHER}}` stays literal; real TextEdit/TextInput for IME, dead keys, paste; Tab intercepted before the widget consumes it; token grammar edge cases pinned.
- Front matter boundary (CHART.md Fog, C2 F4): a body opening with `---` must not be swallowed as front matter.

## Findings
Independent notes: slots/variable-editing-A.md, -B.md, -C.md. Merged: slots/variable-editing-merged.md. Rebuttals: slots/variable-editing-rebuttal-B.md, -C.md.
- Settled by all slots after rebuttal: values only, prose fixed (A conceded; INTAKE.md:14,31). One stop per unique name, first-appearance order, mirrors, Tab/Shift+Tab wrap, no final stop, zero-variable prompt opens ready to copy; first stop selected on open (B,C); clicking a mirror activates the shared name, next Tab goes to the next unique name (B,C). Filled value shows without braces, stays marked and revisitable. Enter inserts a newline in a value, Tab is the only navigation key (A,B,C after C withdrew Enter-as-next). Copy rebuilt from parsed source segments plus values, never from the editor; concatenation, no `String.replace`. Grammar `{{` + `[A-Z0-9_]+` + `}}` with no first-character rule (B; A,C conceded); `{{{NAME}}}` = `{` + token + `}` (A,C; B conceded); tokens in code fences are stops; backslash removed only before a valid token; pasted `{{OTHER}}` literal. Per-variable semantic undo/redo including reset, mirrors follow, no cross-variable undo (B; C conceded). Empty value is distinct from unset; Delete on a selected value makes it empty (B; C conceded).
- Mechanism (not an operator question): C one flowing TextEdit with key guard on the TextEdit itself plus an onTextChanged verifier; B a native input for the active value with prose outside any writable model. Both agree the Keys handler must sit on the focused editor (Qt Keys priority docs; PanelKeyCatcher.qml:23-27 comment is wrong for accepted keys). Leaf done-criterion either way: typing in prose rejected, paste by keyboard/menu/middle-click, dead keys, IME commit, multiline value, mirror edit.
- Open: reset to unset (C: Delete again on an empty value; B: separate Reset action); resume after hide (B: exact cursor and selection; C: reselect the whole active value); pasted value fidelity (Qt turns CRLF/U+2028/U+2029 into LF and NBSP into space in values; C accept for v1, B settle the whole policy or prove an exact path).
- Owned elsewhere: unset variables at Ctrl+C (copy-and-close); values remembered across sessions (settings-and-hotkey); front matter boundary (importer, CHART.md Fog).

## Taken

2026-10-12 operator: `1a | 2a | 3a`
- Q1 values only, prose fixed (settled by all slots, presented and not objected).
- Q2 one stop per unique name, first-appearance order, mirrors, Tab/Shift+Tab wrap, first stop selected on open, no final stop.
- Q3 filled values show without braces and stay revisitable; Delete on a selected value makes it empty; Delete again on an empty value restores unset `{{NAME}}` (operator 1a; foreclosed: separate Reset action). Hide and resume keeps the exact cursor and selection (operator 2a; foreclosed: reselect on show). Enter inserts a newline, Tab is the only navigation key. Per-variable semantic undo/redo including reset.
- Q4 copy rebuilt from parsed source segments plus values; grammar `{{[A-Z0-9_]+}}`, `{{{NAME}}}` = `{` + token + `}`, tokens in code fences count, backslash removed only before a valid token, pasted `{{OTHER}}` literal. Pasted values may be normalized by Qt (CRLF/U+2028/U+2029 to LF, NBSP to space); accepted for v1 (operator 3a; foreclosed: exact value-input path).
- Editor mechanism left to leaf design with the shared proof list in Findings.

Handoff review amendment (2026-10-13, operator `4a`; proofs-overlay.md rows 16-17): middle-click paste, dead-key composition and IME preedit commit are not agent-provable on this machine. They move from done-criteria to a one-time operator check after merge, with exact steps in the overlay-plugin design. Keyboard and menu paste, `č` through fcitx5, multiline values and mirror edits stay done-criteria. Foreclosed: mid-build operator checks, and dropping the three checks.
