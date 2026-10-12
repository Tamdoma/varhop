# Search

## Question
Q1. Which fields are searched (title, file name, category, subcategory, description, tags, body) and how are they weighted?
Q2. Matching: fuzzy (subsequence, typo-tolerant) vs prefix/word; case and diacritic folding (č ć ž š đ); how "Google-like suggestions" appear (inline completion of the top match vs a ranked list).
Q3. Ranking signals beyond text match: recency or frequency of use (needs a usage store), category grouping; what shows on an empty query (all, recent, by category).
Q4. Result row content and keyboard: what each row shows, Up/Down, Enter opens, mouse, how many rows, and how a manual pull keeps the selection by prompt id.

### Carries
- Operator intake: instant fuzzy search, Google-like suggestions, up/down arrows, Enter opens the prompt (INTAKE.md).
- repo-format taken: `prompts/<category>/[<subcategory>/]<name>.md`, optional front matter title, description, tags; id = path (forks/repo-format.md).
- sync-and-auth taken: library comes from a local clone; manual pull only; volatile state lives in a state-dir file, never shell.json (forks/sync-and-auth.md).
- copy-and-close taken: search Esc clears then hides; native selection copy in the search field; a draft prompt can exist while search is shown (forks/copy-and-close.md).
- C2 review M3 (slots/review-C2.md): empty-query list, diacritic folding, usage store outside shell.json, keep selection by id on refresh.

## Findings
Independent notes: slots/search-A.md, -B.md, -C.md. Merged: slots/search-merged.md. Rebuttals: slots/search-rebuttal-B.md, -C.md.
- Settled after rebuttal: fields title (or file-name default), file name, tags, category, subcategory, description, each scored on its own; every query term must match some field. Case-insensitive scored subsequence (fzf V1 linear shape), no typo tolerance, no smart case, no query syntax. Fold: lowercase, NFD, strip U+0300-U+036F, đ→d, no "dj" alias; folded keys precomputed at import. AppSearch not reusable (ASCII words, AppSearch.js:26-40; failed `cdr`, B probe). No per-character highlights. Ranked list under a native TextInput, top row preselected, no inline completion; Up/Down wrap, Enter opens, click opens, PointerMoveGate hover. Query edits reset to the top; a manual pull keeps selection by id, else the top result (C conceded). ListView over all matches with a total count footer; chunking only if the latency proof fails (C conceded). Row: title; line 2 category path and description, plus file name when the title does not identify the file. Empty query: full library by category, subcategory, title, no headers. A pinned "Resume draft" action above the results whenever a draft exists, outside ranking (B,C); its key owed to settings-and-hotkey. Real-shell latency proof at 500/2000/5000 records (B: p95 ≤ 50 ms at 5000).
- Open D-a body search. A,C: folded substring at lowest weight, terms 3+ chars, only when structured matches are few; body-only hits show a snippet. B: none in v1; ClipboardHistory.js:160-187 itself caps searched text at 8192 chars; arbitrary body size is unbounded.
- Open D-b usage. A,C: decayed frecency of successful copies per prompt id, repo-scoped state-dir file, applied only after text relevance; empty query starts with up to 10 recent copies. B: no usage store; fully stable order. If chosen, storage errors are visible, not silently reset (B, against A P3).

## Taken

2026-10-12 operator: `1a | 2a`
- D-a 1a: body searched as a folded substring at the lowest weight; terms of 3+ characters only; runs only when structured matches are few; body-only rows show a one-line snippet around the first matched term (foreclosed: metadata-only search). Long-body performance is part of the latency proof.
- D-b 2a: decayed frecency of successful whole-prompt copies per prompt id, stored in a repo-id-scoped state-dir file (never shell.json), applied only after text relevance; empty query shows up to 10 most recently copied prompts first, then the library by category. Storage errors are shown, never silently reset (foreclosed: no usage store).
- All Settled items in Findings stand as presented and not objected.

Handoff review amendment (2026-10-13, operator `2a`; raised by B F7, C H9): the latency target is p95 ≤ 50 ms from keystroke to updated results at 5000 prompts, including long bodies. A slower result fails. Foreclosed: ≤ 16 ms.
