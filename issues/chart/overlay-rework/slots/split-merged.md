# Split merged (A, B, C), 2026-10-13

## Agreed
- Owner stays issues/open/varhop/ISSUE.md, seat block there before any state.yaml (A,B,C). C adds: owner completion closes varhop only when every leaf under it is merged, so a new owner would strand it.
- prompt-core and repo-sync are merged, no new ordering for them (A,B,C).
- The unmerged base 0df6f48 (33 ahead of main, main has no plugin) is a real dependency, not file overlap. No rework leaf can branch from main (A,B,C).
- No parallel feature leaves for editor, look, picker, controls. Live runs share one desktop and the final-build criteria need one owner (A,B,C).
- No proof-only close-out leaf. The product owner runs the final live sweep and fixes what it finds (B,C).
- Live-proof machinery (a reusable uinput keyboard sender with a known-good pass and a deliberate-break fail) is absent on main. The skill requires it on main before a criterion relies on it, through a prerequisite or a narrowed criterion (B,C). A missed this. A corrects: a prerequisite is needed.

## Disagreements
- T1 tree:
  - B: two leaves. `overlay-proof-tools` (small, from main, machinery only) first, then `overlay-plugin` = adopted base plus all five forks, sources Tamdoma/varhop#1, blocked-by tools. A now agrees.
  - C: two leaves. `overlay-plugin` lands the base unchanged plus the committed uinput helper and a smoke, no seed source. Then `overlay-rework` does all five forks, closes the seed, blocked-by overlay-plugin. C's reason: the rework review reads only the rework diff, and a bad fork cannot hold the base back.
  - B's objection in advance: a base-only landing changes what the chosen `overlay-plugin` successor delivers (disposal 4a says it carries the seed) and lands a version the operator called clunky.
- T2 helper location: separate prerequisite leaf (B) vs inside the base leaf under test/, shipped with the plugin (C).

## Rebuttal corrections
- "No parallel feature leaves" is B's recommendation to bundle, not a rule. After a separately landed base, feature leaves could run in parallel. Live sessions serialize, implementation does not (B).
- The machinery must show an observable expected input result and catch a deliberate break, with cleanup both ways. A successful send alone does not count. Final resume and copy assertions stay with the product owner (B).
- Landing the base installs nothing. The desktop copy stays at 0df6f48 under either tree (disposal 3a). The seed closes at owner completion either way (C).
- A tools leaf on main has no plugin to drive. C's base leaf gives the helper a real consumer (its own smoke) in the same merge (C).
- T2 is no difference: the repo root is the plugin root, so the helper ships in the installed clone under either tree (C).
