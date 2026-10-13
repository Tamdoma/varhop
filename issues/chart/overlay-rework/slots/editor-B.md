# Inline editor: blind Slot B notes

2026-10-13. Read only Question and Carries from the editor fork. No other slot's editor notes were read. Only this return file was written. No prototype or desktop operation was performed.

`W` denotes `/home/ivan/.akrogon/worktrees/varhop/overlay-plugin`. `H` denotes `issues/chart/overlay-rework/archive/overlay-plugin` under the varhop repository. Recommendations remain subject to the operator's decision.

## Q1. Which editor mechanism meets the locked behavior?

### Pick, reason and cost

**Prefer one flowing plain-text TextEdit with an explicit variable-range model, conditional on Q3's feasibility probe.** It gives the entire prompt one text layout and native caret/selection behavior. Keep the original source segments and per-name values authoritative. Derive display text and occurrence ranges from that model. Accept an edit only within one active occurrence, update that name's value, then update its mirrors. Preserve per-name semantic history outside the widget's document-wide undo history.

This is a preferred candidate, not a proven implementation recipe. Qt's documented QML interface exposes whole-item readOnly and edit notifications, not a per-range protection API or documented cancellable edit transaction. The difficult part is protecting prose across keyboard, context-menu paste, cut, replacement, undo and input-method changes while preserving native composition and selection. A Keys handler alone is insufficient. A post-change correction must demonstrably preserve composition, history and cursor state and must never commit an invalid edit to the values model or copy output.

Cost: range bookkeeping and input reconciliation. The probe must establish that these can be implemented cleanly in the existing QML/JS plugin. Do not add a compiled editor extension merely to make this recommendation appear settled.

### Rejected options and reasons

- **Read-only flowing text with one native input over the active value:** structurally protects prose and remains the second candidate. It must still make the input indistinguishable from part of the flowing prompt. An independently laid-out rectangular TextArea does not automatically match a value starting mid-line, wrapping onto full-width subsequent lines, or containing newlines. Matching layout, selection and IME placement across two surfaces may cost more than range guarding. Reconsider it if the first candidate fails the probe, not as an automatic fallback hidden in implementation.
- **Flow of prose pieces and per-name fields:** moving rectangular items into a Flow does not establish one continuous text layout. Adjacent tokens, long prose spans and multiline values must wrap like text rather than boxes. This keeps the separate-field structure behind F5 and would require evidence of equivalent layout before becoming a credible choice.
- **Whole-body editable:** directly contradicts the fixed-prose lock. Easier native editing is not authorization to change the product contract.

### Evidence: tier, source and date

