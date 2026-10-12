# search: blind notes (slot A)

Read 2026-10-12. Tiers: [OP], [SRC], [DOC], [MK].

## Q1 Fields
Pick: title (front matter or file name), category, subcategory, tags, description, then body. Weights in that order; body only as a low-weight substring match. Reason: the user remembers a name or topic; body hits help when they remember a phrase. Cost: body search on low thousands of prompts per keystroke needs a precomputed lowercase, folded copy per prompt (built at index time).
Rejected: title only (forgotten names have no way in); body equal weight (long prompts flood results).

## Q2 Matching
Pick: Omarchy AppSearch shape: every whitespace term must match somewhere (AND), scored by tier: title prefix > title substring > category/tag > description > body substring > subsequence/acronym on title. Fold case and diacritics on both sides: `normalize("NFD")` then strip combining marks, plus a map for đ→d, Đ→D (and ł, ø, ß as cheap extras). Suggestions are the ranked list itself, top row preselected, updated per keystroke; no inline ghost completion. Reason: first-party precedent is /usr/share/omarchy/shell/services/AppSearch.js:49-95 (term AND, tiered fuzzyScore). But its `wordText`/`words` split on `[^a-z0-9]` (:26-40), so `č` breaks words: varhop needs its own folding before matching. Cost: a varhop-local copy of the scoring idea (third-party plugins cannot import services/ by path safely [MK]).
Rejected: fzf-style full subsequence scoring over all fields (noisy on body text, more code); fuse.js (vendor, Bitap typo tolerance not needed for short titles).

## Q3 Ranking and empty query
Pick: text score first, then use frequency as a tiebreak inside a tier (copy count, decayed), from a small JSON state file in `~/.local/state/varhop/usage.json`. Empty query: recently used first (up to ~8), then all prompts grouped by category, alphabetical. Reason: Google-like means the likely pick floats up; browse path for forgotten names [C2 M3]. Cost: one state file written per copy.
Rejected: no usage signal (stale order); usage over text score (wrong prompt beats exact title).

## Q4 Rows and keys
Pick: row = title, dim `category / subcategory` label, first line of description if any; draft marker if a draft exists. Up/Down move, Enter opens, mouse click opens, scrolling list with no hard cap. Selection is held by prompt id; after a manual pull the same id stays selected if present, else the top row. Reason: intake up/down + Enter [OP]; first-party lists do the same. Cost: none notable.

## Pitfalls
- P1 Per-keystroke cost at 2000 prompts with body text: precompute folded strings at index time; measure in the leaf (target under 16 ms).
- P2 `đ` does not decompose under NFD: explicit map; fixture "Đorđe" matches "dorde".
- P3 Usage file corrupt: treat as empty and rewrite, show nothing (state, not user data).

## Questions not asked
- Q5 Should Tab in search do anything (complete the top title?) or nothing, since Tab belongs to the editor?
