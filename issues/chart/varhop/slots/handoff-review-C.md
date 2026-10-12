# Handoff review: slot C (disagreements only, 2026-10-13)

Draft paths below are under the handoff drafts `varhop/` tree.

H1. repo-sync's file:// fixtures cannot run through its own interface.
- Draft: repo-sync/brief.md:7 `sync <owner/repo> <cache-dir>` and :19 "Against a local `file://` fixture repo"; repo-sync/design.md:69 fixes the argument to `^[A-Za-z0-9-]{1,39}/[A-Za-z0-9._-]{1,100}$`.
- Fix: name the test-only remote mechanism (for example an env override for the git base URL that production never sets), and state what `identity`, repo-id lookup, and the gh credential helper do in that mode. As written, a file:// remote is rejected by the CLI's own validation, and a synthetic `owner/repo` would be cloned from github.com.
- Evidence: criterion 3 is the leaf's main failure-path proof (failed fetch, second commit, attributes); none of it is reachable through the specified argv.

H2. `sync` publishes before identity reconfirmation, and repo switching into the slots is undefined.
- Draft: repo-sync/brief.md:7 "refresh the inactive clone slot, switch slots, and write a library bundle"; brief.md:11 bundle carries repo id.
- Fix: give `sync` expected account-id/repo-id inputs (nullable on first selection), validated before clone and before any slot switch; state what happens when the inactive slot's origin is a different repo (reclone it); build and validate the bundle from the inactive slot and only then switch `active` and rename the bundle. Add a fixture: sync repo A, then sync repo B publishes B, and a failed B leaves A's bundle and active slot untouched.
- Evidence: sync-and-auth Taken (design.md:9-12 in this leaf) requires switch only after fetch/checkout/read/index succeed, old library kept until the new one imports, and account/repo mismatch asking to reconfirm. A CLI that switches slots internally and only reports the repo id in the finished bundle lets a recreated same-name repo replace the library before the overlay can compare ids.

H3. The CLI contract the overlay must consume is not pinned.
- Draft: repo-sync/brief.md:5-6 (`identity`: login and account id), :9 "a per-operation timeout"; design.md:69 "each failure class has its own nonzero code" with no classes, codes, timeout values, or success-object schema; brief.md:23 statuses with no exit-code rule.
- Fix: pin the success JSON per subcommand, the error classes/codes, the numeric timeouts, and whether `empty-repo`/`no-prompts` exit 0 and publish. Extend `identity` (or add `status`) to return authenticated state, scopes, and the fix string, and add a repo lookup for a typed `owner/repo`, since `/user/repos` cannot return an unaffiliated typed repo's id.
- Evidence: settings holds "gh status plus the fix" (overlay-plugin/design.md:58) and sync Taken requires the strictly validated typed repo (repo-sync/design.md:13). Login+id alone cannot render the gh status line or save a typed selection's repo id before sync (H2).

H4. prompt-core owns a fixture it cannot receive, and "reproduces the body exactly" contradicts the escape rule.
- Draft: prompt-core/brief.md:5 import takes decoded `text`; design.md:39-41 lists invalid UTF-8 "validated at the raw-data boundary (FileView data vs text)" among prompt-core fixtures; repo-sync/design.md:56 assigns that validation to repo-sync. prompt-core/brief.md:20 "Rebuild with no values set reproduces the body exactly"; design.md:86 Segment has no escape kind.
- Fix: strike invalid UTF-8 from prompt-core's fixture list (repo-sync criterion 4 already proves it at its boundary, via iconv, not FileView). Define the escape as a text segment holding the literal `{{NAME}}`, and reword criterion 4 to "reproduces the body exactly except `\{{` escapes come out as `{{`", with that case in the fixtures.
- Evidence: repo-format Taken (prompt-core/design.md:12) says only tokens and the `\{{` escape are interpreted, so an escaped body cannot round-trip byte-exact through rebuild.

H5. prompt-core leaves two visible behaviors to guess and never proves subsequence ranking.
- Draft: prompt-core/brief.md:18 "title defaulting to the file name" and "Deeper files produce an error note"; brief.md:21-25 search fixtures cover folding, AND, weights, body tier, frecency, empty query only.
- Fix: state whether the default title is the raw file name, the stem, or a prettified stem, and whether a deeper file is excluded from `prompts` or imported with its error. Add a subsequence fixture with an expected order (for example `cdr` matching "Code Review" ahead of a scattered match, and a transposed query matching nothing).
- Evidence: search Findings (forks/search.md:19) settle scored subsequence in the fzf V1 shape and no typo tolerance; as drafted, a substring-only matcher passes every prompt-core criterion.

