# variable-editing: blind notes (slot A)

Read 2026-10-12. Tiers: [OP], [SRC] inspected file, [DOC] URL, [MK].

## Q1 What is editable
Pick: whole body editable, VS Code snippet-session model. Variables are tracked ranges inside one editor; Tab selects a range including braces [OP intake]; typing replaces it; edits elsewhere shift the ranges. Reason: intake describes text selection ("selects the variable including the braces"), which is editor behavior; users fix a word in a prompt before sending. Cost: copy fidelity needs care (Q4); range tracking through arbitrary edits.
Rejected: values-only form (fields beside a read-only preview, Espanso forms style). Exact output for free, but contradicts "Tab selects the token in the text" and blocks quick wording tweaks.

## Q2 Tab stops
Pick: one stop per unique name, in first-appearance order; all occurrences mirror the typed value (VS Code mirrored placeholders, code.visualstudio.com/docs/editing/userdefinedsnippets, [MK] not re-read). Tab after the last stop wraps to the first; Shift+Tab reverse. Reason: repo-format says repeated names share a value; one stop per name avoids typing twice. Cost: user cannot give two occurrences different values (edit text by hand instead).
Rejected: stop per occurrence (duplicate typing, mirroring anyway); stop leaving editor at end (Ctrl+C is the exit).

## Q3 Filled state
Pick: unfilled token shows highlighted in accent; a filled range shows its value with a subtle accent underline and stays a stop, so Tab reselects the whole value. Ctrl+Z undoes. Editing that deletes a whole range removes the stop.
Rejected: filled values lose their stop (cannot fix a typo by Tab).

## Q4 Copy and grammar
Pick: copy = editor text, then line endings restored to the source file's style and the source's final-newline state kept; for an unedited body this equals body with tokens replaced. Grammar: `{{` + `[A-Z][A-Z0-9_]*` + `}}`, no inner spaces; `{{{NAME}}}` = literal `{` + token + `}`; tokens inside code fences are still tokens; backslash stripped only in front of a valid token (`\{{abc}}` stays as written); typed or pasted `{{OTHER}}` is literal text, never a stop.
Rejected: rebuild from body + values only (impossible once free edits are allowed).

## Evidence
- [SRC] No first-party shell QML uses TextEdit; Tab handling via Keys.priority BeforeItem in /usr/share/omarchy/shell/Ui/PanelKeyCatcher.qml:23-60.
- [OP] INTAKE.md Tab/Shift+Tab, Ctrl+C.

## Pitfalls
- P1 TextEdit eats Tab: Keys.priority BeforeItem handler on the editor (PanelKeyCatcher precedent).
- P2 Ranges drift after edits: update ranges from contents-change deltas; prove with insert before, inside, across a range.
- P3 CRLF/BOM lost: store source style at load, restore on copy; fixture proof.

## Questions not asked
- Q5 Should Enter at the last stop copy and close too, or only Ctrl+C?
