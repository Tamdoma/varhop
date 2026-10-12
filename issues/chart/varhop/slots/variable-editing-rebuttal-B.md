# Variable editing: slot B rebuttal

Read 2026-10-12: merged notes and A/B/C notes. Only disputed points and one concession follow.

- **D-a. Keep immutable prose outside the writable input.** C's restore-after-change verifier adds rollback and suspends verification during composition. It does not demonstrate correct attribution of every mutation to the active value. My proposed inline native value input also needs a layout/input proof, but removes writable prose from the input boundary. Put interception on the focused editor: BeforeItem precedes that item's handling, not its focused descendant's. Evidence: B E8, [Qt Keys priority](https://doc.qt.io/qt-6/qml-qtquick-keys.html#key-handling-priorities), read 2026-10-12. The PanelKeyCatcher comment cited by C is incorrect on this point.

- **D-b. Keep empty distinct from unset.** Delete should produce an intentional empty value. Explicit Reset restores the original token. C's choice makes removing an optional substitution impossible without exporting its token or a fabricated space. Evidence: B D3/R5 and the source-based export contract. No operator requirement excludes empty strings. Undo cannot replace Reset after several edits or revisits.

- **D-c. Recommend Enter inserts a newline.** Tab already advances. C's Enter-as-next adds a second navigation key and changes native multiline editing. Espanso submits with Ctrl+Enter, which does not establish Enter-as-next. Evidence: [Espanso forms](https://espanso.org/docs/matches/forms/), read 2026-10-12, and B's native multiline-input recommendation. This is my explicit position now, not a correction to the merge's “not specified” tag.

- **D-d. Retain `[A-Z0-9_]+`.** The lock names the allowed characters without a first-character exception. Both stricter proposals add one. C's claim that every template language follows the same identifier rule is unsupported and unnecessary for data keys that are never executed. Evidence: `forks/repo-format.md:25` and B D4. Treat a stricter rule as an operator choice, not a technical requirement.

- **D-f. Provide per-variable semantic undo/redo, including Reset and mirrors.** Silently ignoring Ctrl+Z is not an equivalent implementation. Native text undo alone cannot distinguish unset from a filled literal `{{NAME}}`. Evidence: B Q8 and Qt's text-only undo API in B E7. The history must restore value state, not the entire rendered document.

- **Q3 agreement tag.** Resume behavior is not fully agreed `(B,C)`. B R2 preserves cursor and selection. C P6 reselects the whole active value on every show. Preserve the exact pre-hide state so returning from the browser does not unexpectedly replace the whole value on the next keystroke. Evidence: `variable-editing-B.md` R2 versus `variable-editing-C.md` P6. Tag preservation `(B)` and reselection `(C)` until settled.

- **Pasted-value fidelity.** “Accept LF for values” resolves only part of the issue. Qt also changes NBSP to space and Unicode separators to LF. Source-based export preserves the body, not values already read through those conversions. Settle the complete normalization policy or prove an exact extraction path before handoff. Evidence: B E10/R9/Q10, [Qt 6.12 QTextDocument source](https://raw.githubusercontent.com/qt/qtbase/v6.12.0/src/gui/text/qtextdocument.cpp), lines 1213-1251, read 2026-10-12. Also retain B Q9's unresolved front-matter boundary under importer ownership.

Concede **D-e**: literal outer braces plus the inner token uses the existing token matcher without an extra brace-run exclusion. Literal examples must use the locked escape. This replaces my earlier whole-run-literal recommendation.
