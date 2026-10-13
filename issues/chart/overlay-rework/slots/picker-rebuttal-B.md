# Picker rebuttal, Slot B

Read only picker-merged.md for this pass.

- **F1. Correct the API-order claim.** “API order, which is created-descending” conflicts with the endpoint evidence in my initial notes: `/user/repos` defaults to `full_name` ascending. Keep explicit local sorting for a stable UI contract, but do not justify it with that incorrect default.

- **F2. Keep Enter tied to the visible target.** C's “exact match wins only at Enter” cannot be combined with the stated agreement that Enter activates the highlight unless that exact match is already highlighted. Exact-match priority must happen visibly before activation, never override a different highlighted row at Enter. A's proposal to put the explicit lookup candidate last is acceptable: it removes the partial-identifier capture while retaining a visible, reachable lookup action when listed matches exist.

- **F3. Preserve the list-refresh rule.** Resetting to the first row after a query edit is intentional. Doing so after an asynchronous list refresh can silently change what the next Enter selects. Retain the active repo by ID when it remains present. If it disappears, clear the active candidate until another query edit or explicit navigation. Carry this into implementation acceptance rather than leaving refresh behavior unspecified.

The Tab interpretation remains an operator decision as the merge already states. It must not become a settled one-control exception without that answer.
