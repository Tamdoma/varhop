# Variable editing: blind notes, slot B

Read date: 2026-10-12. These are recommendations, not operator decisions. I read the supplied Question/Carries, intake, locked Taken sections, and my earlier map and sync notes. I did not read another slot's variable-editing notes. Earlier proposals superseded by the locks are not reopened.

## Evidence

- **E1. Operator, 2026-10-12.** `issues/chart/varhop/INTAKE.md:30-33` requires the whole prompt to open, inline selection including token braces, backward traversal, interruption to obtain values elsewhere, and whole-prompt Ctrl+C followed by close. `forks/repo-format.md:25-28` locks uppercase names, literal invalid tokens, an escape, no defaults/hints, and verbatim arbitrary Markdown. The supplied `forks/variable-editing.md:11-15` carries shared values, original-template navigation and source-based export.
- **E2. Practitioner, read 2026-10-12.** [SirVer, New parser for UltiSnips](https://www.sirver.net/blog/2011/07/24/new-parser-for-ultisnips/), published 2011-07-24. UltiSnips' creator describes daily use and replacing a regex-based parser with explicit text objects and mirror references because nested syntax and ambiguous references caused complexity. This supports retaining variable identity separately from visible text. It does not require varhop to adopt nested syntax or a general snippet engine.
- **E3. Better-than-training, read 2026-10-12.** [VS Code snippets](https://code.visualstudio.com/docs/editing/userdefinedsnippets#_snippet-syntax): numbered stops have linked occurrences, placeholders are selected for replacement, and `$0` is the final cursor position. Useful precedent for shared names and selected values, not proof that varhop needs a final prose-editing state.
- **E4. Better-than-training, read 2026-10-12.** [Espanso forms](https://espanso.org/docs/matches/forms/): named fields are collected through a form, multiline inputs are explicitly supported, and submission is Ctrl+Enter. This demonstrates a values-only workflow without editing the surrounding template. Its separate form is not the operator's requested inline interaction.
- **E5. Better-than-training, read 2026-10-12.** [Raycast dynamic placeholders](https://manual.raycast.com/dynamic-placeholders): matching argument names share a value, arguments are collected in search inputs, there are at most three distinct arguments, and arguments are required unless a default is supplied. Name-based identity transfers to varhop. The limit and required-value policy do not.
- **E6. Better-than-training, read 2026-10-12.** [TextExpander fill-ins](https://textexpander.com/learn/using/snippets/advanced-snippet-elements/advanced-fill-ins) shares values between identically named fields. [Advanced syntax](https://textexpander.com/learn/using/snippets/snippet-fill-ins/advanced-fill-in-syntax) distinguishes single-line and multiline fields. [UltiSnips manual](https://raw.githubusercontent.com/SirVer/ultisnips/master/doc/UltiSnips.txt), lines 1253-1289 and 1408-1419, uses ordered stops, a final `$0`, and mirrors. Its default jump keys are Ctrl+J/Ctrl+K, not Tab, because Tab commonly belongs to completion.
- **E7. Better-than-training, inspected 2026-10-12.** `pacman -Q quickshell qt6-base qt6-declarative` returned `0.3.2-4`, `6.12.0-2`, `6.12.0-1`. Installed `/usr/lib/qt6/qml/QtQuick/plugins.qmltypes:9855-9900,18571-18574,18830-18864` exposes Keys priorities, composing state, selection, textEdited, paste and undo. `/usr/lib/qt6/qml/QtQuick/Controls/Basic/TextArea.qml:10` and `TextField.qml:10` wrap native template controls. These APIs exist locally. No inline-variable prototype or live input test was run.
- **E8. Better-than-training, read 2026-10-12.** [Qt Keys 6.12](https://doc.qt.io/qt-6/qml-qtquick-keys.html#key-handling-priorities) places BeforeItem handling before the attached item's native handling, with parents later. Acceptance stops propagation, and specific handlers precede onPressed. [TextEdit](https://doc.qt.io/qt-6/qml-qtquick-textedit.html) supports plain text, selection, multiline editing, undo and composition state. [TextInput](https://doc.qt.io/qt-6/qml-qtquick-textinput.html) is single-line. Use native input rather than constructing text from key event characters.
- **E9. Better-than-training, inspected 2026-10-12.** `/usr/share/omarchy/shell/plugins/emojis/Emojis.qml:193-228`, `clipboard/Clipboard.qml:348-393`, and `menu/Menu.qml:1231-1275` intercept keys and manually build filters. They are not multiline/IME editor precedents. `polkit/PolkitAgent.qml:310-334` uses a real TextInput with only Escape intercepted. `image-picker/ImagePicker.qml:708-713` recognizes Backtab and Shift+Tab. `dev-gallery/GalleryPanel.qml:327-333` blocks the panel catcher while a real field owns focus. `Ui/TextField.qml:18-55` supplies native themed input. `Ui/PanelKeyCatcher.qml:25-29` claims BeforeItem precedes descendant handling, but Qt's documented priority is relative to the attached item. Do not rely on that comment to intercept a focused TextEdit's accepted keys.
- **E10. Better-than-training, source inspected 2026-10-12.** Qt 6.12 [TextEdit source](https://raw.githubusercontent.com/qt/qtdeclarative/v6.12.0/src/quick/items/qquicktextedit.cpp), lines 166-185, 1971-1976, 2203-2210 and 3357-3371, delegates keys/IME to its native control and obtains plain text through document/fragment conversions. [Control source](https://raw.githubusercontent.com/qt/qtdeclarative/v6.12.0/src/quick/items/qquicktextcontrol.cpp), lines 833-836, 901-904 and 1850-1853, consumes normal copy/paste and reads QTextDocument plain text. [QTextDocument source](https://raw.githubusercontent.com/qt/qtbase/v6.12.0/src/gui/text/qtextdocument.cpp), lines 1213-1251, replaces NBSP with space and Unicode line/paragraph separators with LF. [Documentation](https://doc.qt.io/qt-6/qtextdocument.html#toPlainText) confirms those conversions. A native editor's output is not an exact source serializer, including for some pasted values.

Practitioner synthesis: SirVer's experience supports explicit slot identity and exposes the cost of a full snippet engine. The maintained tools agree on linked identities, but differ on presentation and completion. Editor snippets supply a final cursor stop because they return to ordinary document editing. Form tools collect values before expansion. Varhop's scope and Ctrl+C completion support the latter data model with the requested inline presentation. This last conclusion is my inference. Full-body editing would change it. Practitioner searches included `Espanso Federico Terzi forms design blog snippet Raycast snippets engineer` and `site.sirver.net UltiSnips "Text Objects"`. I found no first-hand source establishing an optimal last-stop policy for this exact launcher.

## Q1. Editable scope

### Pick, reason and cost

**D1. Edit variable values only, in the opened prompt.** Keep the source body immutable and retain a value state per original unique name. Surrounding prose is not editable. The current token or filled value is selected in place, and edits affect only that variable, including its mirrors. Use a native plain-text TextEdit/TextArea for multiline value entry. A separate list of form fields would change the requested interaction.

This removes cross-variable deletions, accidental template edits, and the conflict between arbitrary prose changes and rebuilding from source. Cost: a one-off wording change must happen in the repository or after pasting. Inline multiline layout still requires implementation work. Qt offers whole-widget readOnly, not a demonstrated protected-variable-range component. Do not promise that putting the whole prompt in an editable TextEdit and intercepting ordinary keys protects its prose against paste, mouse actions or IME.

### Rejected options

- **O1. Whole-body editing with tracked tab stops.** Useful if temporary prose edits are required, but needs rules for deleting/merging stops, range-crossing paste, mirror conflicts and undo. Source-plus-values export would otherwise discard visible prose edits. Not requested by the intake.
- **O2. Values-only separate form.** Simpler native widget layout, but the operator specifically asked to select tokens inside the prompt. Do not substitute it silently.
- **O3. Ordinary whole-body TextEdit plus key-based edit restrictions.** Restrictions on key events cannot represent every native text mutation path. It guards the wrong boundary.

### Evidence

E1, operator, 2026-10-12, supplies scope. E2, practitioner, and E4/E7-E10, better-than-training, all read 2026-10-12, support separate slot identity and native input. None proves an existing Omarchy inline multiline editor.

### Pitfalls and removal

**R1. Native input changes immutable prose.** Keep prose outside the writable value model. The implementation must demonstrate inline replacement, multiline reflow, adjacent variables, selection, paste, dead keys and IME on the installed stack before the inline contract is considered proven. This is a pending implementation criterion, not a measurement performed here.

**R2. Refresh or hide destroys the draft.** Retain the opened source revision, values, active name and cursor/selection independently of overlay visibility and library refresh. This honors the supplied interruption carry without adding restart persistence.

### Question not asked

**Q5. Is temporary editing of ordinary prose actually required?** Recommend no for v1. If yes, D1 and the export design must change together. Do not add a second editor mode preemptively.

## Q2. Stops, ordering and endpoints

### Pick, reason and cost

**D2. One stop per unique name, in order of first unescaped occurrence, wrapping in both directions.** Opening selects the first token automatically. Every same-name occurrence updates from one value. Revisiting selects the complete current value, not the old braces. Tab from the last name selects the first. Shift+Tab from the first selects the last. There is no final body cursor stop and no finished editing state before copy. With one name, Tab reselects that value. With no names, the prompt opens read-only, copy works, and Tab/Shift+Tab do not modify text or leave the prompt workflow.

For `{{A}} / {{B}} / {{A}}`, the stops are A then B. Clicking the second A, if supported, activates A's shared value. The next Tab goes to B. Cost: reviewing every occurrence requires looking at the prompt rather than stopping at each mirror. Tab does not navigate other overlay controls during variable entry. Other actions need the keyboard routes settled in the shortcuts fork.

### Rejected options

- **O4. Stop at every occurrence.** Repeatedly selects the same shared value and adds keystrokes. Independent occurrence values are already foreclosed by the shared-name lock.
- **O5. Final `$0`-style body position.** Useful in code editors, but creates an extra state with nothing editable under D1 and weakens revisiting. Copy already completes this workflow.
- **O6. Clamp at the last/first stop.** Simple, but makes repeated Tab appear unresponsive and requires reversing direction to revisit. Wrapping is the explicit recommendation, not a convention established by the sources.

### Evidence

E1, operator carry, and E3/E5/E6, better-than-training, read 2026-10-12, support linked names. E3/E6 establish final-stop precedent in full editors. E8/E9 establish key interception and Backtab handling, not the recommended wrapping policy.

### Pitfalls and removal

**R3. Tab inserts a tab or changes focus, and Ctrl+C copies only the selection.** Attach explicit `Keys.priority: Keys.BeforeItem` handlers to the focused native editor. Accept ordinary Tab and Backtab/Shift+Tab and editor-scoped Ctrl+C before native handling. Leave other editing keys to the widget. Do not use a parent catcher as the interception guarantee, and do not attach conflicting specific key handlers or forward targets before these handlers.

**R4. Navigation interrupts composition.** While inputMethodComposing is true, give composition keys to the input method. A navigation key consumed by composition does not also move the slot. Copy must commit preedit through Qt's input method before reading the value and exporting. Prove this with actual composition, rather than treating preedit as committed text.

### Question not asked

**Q6. Should the first variable be selected immediately?** Recommend yes, as D2 specifies. This saves an initial Tab and makes the first typing action predictable. Hide/reopen resumes the active slot rather than selecting the first again.

## Q3. Filled, empty and reset states

### Pick, reason and cost

**D3. A filled value replaces the braces visually and remains a marked, revisitable variable.** Keep a subtle variable indication and an active-name label such as `A · 1 of 2` outside the exported text. Mirrors show the same value. Selection belongs to the active occurrence, not several simultaneous native cursors.

Represent each name as either unset or filled with a string. An unset slot displays its original token. A filled empty string removes the token from exported text but keeps a visible editing target in the UI. Deleting a selected token is an intentional empty value, not reset. Offer an explicit editor-local “Reset variable” action that restores unset for that name and every mirror. Its keyboard binding belongs in the shortcuts fork. Reset and ordinary edits must have defined undo semantics before handoff.

Reason: visible text cannot tell apart unset, empty, and a user deliberately entering `{{A}}` as literal content. Cost: field indication, an empty target and reset add small UI/state work. No defaults, hints or new template syntax are introduced.

### Rejected options

- **O7. Leave braces around filled text.** Makes display differ from the copied prompt and confuses delimiters with content.
- **O8. Remove variable identity after replacement.** Breaks backward traversal and corrections.
- **O9. Empty means reset, or typing the original token means reset.** Prevents intentional empty/literal values and recreates parsing-dependent identity.

### Evidence

E1, operator, and E2, practitioner, read 2026-10-12, require/support revisitable identity. E3, better-than-training, supports selected replacement. E7/E8 expose native selection/undo, but those APIs alone do not restore unset/filled model state or make mirror updates one undo operation.

### Pitfalls and removal

**R5. Empty values disappear from navigation.** Stops come from the original template, with a visible empty-field target outside output. Never derive stops from the current display or value string.

**R6. Programmatic mirror updates reset the active editor, cursor or undo history.** Let the active native input own its text while editing. Update mirrored presentation from the shared value. Do not continuously assign a reconstructed whole prompt back into that input. The done-criterion must include replacement, revisiting, undo/redo, reset, empty values and hide/resume.

### Question not asked

**Q7. Does Ctrl+C allow unset variables?** Recommend yes, copying their original tokens, with an unobtrusive remaining-variable count. The intake did not request mandatory validation. Requiring all fields would prevent intentionally partial prompts. An explicit empty value counts as filled. Raycast's required arguments are a different product choice, not authority to add blocking here.

**Q8. What is the undo boundary?** Recommend undo/redo within the active variable, updating every mirror, with reset also undoable as a semantic unset/filled change. Do not assume TextEdit's text-only undo supplies this distinction. Cross-variable global undo is additional behavior and is not proposed.

## Q4. Export and token boundaries

### Pick, reason and cost

**D4. Parse the original body once into exact literal spans, escaped literals and name references.** Export by concatenating those spans with each unset original token or filled value. Insert values as data in one pass. Never reparse generated text, run regex replacement over it, serialize Markdown, or copy the full editor document. Preserve source CRLF, tabs, spaces, Unicode and final-newline state in the stored literals. Cost: maintain this small source model and a separate display representation.

Pin these grammar recommendations explicitly. The examples below use literal characters, not programming-language string escapes.

| Case | Proposed result |
| --- | --- |
| `{{NAME}}`, `{{1}}`, `{{_}}`, `{{1_NAME}}` | Variables. Name is one or more ASCII characters from `[A-Z0-9_]`, with no special first-character rule. |
| `{{}}`, `{{abc}}`, `{{A B}}`, `{{É}}`, `{{A-B}}` | Literal text, unchanged. |
| `{{{NAME}}}`, `{{NAME}}}`, `{{{NAME}}` | Literal text, unchanged. Do not match an inner token from a longer adjacent run of the same brace. |
| `x{{NAME}}y` | One variable between literal `x` and `y`. No word boundary requirement. |
| `{{A}}{{B}}` | Two adjacent variables. |
| Tokens in fenced code, inline code, quotes or Markdown links | Recognized exactly as in ordinary prose. Markdown does not change token parsing. |
| `\{{NAME}}` | Literal `{{NAME}}`, with the immediately preceding escape backslash removed. No stop. |
| `\{{abc}}` | Literal `\{{abc}}`, unchanged. The name is not a token, so there is nothing to escape. |
| Two or more backslashes immediately before a valid token | The last backslash escapes it. Retain all preceding backslashes. No odd/even backslash language is introduced. |
| Escaped malformed/triple-brace spelling | Entire spelling stays literal, including its backslash. |
| Value contains `{{OTHER}}`, `\{{NAME}}`, `$1` or Markdown | Insert exactly as value data. No new stops, escape removal, interpolation or expansion. |

The whole-file front-matter parser must supply an already-decided body slice. Variable parsing cannot decide whether an initial `---` is metadata. Do not trim or strip another front-matter block from the body here.

### Rejected options

- **O10. Read the copied prompt from TextEdit.** Cannot promise verbatim source preservation. E10 shows a concrete Unicode normalization path even in plain-text mode.
- **O11. Repeated/global substitutions or reparsing after edits.** Values can create fake variables, change traversal order or be substituted again. Original name references remove this problem.
- **O12. Identifier-style first-character restriction, code-fence exemption, or unescaping all `\{{`.** Each adds an unstated exception to the locked character alphabet/literal rule. Triple-brace matching remains a proposed boundary refinement for this fork to settle.

### Evidence

E1, operator and supplied carries, read 2026-10-12, governs literal preservation. E2, practitioner, supports identity independent of spelling. E10, better-than-training source read 2026-10-12, proves why native document serialization is insufficient. The exact boundary table is my proposed contract, not behavior attributed to VS Code, Qt or other snippet tools.

### Pitfalls and removal

**R7. Output silently loses whitespace or changes content.** Source-based export removes native-document transformations from immutable text. Verification compares exact output for CRLF/LF, missing/present final newline, blank paragraphs, tabs, NBSP, Unicode separators and emoji, with and without replacements. These checks are pending, not reported as passed.

**R8. Display offsets disagree with source offsets.** Derive display ranges while rendering from the same parsed spans. Keep source coordinates separate from native document coordinates. CRLF/document normalization and UTF-16 emoji offsets make direct source-offset selection unsafe.

**R9. A pasted value is normalized before it reaches the values map.** Source-based export alone does not remove this problem. E10 also applies to value TextEdit.text/getText. Before contracting exact value fidelity, prove the value-input extraction path on Qt 6.12 or settle Q10 explicitly. Do not claim toRawText is a QML TextEdit API or switch to rich text as a workaround.

### Questions not asked

**Q9. How is optional front matter distinguished from a body starting with `---`?** The supplied carry makes this material. A body-only template and metadata can have identical opening characters. This belongs to the importer boundary and needs an explicit authoring rule. An undocumented required leading blank line would contradict verbatim arbitrary-body acceptance.

**Q10. Must pasted values preserve CRLF, NBSP and Unicode separators exactly?** Recommend yes for pasted text, and ordinary LF for newly typed line breaks. Native TextEdit getters are insufficient evidence for that promise. Resolving this may require a separate proven input boundary, not a change to the source-based export decision. Do not silently broaden the plugin into a compiled editor component or silently accept normalization.

## Limits and handoff implications

Only this return file was written. Research used installed type declarations and Omarchy source, exact upstream Qt 6.12 source, one first-hand practitioner write-up, and all five requested tools' primary documentation. No packages, settings, repository state, clipboard or running overlay were changed. No live editor behavior, parser implementation or clipboard delivery was tested.

D1-D4 are my picks. Q7-Q10 need explicit treatment before implementation: partial-copy policy, semantic undo, front-matter disambiguation and value fidelity. The local input/inline-layout criteria above remain pending. They must not be presented as already proven by the existing search overlays.
