# search: merged notes (A)

Sources: slots/search-A.md, -B.md, -C.md (2026-10-12).

## Agreed
- Fields include title (front matter or file-name default), file name, tags, category, subcategory, description; each field and each tag scored on its own, no concatenated haystack (B,C; A had per-field tiers). Every whitespace term must match some field (A,B,C; AppSearch.js:49-69, MenuModel.js:323-355).
- Matching: case-insensitive, scored subsequence over the short fields with word-start, consecutive and gap scoring in the fzf V1 linear shape, no typo tolerance, no smart case, no query syntax (B,C; A conceded from title-only acronym). Folding: lowercase, NFD, strip U+0300-U+036F, explicit đ→d, no "dj" alias (A,B,C; B QJSEngine probe and C Node probe). AppSearch is not reusable: ASCII word splitting (AppSearch.js:26-40), failed `cdr` (B probe). Folded keys precomputed at import, kept apart from original text (A,B,C). No per-character highlights in v1 (B,C).
- Presentation: ranked list under a native TextInput, top row preselected, updated per keystroke, no inline ghost completion (A,B,C). Up/Down wrap, Enter opens on first press, click opens, hover only after real movement via PointerMoveGate (B,C; Clipboard.qml:160-197, Ui/PointerMoveGate.qml). Query edits reset selection to the top; a manual pull keeps the selection by prompt id, else top (A,B,C). All matches reachable, no silent cap (B,C). Plain-text, elided rows with category path and a Draft marker; duplicate titles disambiguated (A,B,C). Empty query lists the library in category, subcategory, title order without section headers (B,C; A also).
- Latency proof in the real shell at 2000+ records (A,B,C; B proposes p95 ≤ 50 ms at 5000).

## Disagreements
- D-a Body search. A,C: body is searched as a folded substring at the lowest weight (C: terms of 3+ chars, and only when structured matches are few). B: no body search in v1; put lookup words in description/tags.
- D-b Usage ranking. A,C: count successful copies per prompt id in a state-dir file (C: namespaced by repo id), use only as a tiebreak inside the same match class; empty query starts with recently copied prompts (A ~8, C 10). B: no usage store in v1; fully deterministic order.
- D-c Row line 2. C: category path + description, or a body snippet when the hit is body-only. B: category path + file name + description. A: category path + description.
- D-d List rendering. C: model holds first 50 rows, extends by 50 near the end, "50 of 237" footer. B: ListView over all matches, ~6 rows visible. (Implementation; both keep every match reachable.)
- B Q8: a Resume action independent of the list for a draft whose prompt is filtered out or deleted; binding owed to settings-and-hotkey.
