# Picker fork: blind notes, Slot B

2026-10-13. Read picker Question and Carries, permitted existing context and source. No other slots' picker notes read. No desktop or GitHub operations performed. These are proposed choices, not operator decisions.

## Q1. What matches, and in what order?

### Pick, reason and cost

Filter locally on each edit using a case-insensitive literal substring of the full `owner/repo`. Trim leading/trailing whitespace for matching without rewriting the field. Keep punctuation literal. Empty or whitespace-only input shows all loaded repos. Sort case-insensitively by full name, with an exact full-name match first. Do not rank by recent use or request GitHub on each keystroke.

Examples: `varhop` matches both granted prompt repos, `TAMDOMA/` matches that owner regardless of case, and `prompts-b` narrows to the second repo. `varhop prompts` is one literal query, not two independently matched words.

Reason: predictable matching on the identifier the user sees, without a new scoring model. Cost: abbreviations such as `vhp` do not match `varhop-prompts`, and exact-match promotion moves one row from alphabetical order.

### Rejected options

- Exact-only matching preserves the reported failure.
- Prefix-only matching cannot find a repository by name when its owner prefixes the displayed identifier.
- Fuzzy matching or word-token matching adds semantics not required by F1. Choose fuzzy only if abbreviation matching is an explicit preference.
- GitHub search per keypress introduces remote latency and a different search universe when the loaded repo list already exists.

### Evidence, tier, source and date

