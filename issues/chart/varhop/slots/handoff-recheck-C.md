# Handoff re-check: slot C (remaining disagreements only, 2026-10-13)

R1. Prepared search keys still have no home in the typed contract.
- Draft: prompt-core/design.md:86 `Prompt = {id (path), category, subcategory | null, fileName, title, description | null, tags: string[], body: string, segments: Segment[], names: string[]}` and :90 `rank(prompts, query, usage, now)`; overlay-plugin/design.md:143 consumes them "exactly as typed".
- Fix: add the precomputed folded search fields (including folded body and whatever offset data the snippet needs) to `Prompt`, or make import return a prepared search index that `rank` takes. As typed, `rank` must re-fold every field on every keystroke or add undeclared fields.
- Evidence: search Findings settle "folded keys precomputed at import" (forks/search.md:19). At the latency fixture scale (5000 prompts, half with 20 KB bodies, overlay-plugin/brief.md:41) re-folding bodies per keystroke cannot meet the operator's p95 ≤ 50 ms (forks/search.md:29).

R2. The owner/repo pattern still accepts a case criterion 5 refuses.
- Draft: repo-sync/design.md:82 pattern `^[A-Za-z0-9-]{1,39}/[A-Za-z0-9._-]{1,100}$`; repo-sync/brief.md:29 requires `-x/y` to be refused with exit 2.
- Fix: require the owner's first character to be alphanumeric in the pinned pattern. The current regex matches `-x/y`, so an implementer who implements the design's pattern verbatim fails the brief's own criterion.

R3. "The journal shows no varhop-sync run" is not evidence with the stated machinery.
- Draft: overlay-plugin/brief.md:26 criterion ends "The journal shows no `varhop-sync` run." The only mandated journal logging in overlay-plugin/design.md:151 is per-search latency lines; nothing logs sync invocations, and a QML `Process` child's captured stdout/stderr does not reach the journal.
- Fix: either require a structured sync-start log line in Leaf architecture, or replace the evidence with `library.json` sha256 and `fetchedAt` unchanged across the restart-and-summon (any sync republishes the bundle with a new `fetchedAt`, repo-sync/design.md:76). Absence of a journal line currently proves nothing either way.