H6. overlay-plugin never says how the plugin reads its own selection or the existing bundle at load.
- Draft: overlay-plugin/design.md:141-143 lists owned paths and consumed interfaces only; brief.md:22 only proves the shell.json entry "reads back" externally after a save.
- Fix: name the read path (the scoped shell API writes via `updateEntryInline` but offers an overlay no settings getter, so this means reading shell.json itself, e.g. FileView + find own entry, with watch/reload behavior stated), when library.json is loaded relative to that, and how bundle reloads after a pull are generation-tagged. Add a done-criterion: after a shell restart, summon opens search from the saved selection and existing bundle with no sync run.
- Evidence: summon routing (design.md:60) depends on "no repo selected" at every cold start, and sync Taken (design.md:93) requires generation numbers on async completions; neither has a mechanism or a criterion in this leaf.

H7. overlay done-criteria do not cover most settled editor and search runtime behavior.
- Draft: overlay-plugin/brief.md:25-35 proves open, Tab walk, mirror-on-type, copy, draft resume "with its cursor", and the owed chords.
- Fix: add observable live checks for the settled lists the design only quotes: typing in prose rejected; paste by keyboard/menu/middle-click; dead-key and IME commit (including preedit commit before Ctrl+C); multiline value; clicking a mirror edits the shared value; Delete empties, Delete again restores unset; per-variable undo/redo; resume keeps exact cursor *and selection*; a zero-variable prompt opens ready and copies; search rows show the body snippet on body-only hits and the Draft marker; the pinned Resume row is visible and clickable; selection after a manual pull follows the prompt id.
- Evidence: variable-editing Findings name exactly this proof list "either way" (forks/variable-editing.md:20) and Taken sets the behaviors (overlay-plugin/design.md:31-33); search Findings set the row/snippet/pinned-row rules (forks/search.md:19). As drafted, an editor that lets prose be typed over passes.

H8. overlay has no criterion for the settings displays it must render or for identity mismatch.
- Draft: overlay-plugin/brief.md:19-24 covers first run, one happy-path selection, read-back, Ctrl+,/Esc, and the chord field only; design.md:58 lists last successful pull, last error, and load errors as settings contents.
- Fix: add criteria that settings shows the gh fix when unauthenticated, the last pull time and a failed pull's error, and merged load errors (bundle errors without line numbers plus prompt-core errors with them); that a typed unaffiliated `owner/repo` can be selected and a malformed one refused in the UI; and that an account/repo-id mismatch routes to reconfirm before the selection save (depends on H2/H3).
- Evidence: settings Taken (design.md:57-59) and sync Taken (design.md:94-95). These are wiring behaviors only this leaf can prove.

H9. The latency criterion is not observable as written.
- Draft: overlay-plugin/brief.md:36 "recorded against the design's budget"; design.md:146 "one keystroke-to-render frame budget".
- Fix: pin the number and the measured span (search Findings propose p95 ≤ 50 ms at 5000, forks/search.md:19; state whether that is keystroke-to-model or to rendered frame), and state how the 500/2000/5000 synthetic libraries reach the live plugin (generated bundle written where, under what selection), since that setup depends on H1 and H6.
- Evidence: "a frame budget" can be read as 16 ms or as "one frame, whenever it comes"; an implementer cannot pass or fail it.

H10. Lifecycle proof and readiness metadata are incomplete in two places.
- Draft: overlay-plugin/design.md:84 lists "Update keeps the selection" as a proof item, but brief.md:37 has no update criterion and readiness.yaml:39 grants add/enable/disable/remove operations without update. repo-sync/readiness.yaml:19 and overlay-plugin/readiness.yaml:43 both say `retained: []`.
- Fix: either add the update criterion and grant operation (from the local repo, with its commit step named) or explicitly exclude the update proof. Record Tamdoma/varhop-prompts under `retained` in both readiness files.
- Evidence: proofs-sync.md records the repo as "Created and retained by agreement… No removal date"; the readiness shape (chart-issues shapes.md `retained:`) is where kept external resources live, not the grant narrative.

H11. Real-call criteria are ambiguous between committed tests and one-time leaf proofs.
- Draft: repo-sync/design.md:68 "its tests (bun:test spawning the CLI against file:// fixtures in temp dirs, plus the two real-call criteria against Tamdoma/varhop-prompts)"; prompt-core/design.md:93 sets the repo check to `bun test --pass-with-no-tests` (already in issues/config.yaml `checks.test`).
- Fix: state that the two real GitHub calls are recorded leaf proof commands, not bun tests in the tree (or env-gate them out of the root check). Otherwise every later leaf's blocking test check performs live GitHub reads under the operator's gh login.
- Evidence: the grant bounds those reads as leaf operations (repo-sync/readiness.yaml:17); a committed test re-runs them unbounded on every check.
