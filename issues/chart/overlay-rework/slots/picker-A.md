# Picker notes, slot A (blind), 2026-10-13

Pick:
- Match: case- and accent-insensitive with lib/fold.mjs. Every space-separated word of the field must appear in `fullName`.
- Order: exact full name first, then names whose repo part starts with the text, then the rest in /user/repos order.
- Highlight: the first match is highlighted with `menu.selectedBackground`. Up and Down move the highlight and the list scrolls to keep it visible. Enter selects the highlighted row through the same `repoChosen` path a click uses.
- No match: if the text matches `owner/repo` (repoRe), Enter takes the existing typed path (repoProc validation). Otherwise Enter shows "no match" and does nothing.
- Empty field: the full list with the first row highlighted.

Reason: this is the fzf, VS Code quick pick and Omarchy menu shape. Typing narrows, the top row is the default, and Enter takes it. It also covers repos not in the list (orgs and grants) through the existing validated path.

Cost: a small pure filter function in lib/ with unit tests, plus a highlight index in SettingsBody.

Rejected:
- Fuzzy subsequence scoring like the prompt search (overkill for about 100 names, and surprising matches).
- Filtering without a highlight (Enter would still need an exact name, which is F1).

Evidence: SettingsBody.qml:188-234 (plain Repeater, Enter calls repoTyped on raw text). Varhop.qml:900-910 (chosen vs typed paths). lib/fold.mjs.

Pitfalls:
- Repos load once and an empty list on failure is silent (Varhop.qml:586-598). Show the load error and a retry instead of an empty picker.
- Rows are 26px fixed, and the look fork wants token heights.