- **Operator, read 2026-10-13:** F5 in the supplied intake requires values inside the prompt with no per-variable form fields. `issues/chart/varhop/forks/variable-editing.md:27-31` keeps fixed prose, shared names, wrapping Tab order, reset, per-variable history, exact resume and source-based copy while leaving the mechanism to implementation.
- **Practitioner/primary, read 2026-10-13:** the [VS Code team's snippet documentation](https://code.visualstudio.com/docs/editing/userdefinedsnippets#_tabstops) establishes linked occurrences and tab stops in a flowing editor. It does not establish fixed-prose protection. [CodeMirror's maintained snippet implementation](https://github.com/codemirror/autocomplete/blob/main/src/snippet.ts) explicitly maps field ranges through changes and deactivates snippet fields on certain cursor movements. That supports an explicit range model, but its exit behavior differs from Varhop's permanent wrap cycle. Neither editor is a drop-in mechanism for this QML plugin.
- **Better-than-training, read 2026-10-13:** [Qt 6.12 TextEdit documentation](https://doc.qt.io/qt-6/qml-qtquick-textedit.html) provides native multiline editing, selection, composition state and position mapping. Its readOnly property applies to the item. The published QML API does not expose protected subranges. This is why a feasibility test is needed.
- **Better-than-training, inspected 2026-10-13:** `W/qml/EditorBody.qml:250-297` uses separate rows and native TextAreas. Its current structural isolation cannot be assumed in a shared document. `:186-195` captures variable-local state/history; `:199-205` walks unique names; `:208-210` commits input before source-based copy. `W/lib/tokens.mjs:11-42` supplies source segments and unique-name order. Preserve those contracts rather than parsing the edited display for tokens.

### Pitfalls and what removes them

- **R1. An edit crossing prose is misclassified as a value edit.** Define permitted edits from the pre-edit active occurrence and selection. Reject cross-boundary deletion/replacement as one operation. Exercise keyboard paste, menu paste, cut and composition paths. Do not rely solely on the smallest text diff: identical adjacent text can make its location ambiguous.
- **R2. Mirrors move the active caret.** Store name, active occurrence and value-local selection/caret state, then remap them after mirrored length changes. A repeated occurrence before the active one must not shift the logical caret. Save enough state to preserve selection direction on resume, not just the unordered selected range.
- **R3. Display offsets leak into source reconstruction.** Keep source bytes/segments separate from the display representation. Test CRLF source, emoji, combining characters, repeated text and multiline values. Copy remains the existing segment/value reconstruction. Qt's cursor offsets use UTF-16 units, not grapheme counts, per its TextEdit documentation.
- **R4. Native undo reverses unrelated variables or mirror maintenance.** Retain one semantic history per name and ensure programmatic mirror updates never become user history. Verify edit A, edit B, undo B, return to A, undo A, including empty/unset reset and hide/resume.
- **R5. New controls consume variable Tab navigation.** Preserve the editor's Tab/Shift+Tab cycle. The proof-bar carry also requires Tab+Enter access to other controls, so the design must provide a separate reachable toolbar/control focus context rather than silently inserting those controls into the variable cycle.

### Missing question

When a repeated occurrence is clicked, should editing stay at that occurrence or jump to the first? Recommend staying at the clicked occurrence while retaining one logical name and the original unique-name Tab order. Also settle the keyboard route between editor and toolbar so the two Tab requirements can both be met. These are user-visible behavior choices that “one flowing TextEdit” does not answer.

## Q2. How should values look without changing the prompt text?

### Pick, reason and cost

**Use ordinary inline text with unobtrusive decorations, preserving content and font metrics.**

| State | Recommended rendering |
|---|---|
| Unset | Literal `{{NAME}}`, with a subtle theme-derived underline or background identifying the editable range. |
| Filled | The actual value without braces, same font and baseline as surrounding prose, with a subtle range decoration so it remains discoverable. |
| Empty | No replacement text and no reserved field width. Draw a small non-text boundary indicator so the zero-length range remains findable. Tab reaches it regardless of pointer hit testing. |
| Active | A stronger decoration around the active occurrence and a normal native caret/selection. First open selects the first placeholder as locked. Decorations must not replace a resumed partial selection. |

Repeated occurrences show the same value. Active occurrence identity remains distinct from shared value identity. Empty indicators may overlap for adjacent empty names, so keyboard traversal remains the unambiguous selection path.

Cost: range decoration geometry, especially for wrapped values and empty ranges. Prototype those cases. Preserve explicit line breaks and indentation. Values changing length naturally reflow following text; “same shape” should mean continuous prompt layout without injected form rows, not frozen pixel positions.

### Rejected options and reasons

- **Visible labels, chips or padded boxes for every value:** reintroduces the per-variable form appearance and changes wrapping.
- **Render empty values as `{{NAME}}`:** collapses the locked distinction between empty and unset. Empty copies zero characters; unset copies the token.
- **Insert an invisible character or an “empty” label into the document:** creates extra positions and potential copy/history errors. An empty marker must be paint/UI only, outside the text model.
- **Use Markdown/HTML interpolation to style prompt content:** violates the literal-text requirement and adds markup escaping/position translation. Set PlainText explicitly and decorate separately.
- **Reselect the whole value whenever the editor regains focus:** breaks exact cursor/selection resume. Selection on first open is not permission to reset selection later.

### Evidence: tier, source and date

- **Operator, read 2026-10-13:** `issues/chart/varhop/forks/variable-editing.md:29` distinguishes filled, empty and unset states and locks exact resume. F5 requests no form fields.
- **Better-than-training, inspected 2026-10-13:** `W/qml/EditorBody.qml:288-299` and `:353-366` distinguish missing values from present empty strings. `H/brief.md:60` requires hostile strings to remain literal with no request. `W/lib/rebuild.mjs:5-15` preserves empty versus unset in copy output.
- **Better-than-training, read 2026-10-13:** [Qt TextEdit textFormat](https://doc.qt.io/qt-6/qml-qtquick-textedit.html#textFormat-prop) distinguishes PlainText from interpreted formats. Explicit PlainText preserves the intended display contract.
- **Better-than-training, read 2026-10-13:** [QSyntaxHighlighter](https://doc.qt.io/qt-6/qsyntaxhighlighter.html#setFormat) can apply display formatting without changing document content, but requires a subclass. [QQuickTextDocument](https://doc.qt.io/qt-6/qquicktextdocument.html) provides the native document interface. These C++ APIs do not establish that a highlighter can simply be instantiated from this plugin's existing QML. Do not promise that implementation or introduce a compiled dependency without a separate justified decision.

### Pitfalls and what removes them

- **R6. Highlighting changes line wrapping.** Use decorations that do not add padding or alter font metrics. Compare adjacent values, punctuation, indentation and wrapped multiline content with an undecorated plain-text rendering of the same display string.
- **R7. Visual markers become copied data.** Assert exact reconstructed bytes for unset, filled and empty values, including all-empty output and trailing newline. No decoration character enters source or values.
- **R8. Range paint is correct only on one line or one font size.** Derive decoration geometry from the actual layout and refresh it after edits, resizing and font changes. Do not use one start/end rectangle as an assumed multiline outline.
- **R9. Placeholder-looking user input becomes a new variable.** Type/paste literal `{{OTHER}}`, `<b>x</b>` and an image tag into a value. They remain text in that value. Variable identity comes only from parsed source.

### Missing question

Confirm that a small non-text empty-range indicator is acceptable and that natural reflow as values grow is intended. Specify what the user sees when two empty ranges share the same visual position. These decisions matter more than choosing an exact highlight color now.

## Q3. Prototype now or leave the mechanism to the successor plan?

### Pick, reason and cost

**Recommend an explicitly approved 20-minute feasibility probe before handoff**, targeting the single-document candidate and the two hardest unknowns: fixed-prose enforcement under native edits, and inline range rendering for multiline/empty/repeated values. Twenty minutes is an estimate and a stop boundary, not a promise of implementation success.

Use disposable QML/JS scratch code with synthetic prompts, retain findings only and discard the scratch code. No installation or production state changes. Clipboard/live operations require their own explicitly scoped handling rather than assuming a scratch probe cannot affect the desktop. This notes task does not authorize running the probe.

### Rejected options and reasons

- **Leave everything to the implementation plan:** reasonable for routine widget choices, but here failure may force a different mechanism or packaging choice. A small measurement can prevent another long repair cycle around the wrong editor structure.
- **Build all candidate editors:** too much work for a charting decision. Test the preferred candidate against disqualifying cases first. If it fails or the clock expires, record exactly what remains unknown and return to the mechanism choice.
- **Treat prototype success as completion proof:** a scratch editor does not prove the final root, lifecycle, theme or clipboard integration. The successor still needs final-build component and live evidence under the newly settled proof bar.

### Evidence: tier, source and date

- **Better-than-training, inspected 2026-10-13:** `W/qml/EditorBody.qml:250-297` proves the current layout needs structural replacement, not a spacing adjustment. The API and practitioner evidence in Q1 establish feasible ingredients but not their combined correctness under Varhop's fixed-prose rules.
- **Operator decision, read 2026-10-13:** `issues/chart/overlay-rework/forks/proof-bar.md`, Taken and probe result, now supplies a demonstrated uinput keyboard route and restores OA2/OA3 as agent criteria on the final build. Its search-field probe does not establish the new editor. Preserve that final-build obligation.

### Pitfalls and what removes them

- **R10. Probe covers only typing in a simple one-line value.** Use one compact corpus containing `Before {{A}}{{B}} after {{A}}`, explicit newlines, CRLF source, a long wrapped value, an empty name and hostile literal text. Exercise mirror growth before the active occurrence, newline entry, boundary selection replacement, Delete empty→unset, per-name undo and capture/restore with a reverse selection. Test the geometry at two widths.
- **R11. Read-only prose is “proved” using only intercepted keys.** Include native paste and a composition-sensitive path or explicitly record those paths as unproved. No blanket pass if only ordinary typing was tested. If the environment cannot exercise a required path in the time box, record that limitation rather than implementing a bypass.
- **R12. Measurement silently becomes product implementation.** End at the time limit. Report which candidate constraints passed, failed or remain unknown. Remove scratch code. Carry successful findings into the leaf's design and tests without calling them final acceptance evidence.

### Missing question

Does the operator approve this time box and its scoped test surface? If not, the successor plan must still resolve the mechanism before implementing it, and the handoff should name the unresolved risk. Failure or timeout does not authorize whole-body editing, a compiled extension, or a silent switch to another design.