- **Operator**, picker Carries and INTAKE F1, read 2026-10-13: typing currently does not filter.
- **Practitioner**, Microsoft VS Code team, [Quick Picks guidance](https://code.visualstudio.com/api/ux-guidelines/quick-picks), read 2026-10-13: its deployed picker pattern combines typed filtering with list selection and concise context. This supports a single filterable chooser, not any particular substring algorithm.
- **Better-than-training**, worktree `qml/SettingsBody.qml:191-234`, read 2026-10-13: field text is submitted independently while the Repeater reads `root.repos` unchanged.
- **Better-than-training**, worktree `bin/varhop-sync:86-89` and [GitHub's authenticated-user repository endpoint](https://docs.github.com/en/rest/repos/repos#list-repositories-for-the-authenticated-user), read 2026-10-13: listing already paginates, and GitHub defaults to full-name ascending order. Preserve full-list filtering rather than adding a first-100 limit. Local explicit sorting makes the UI contract independent of arrival order.

### Pitfalls and removal

Filter copies/references to repository records, retaining IDs and canonical full names. Do not select by the original array index after filtering. Cover owner substrings, repo substrings, mixed case, literal punctuation, surrounding whitespace and a match after row 100 in component tests. The same-name/different-owner case must display both full identifiers.

### Missing question

Does the operator actually want abbreviation/fuzzy matching? The current complaint establishes filtering, not that algorithm. Recommend literal substring unless they ask for abbreviations.

## Q2. What does Enter do for zero, one or many results?

### Pick, reason and cost

Enter activates the visibly highlighted candidate through the same action as clicking it. After a user changes the query, highlight the first candidate. One match therefore needs one Enter. With several matches, Enter chooses the first unless the user moves the highlight. An exact full-name match is first, so entering that identifier preserves the existing direct-selection result.

With no candidate, Enter performs no repository operation and the view explains that there is no match or asks for a complete owner/repo. A lookup candidate for a valid unlisted identifier is covered in Q3. Empty input shows all repos and highlights the first, so Enter selects that visible first repo. Clearing input only resets the filter, never clears the configured repository.

Reason: Enter always has a visible target instead of switching between hidden rules. Cost: pressing Enter with many results accepts the top one. The selected color must be clear before activation.

### Rejected options

- Choose only when exactly one result remains: requires unnecessary typing even when the intended first result is visibly selected.
- Open a second ambiguity dialog for multiple results: the list already lets the user resolve ambiguity.
- Submit raw field text regardless of the highlight: typing `varhop` would still fail instead of selecting a displayed result.
- First Enter highlights and second Enter activates: Emojis demonstrates this mode, but it adds a keystroke without benefit when this picker already shows an initial highlight.

### Evidence, tier, source and date

- **Operator**, F1 and proof-bar Taken, read 2026-10-13: selection must work from the keyboard.
- **Better-than-training**, `/usr/share/omarchy/shell/plugins/emojis/Emojis.qml:208-224`, read 2026-10-13: separates navigation from activation and makes Enter act on an active index. Its first-Enter activation mode is a reference, not a requirement to copy.
- **Better-than-training**, worktree `Varhop.qml:328-336,899-910`, read 2026-10-13: listed and typed paths converge on repo switching, with draft-discard confirmation before a changed repository is used. Preserve that behavior.

### Pitfalls and removal

Keep the keyboard candidate distinct from the saved repository, which remains identified separately. Highlighting must not save or sync. On a background list replacement, retain the active repository by ID if still present. If it disappears, clear the active candidate until the next query edit or explicit navigation rather than silently targeting a different repo at the old index. Test zero/one/many, exact match among longer matches, clear input, refresh and draft confirmation. Navigation never discards a draft.

### Missing question

Is choosing the visible first repo on empty-field Enter acceptable, or should blank input require explicit row navigation first? Recommend the same highlighted-candidate rule for consistency, with the tradeoff stated above.

## Q3. Can a complete typed repository outside the list still be used?

### Pick, reason and cost

Yes. When trimmed input passes the existing owner/repo syntax boundary and there is no case-insensitive exact listed match, show a distinct first candidate labeled `Look up owner/repo`. Keep any substring matches below it. Enter or clicking that row performs the existing explicit lookup. This is a candidate action, not a claim that the repo exists. A listed exact match suppresses this extra row and uses its canonical identifier and ID.

Reason: preserves the current typed escape path while keeping Enter's target visible. Cost: a complete but nonexistent identifier can rank above longer valid listed names. Its `Look up` label must make that difference clear. Failure stays in settings with the query and previous committed repo intact.

### Rejected options

- Require list membership: an accessible repo can be absent from this authenticated-user list, and direct lookup already exists.
- Silently prioritize a raw typed lookup over a highlighted row: breaks the rule that Enter activates what is visibly selected.
- Add a second permanent input or a new shortcut: duplicates a flow already available in this field.
- Automatically look up every syntactically complete query while typing: creates network work before an explicit choice.

### Evidence, tier, source and date

- **Better-than-training**, worktree `bin/varhop-sync:86-97`, `Varhop.qml:308,603-614,905-909`, read 2026-10-13: listing and individual repo lookup are separate existing operations. Lookup yields a canonical name and repo ID before choosing.
- **Better-than-training**, [GitHub repository listing documentation](https://docs.github.com/en/rest/repos/repos#list-repositories-for-the-authenticated-user), read 2026-10-13: the list covers the authenticated user's owner/collaborator/organization affiliations, not every public repository accessible by name. List absence is not proof of inaccessibility.
- **Practitioner**, Microsoft's Quick Picks guidance cited in Q1, read 2026-10-13: permits a visibly distinct additional action when picking from a list. Applying that pattern to lookup is my recommendation, not Microsoft's prescribed GitHub behavior.

### Pitfalls and removal

Activate once per deliberate action. Disable repeat repo activation while lookup/switch is pending and bind the result to the submitted identifier, not later field text. A query edit must never retarget an in-flight lookup. Preserve the existing account/repo identity checks and staged commit path. Component proof covers typed-but-absent, absent with longer substring matches, malformed text, lookup failure and repeated Enter. Live proof stays within the already granted repo pair and ends back on `Tamdoma/varhop-prompts`.

### Missing question

None beyond deciding whether the visible lookup candidate is preferred to a separate explicit lookup button. Both retain the typed capability, but the candidate keeps one activation model.

## Q4. How do arrows and Tab reach the picker and other settings?

### Pick, reason and cost

Up/Down in the filter move the active candidate without changing the query, clamping at the first/last row. Left/Right, Home/End and text-selection shortcuts retain normal field editing. Enter activates the current candidate. Tab leaves the field for candidates in displayed order, then the next settings control. Shift+Tab reverses that order. Each candidate is a real focusable action: focusing it updates the highlight, and Enter or click uses the same activation path. Scroll the focused/highlighted candidate into view.

Reason: fast arrow navigation plus the already settled Tab+Enter reach for every action. Cost: a large unfiltered list takes many Tab presses. Typing narrows it, and this cost does not justify violating the accepted keyboard contract.

### Rejected options

- Arrows as the only way to reach rows: does not meet the explicit Tab+Enter carry.
- Tab autocompletes or cycles within the picker indefinitely: blocks access to Sync now and other settings controls.
- Leave MouseArea-only rows and add Enter only to the field: does not make each row keyboard-reachable.
- Change the editor's variable Tab cycle: unrelated and explicitly preserved.

### Evidence, tier, source and date

- **Operator**, `forks/proof-bar.md` Taken Q4, read 2026-10-13: every mouse action must be reachable with Tab and activated by Enter, through the same action path.
- **Better-than-training**, worktree `qml/SettingsBody.qml:219-234` and `Varhop.qml:899-910`, read 2026-10-13: repo rows currently rely on MouseArea while the root already provides shared selection signals.
- **Better-than-training**, installed Emojis key handling cited in Q2, read 2026-10-13: active-candidate navigation is an established local pattern. It does not override this task's stronger Tab requirement.

### Pitfalls and removal

Keep focus and highlight aligned, including when a filtered row disappears. Do not retain hidden delegates in the Tab chain. Component tests must reach a non-first repo and then Sync now using Tab+Enter alone, reverse with Shift+Tab, and verify focused rows scroll into view. Loading, failed loading and an actually empty list need distinct status text: existing `reposProc` collapses failures to `[]` at `Varhop.qml:591-598`, so that cannot truthfully become “No matching repositories.” Carry this narrow state distinction into the picker implementation, not a broader sync redesign.

### Missing question

No further operator choice is needed for Tab reach because it is already settled. Arrow clamping rather than wrapping is a small proposed behavior within this question.
