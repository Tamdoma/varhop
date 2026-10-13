# Picker fork, merged notes (A), 2026-10-13

Sources: picker-A.md, picker-B.md, picker-C.md.

## Ground
- 161 repos from /user/repos today (C, gh api count). The list paginates at 100 (B,C). Rows carry fullName, id and private (B,C).
- Choosing a repo starts a sync and save, and with a draft it goes through the discard warning (B,C, Varhop.qml:328-338).
- A repos load failure shows as an empty list, retried every 1.5 s (A,B,C, Varhop.qml:583-601).
- The filter runs inside SettingsBody on the repos prop. The sync contract is unchanged (B,C).

## Q1 match and order
- Case-insensitive literal substring of the trimmed text on fullName, sorted alphabetically by lowercased fullName (B,C).
- Exact full-name match: moved to first (B), or never reorders and wins only at Enter (C), or ranked first with prefix second (A).
- Multi-word: every word must match (A), one literal term (B,C).
- Rejected: fuzzy or subsequence scoring (A,B,C). GitHub per-keystroke search (B). API order, which is created-descending (C).

## Q2 Enter
- Enter activates the visible highlight through the same path a click uses. After every text change the first match is highlighted (A,B,C).
- Empty field: Enter picks the first row (A,B) vs Enter does nothing, because a stray Enter would sync the alphabetically first repo, someone else's apphutdev/aiva (C).
- A highlight moved after the last text change beats exact text (C).
- One match does not auto-pick while typing (B,C).

## Q3 typed repo not in the list
- Keep the existing validated lookup (A,B,C).
- B: a visible "Look up owner/repo" candidate first when the text is valid and not an exact listed match.
- C: lookup only when no row is highlighted (zero matches).
- A note: partial typing like `Tamdoma/var` is already valid owner/repo syntax, so B's first-row lookup would capture Enter mid-typing. A proposes the lookup row last in the list (first when there are no matches), so it stays visible but never beats a real match.

## Q4 keyboard reach
- Up and Down move the highlight in the field (A,B,C). Wrap (C) vs clamp (B).
- Tab: each row a Tab stop, then Sync now (B), vs the picker is one control where Tab reaches the field and rows are reached by typing and arrows. 161 Tab stops is unusable, and no first-party picker does it (C). This reads the proof-bar Tab+Enter carry as per control, not per row, so it needs the operator's word.
- Esc clears a non-empty filter first (C).

## List and states (agreed, no operator question)
- A bounded ListView about 8 rows tall, keeping the highlight in view (C). Hidden rows never sit in the Tab chain (B).
- Three distinct lines: loading, could not list (typed path still available), no match (B,C).
- A "current" marker on the selected repo (C).
- Locks the input while a lookup or switch is pending, bound to the submitted text (B).

## Questions surfaced
- Enter or click on the already selected repo: re-sync, refuse, or full switch as today (C).
- PageUp, PageDown, Home and End in the list (C).

## Rebuttal corrections
- /user/repos defaults to sort=full_name ascending, not created (B rebuttal F1). Local sort is kept for a stable contract.
- Exact-match priority must be visible before Enter (B F2). Compromise: no reordering. After a text change the highlight goes to the exact match if listed, else the first row (A).
- After an async list refresh, keep the highlight by repo ID. If it disappears, clear the highlight (B F3).
- No highlight on an empty field, so Enter does nothing (C 1). No reordering (C 2). No synthetic lookup row (C 3). Wrap like search (C 6). Input lock was C's open question, not agreement, and is dropped. Lookup results apply only if the field still holds the submitted text (C 5).
- Tab per row vs one composite control stays an operator decision (B, C 4).
