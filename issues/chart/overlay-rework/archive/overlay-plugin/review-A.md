# Review A — overlay-plugin

Base `5cac0ae`, reviewed head `61c742e` (13 commits, +2471). Verdict: **fix**.

## F1 — Every copy after the first writes nothing (criterion 6a)

Realistic source: real user action — pressing Ctrl+C in the editor a second time (or any second prompt copy in one shell session), reproduced live.

`qml/Copier.qml` `copy()` spawns `proc` once per call and `onStarted` does `write(pendingText); stdinEnabled = false`. `stdinEnabled` is a real property that stays false, so the second spawn runs `wl-copy` with stdin closed immediately — `wl-copy` exits and the previous clipboard content survives. Verified live: first copy put the rebuilt text on `wl-paste` exactly; a later copy produced the banner "wl-copy exited" and `wl-paste` still returned the old content. A standalone `quickshell -p` probe confirms `stdinEnabled` reads false on the second `running = true` (`SPAWN round 2 stdin=false`).

Consequence today: criterion 6a (Ctrl+C puts exactly the rebuilt text on the clipboard, ends the draft, hides) holds only for the first copy of a session; every subsequent copy shows an error and keeps the overlay open. `tst_copier.qml` misses it because it creates a fresh Copier per case.

Fix shape: reset `proc.stdinEnabled = true` before `proc.running = true` in `copy()`.

## F2 — Edits to a resumed draft are dropped on the next hide (criterion 5f)

Realistic source: real user action — resume a draft, keep typing, press Esc, reopen. Reproduced live: field contained "ZZZ" after first hide; typed "MORE", Esc'd, re-summoned; editor showed "ZZZ" — the second edit was gone.

`Varhop.qml close()` guards the capture with `draft === null`:

```qml
if (view === "editor" && editorLoader.item && draft === null && currentPrompt) {
    if (currentPrompt.names.length > 0) draft = editorLoader.item.captureDraft()
}
```

After `route()` restores a draft, `draft` is non-null, so the next `close()` never calls `captureDraft()` and the pre-resume object survives stale. Criterion 5f (hide, then summon, resumes the draft) silently drops any editing done after a resume. The `draft === null` condition also isn't needed — `captureDraft()` is safe to run unconditionally here.

## F3 — Criterion 4g unverified (p95 ≤ 50 ms at 500–5000 prompts)

The proof map's only latency evidence is 8 keystrokes on the real 4-prompt library (1–15 ms). The criterion names 500/2000/5000-prompt runs via `test/make-library.sh`. `SearchBody`'s `Repeater` instantiates one delegate per ranked row, so at 5000 results the row-build cost lands inside the key→frame window and `rank`'s own body scan is ~43 ms alone at that size. Whether p95 stays under 50 ms is unknown, and the plan's stated fallback (chunked rows / `Qt.callLater`) is not implemented.

This is missing verification evidence for a named criterion; run `make-library.sh` at the three sizes and take the p95, or fix the wiring if red.

## Nits

- `rebuildRows()` does an O(n²) inner scan to map ranked ids back to prompts (~250K comparisons at 5000 — measurable but not the criterion's blocker; a `Map` would be one line).
- `repoField` takes `forceActiveFocus()` whenever settings becomes visible, so opening settings with Ctrl+, steals focus from list navigation into the typed field. Cosmetic annoyance; keys still route through `handleKey`.
- `retryStatus`/`retryRepos` keep firing forever until success — fine, they stop once data lands, but a dead `varhop-sync` would loop quietly (no user-visible error). Low impact: `gh`-less envs aren't the target.
- `README` says "re-check `hyprctl binds -j` before pasting" — good; the settings chord field's live `binds` probe exists but `bindsProc` can spawn-fail at boot like the other probes (no retry timer on it — actually it has one via the manifest-gated refreshBinds, but bindsProc has no retry Timer; cosmetic because the chord field still works with an empty list, just no conflict warning until re-open).

## Evidence notes

- `bun test`: 75 pass under `run-check` verbatim command.
- Live: summon layer 3 on all 3 monitors; selection saved to shell.json and byte-identical across `omarchy plugin update`; sync→accept→library.json `{status:"ok"}` with 4 prompts; usage file written; draft pin row + Ctrl+Shift+P resume path verified end to end.
