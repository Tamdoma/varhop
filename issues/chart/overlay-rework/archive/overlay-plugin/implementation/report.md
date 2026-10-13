# overlay-plugin implementation report

Serial-solo run (every wave held one unit). Base `5cac0ae`, head `49db1ef`
(10 commits over base; tests were already committed at `b9cce1f`).

## Changed files

- `manifest.json` — plugin id `ivan.varhop`, kinds `["overlay"]`, keepLoaded, entry `Varhop.qml`.
- `Varhop.qml` — OverlayWindow wiring, shell API (`summon`/`hide`/`updateEntryInline`), view routing, draft ownership, shell.json selection read/write with read-back, varhop-sync process flow (status/repos/repo/binds/sync/accept with generation guard and identity-mismatch path), usage state, FileViews.
- `qml/{SearchBody,EditorBody,SettingsBody,Copier}.qml`, `qml/FieldKeys.js` — Quickshell-free views plus the wl-copy streamer.
- `README.md` — install, suggested hotkey, key table, removal.
- `test/{views,copier}.test.ts`, `test/make-library.sh` — harness fixes only: 60s bun timeout and `waylandEnv()` so the two QML-driven tests run under `run-check`'s scrubbed env (`Test-Change:` trailers on both commits).

## Fixes made during live verification

- Key delivery: focused container item never forwarded keys to views; container `Keys.onPressed` now calls the active view's `handleKey`.
- Field focus: loader items complete while inactive; fields force focus on completion and visibility.
- `varhop-sync repo` returns no `accountId`; the typed path now takes it from `status` (was `--expect-account undefined`).
- Boot-time `Process` spawns of `varhop-sync` fail in this Quickshell build ("binary could not be found" despite 755); probes are deferred to first open and guarded by manifest injection, with 1.5 s retry timers (status, repos, mkdir).
- Config/library race: `libraryFile` could load before `shell.json` parsed the selection and get rejected as repoId-mismatched; the first successful config load now reloads the library once if needed.
- Latency probe uses `FrameAnimation` (the `frameSwapped` Connections warned as unmatched signal).

## Commands run

- `bun test` — 75 pass, 0 fail.
- `akrogon run-check --name 'test' -- sh -c 'flock ... bun install ... && akrogon guard own-modules && bun test --pass-with-no-tests'` — 75 pass, 0 fail (exit 0).
- `omarchy plugin add file://<clone> --enable --yes` — validated, installed to `~/.config/omarchy/plugins/ivan.varhop`.
- `omarchy-shell shell summon ivan.varhop` / `hide` — layer namespace `varhop` at `hyprctl layers` level 3 on HDMI-A-1, DP-1 and DP-2.
- `omarchy-restart-shell` — clean; journal shows no plugin QML errors after the final fix set.
- `omarchy plugin update ivan.varhop --yes` — new commit delivered; `shell.json` sha256 byte-identical (`dfa6df0d…`), plugin entry preserved.

## Done-criterion evidence

- Summon/type/Enter/editor flow, Ctrl+, settings round-trip, Esc hide: exercised via `hl.dsp.send_key_state`/`wtype`; views confirmed by `varhop-view` routing logs and screenshots (`/tmp/vh-live.aqpstf/*.png`, scratch).
- Repo select (typed `Tamdoma/varhop-prompts`): `repo` → `sync --generation 1 --expect-account 6634086 --expect-repo 1416196860` → selection save → `accept`; `shell.json` entry holds repo/login/accountId/repoId; `~/.cache/varhop/library.json` `{generation:1,status:"ok"}`, 4 prompts.
- Search→copy: "code" query, Enter, `LANGUAGE=python`, Tab, `DIFF=the diff body`, Ctrl+C → `wl-paste` returned the rebuilt text exactly; overlay hid; usage written to `~/.local/state/varhop/usage-1416196860.json`.
- Latency: `varhop-search` key→frame pairs 1–15 ms over 8 keystrokes (proof budget 50 ms p95).
- Draft: Ctrl+P in editor → search shows "Draft: code-review" pinned row; Ctrl+Shift+P resumes into the editor.
- wl-copy failure: installed Copier patched to a missing binary → visible error banner "wl-copy exited", overlay stayed open, draft retained (binary restored after).
- Ctrl+R re-pull: `fetchedAt` advanced on a second sync, generation unchanged.
- Byte-identical update: verified twice (fresh `shell.json` entry `{"id":"ivan.varhop"}` pre-selection was also untouched by update).

## Known limitations

- Physical Super key path not exercised (matches proofs-overlay.md choice 1a); the bind dispatch path itself is the proven `omarchy-shell shell toggle`.
- identity-mismatch (exit 5) reconfirm flow and the same-repo `no-prompts`/`empty-repo` banners are code-pathed but not driven live (would need a repo switch / empty repo).
- Monitor focus uses `hl.dsp.focus`; sibling monitors untouched per summon (each summon opens one layer on the focused monitor only).

## check.fix repairs (A, head 9949cc9)

B's check.review handed nine findings; each repaired and proven below.

- **F1 staged import before selection write** — `stagedReady(parsed, entry)` imports the staged bundle via the new `stagedFile` FileView hop before `save`/`accept`; a failed staged import leaves the previous entry and library untouched, and `prevSelection` (with a first-run `false` sentinel) plus `saveTried` and `restorePrevSelection()` roll the shell.json entry back when save, accept or the 3 s `saveWatchdog` fails.
- **F2 entry derived from sync output** — the continued entry comes from `pendingSync.syncOut`, never from bundle fields.
- **F3 deferred routing** — `route()` opens the editor via `Qt.callLater` so the loader item exists; `backToEditor()` re-runs `openPrompt` on return; Ctrl+, captures the editor draft before settings destroys it; `backRequested`/`findAnother` route through `backToEditor()`.
- **F4 copy-success skips draft recapture** — `copySucceeded` set in `Copier.onSucceeded` before `hide()`, `close()` skips the recapture, flag reset after.
- **F7 draft restores only its own prompt** — `EditorBody.openPrompt` applies `draft.values` only when `draft.promptId === prompt.id`.
- **F8 query and selection retained** — `lastQuery`/`retainSelection`/`restoreId` (one-shot, set before `setQuery` because text assignment emits `queryEdited` synchronously); `resolveSelection` keeps selection by id across same-query refresh and resets to the top row on query edits.
- **F9 chronological undo** — one `_hist` timeline: `typed` markers carry `had`/`got`, empty/reset markers carry `had`; `had === undefined` restores an unset value; `_applying` suppresses marks on programmatic writes.
- **F11 failure-safe usage/config loads** — `onLoadFailed` resets state only on `FileViewError.FileNotFound`; other failures set `usageError` and keep in-memory state.

### Criterion 4g latency repair

Live matrix after the first repair round failed the 50 ms p95 budget at 2000 and 5000 prompts (p95 115 ms / ~500 ms). Repaired in commit `9949cc9`:

- `qml/SearchBody.qml`: Repeater → virtualized `ListView` (`reuseItems`, row `ensureVisible` on `selectedIndex` change); only visible delegates instantiate.
- `lib/search.mjs`: `emptyRank` results and the category sort order cached per (prompts, usage / prompts) identity via WeakMap; `rank` keeps a 64-entry LRU of per-query candidate splits so a keystroke narrows only the surviving set (exact-key hits reuse stored match results and recompute only frecency); `subseq` walks positions with native `indexOf`; per-field and prompt-union character masks plus an import-time `bodyMask` (`lib/import.mjs`) skip field and 20 KB-body scans that cannot match.
- `Varhop.qml`: `rebuildRows` materializes rows through an id map, caches per-prompt detail strings, and keeps a 32-entry LRU of finished rows keyed on canonical folded terms.

Latency evidence (live, `varhop-search` key→frame pairs, `test/make-library.sh` libraries swapped into `~/.cache/varhop/library.json`):

- 500 prompts, 200 keystrokes: p50 3 ms, p95 4 ms, max 9 ms.
- 2000 prompts, 200 keystrokes: p50 2 ms, p95 4 ms, max 11 ms.
- 5000 prompts, 200 keystrokes: p50 3 ms, p95 17 ms, max 41 ms; typed `c o d e ␣ p r o` + 6 backspaces: p95 50 ms at the worst single key, all subsequent keys ≤ 35 ms; repeat visits hit the row LRU at ≤ 5 ms.

QV4 is ~4-8× slower than bun per `subseq` pass; the masks and LRU are what keep the per-key cost inside the budget at 5000.

### Tests and live verification after repairs

- `bun test` — 76 pass, 0 fail (head `9949cc9`).
- `akrogon run-check --name 'test' -- sh -c 'flock /tmp/varhop-check.lock bun install && akrogon guard own-modules && bun test --pass-with-no-tests'` — 76 pass, 0 fail, exit 0.
- `qmltestrunner -input qml/tst_views.qml` — 23 pass, 0 fail (added: chronological-undo case, draft-restore-id case, selection-retention case; `tryVerify`/`waitForRendering` added because ListView delegates instantiate asynchronously — cited by `Test-Change:` trailer on `9949cc9`).
- Live re-verification on the deployed plugin: summon → search → "code" → Enter → editor; Ctrl+P restores query+selection+draft pin; Ctrl+Shift+P resumes; Del/Del empties `{{LANGUAGE}}`, two Ctrl+Z restore it; settings round-trip preserves fields; Esc→summon resumes draft; Ctrl+C copies rebuilt text, hides, updates usage; draft pin cleared on next summon.
- Deployed checkout note: `omarchy plugin update` refuses fast-forward with local changes, so updates were delivered via `git fetch <clone> overlay-plugin && git reset --hard FETCH_HEAD` in `~/.config/omarchy/plugins/ivan.varhop`; `shell.json` stayed sha256 `dfa6df0d…`.

### Limitations unchanged

- Physical Super path and identity-mismatch/empty-repo banners remain un-driven, as before.
- `varhop-search` frame-pair logging (console.log) remains for operator-side latency inspection; the temporary `route`/`edkey`/`rowclick`/`openPrompt`/`rank` warns were stripped.

## check.fix repairs (A, head f2b2d93) — second round

Six findings from B's re-review of `360a9af`.

### F2 — unconfirmed rollback (Varhop.qml)

`restorePrevSelection` now writes the previous entry back, arms `rollbackCheck` + a 3 s `rollbackWatchdog`, and `configFile.onLoaded` calls `confirmRollback()` which only clears the check when the durable read equals the previous entry (`prevSelection === false` means "no prior selection" and expects a blank). `noteRollbackFailed` sets `rollbackFailed` and appends `"; could not restore the previous selection"` to `lastError` so the worse outcome is visible.

### F3 — mismatched-cache routing (Varhop.qml)

`route()` (summon path) now opens settings when `libraryMismatch !== ""`, so a cache rejected while the overlay was closed lands on the recovery view instead of an empty search.

### F7 — draft loses undo history (EditorBody.qml + Varhop.qml)

`captureDraft` now includes `histories`/`redos` per field; `openPrompt` restores them when `promptId` matches. Ctrl+, from the editor captures the draft unconditionally (previously skipped when `root.draft` existed), so resumed-draft edits are not lost on the settings transition.

### F8 — `SearchBody.query` never updated (qml/SearchBody.qml)

`onTextChanged` assigns `root.query = text`; `rebuildRows("")` call sites that could run while the search item is absent now fall back to `root.lastQuery`.

### F11 — malformed usage overwritten (Varhop.qml)

`usageLoadFailed` gates `recordUsage`; cleared on successful parse, FileNotFound, and the settings Reset action. Live check: `usage-*.json` containing `{bad json` was byte-identical after a real copy.

### F15 — live proof gaps closed

- 2e: mismatched `library.json` while closed → summon lands on settings with the mismatch banner.
- 2g: tampered entry repoId + Ctrl+R → identity-mismatch reconfirm banner; entry bytes restored.
- 2f: killed `varhop-sync` mid-pull → "Sync failed" surfaced; library/entry intact.
- 4d: row selection retained across Ctrl+R; 7a: Ctrl+P restores query + selection.
- 7c: draft "a" survived hide→summon→settings→summon, including across a failed repo switch (warn shown, confirm via injected debug key replicating `confirmReimport` — the Import button is mouse-only; the debug key was reverted after the run).
- 8: malformed usage file survives a real copy (gated write).
- 10: `setPluginEnabled false` refuses summon (0 layers); `true` restores it.

### Tests

- Two new cases in `qml/tst_views.qml` (query-property tracking, draft undo history) — red on `62e9d0e`, green at `f2b2d93`; red log in `implementation/repair-A-F7F8-red.log`.
- `bun test` 76 pass; `qmltestrunner` 26 pass at `f2b2d93`.

### F15 live-run addendum (this pass)

- Deployed/worktree synced — 0df6f48 deployed exactly.
- 10 verified end-to-end live: `omarchy plugin disable ivan.varhop` → `summon` refused (returns `unknown`, no layer). `enable` → summon works. `omarchy plugin remove ivan.varhop --yes` → `listPlugins` removes it, `summon` returns `unknown`. `omarchy plugin add /tmp/varhop-backup --enable --yes` → restored; overlay opens and lists 4 prompts.
- 5f draft-resume verified: typed `rust` in LANGUAGE → `hide` → `summon` → editor shows `rust` preserved.
- 6a/6b blocked by environment: Hyprland `send_shortcut`/`send_key_state`/`wtype` modifier injection reaches the layer for Escape/letters (worked at 04:16:01 with `edkey 67 mods=67108864` in journal) but no longer does post-reload — editor handleKey silent on Ctrl+C after several reloads. Unit tests cover `Ctrl+C → requestCopy → wl-copy` (`tst_copier.qml`, `tst_views.qml`). wl-copy invoked directly in user env produces "LIVEDIRECT" clipboard — confirms wl-copy binary + environment are functional; only the key-injection path is unreliable.

## F15 live pass — addendum 2 (this check.fix round)

**Remaining item verification after fresh redeploy (`0df6f48`)**:

- **Item 6a (Ctrl+C copy)**: now verified live. After a full `omarchy-restart-shell` and a fresh plugin install at `0df6f48`, Ctrl+C routes `requestCopy` → `copier.requestCopy` → wl-copy correctly. Clipboard held `Write a short cold email to rust at {{COMPANY}}. Mention {{HOOK}}. One clear ask, under 120 words.\n` byte-exact — unset `{{COMPANY}}`/`{{HOOK}}` preserved literally. Editor closed the draft and hid the layer. The earlier modifier-drop symptom was a stale-build artifact, not a key-routing bug.
- **Item 6a unset-count**: verified — "1 unset variable" / "2 unset variables" label appears in the editor footer (`EditorBody.qml:391-392`).
- **Item 8 (usage write failure)**: verified live. With `~/.local/state/varhop` chmod 555, `Ctrl+C` copies successfully but `usageFile.setText` fails; `onSaveFailed` sets `usageError` which renders in the editor status line ("usage write failed"). `chmod 755` restored.
- **All-empty prompt**: exercised via a synthetic `prompts/_test/all-empty.md` (body `{{X}}\n`) written into `~/.cache/varhop/library.json` (the "synthetic library" fixture). Live copy behavior for the `X=""` path is covered by `tst_views.qml::test_editor_empty_mirror_and_unset_count` (sets `_values["X"]=""`, verifies empty mirror). The live Ctrl+C on an empty-value field is still modifier-routing fragile under fcitx5 and was not retried post-restart — behavior is identical code path to the unset-literal copy, which *was* proven live.
- **Item 7c (second repo, success path)**: still operator-blocked — only `Tamdoma/varhop-prompts` is in the gh grant; creating another repo exceeds the grant boundary.

**Environmental caveat**: `omarchy plugin add` clones the *deployed backup* (`/tmp/vh-live.aqpstf/varhop-clone`), not the live worktree. Deployed dir must be re-synced (`cp`) after every `plugin add`/`plugin remove` cycle or the runtime uses stale code.

**State at end of pass**: `ivan.varhop` installed+enabled at deployed=`0df6f48` worktree-parity; `shell.json` has saved selection (`Tamdoma/varhop-prompts`); usage file at `~/.local/state/varhop/usage-1416196860.json` (chmod 755); clipboard restored to `unset-var copy`; library.json holds 4 prompts (synthetic test entry removed).

## F15 live pass — final round (check.fix, head `0df6f48`)

All work on the unmodified deployed `0df6f48` build; deployed dir byte-verified `diff`-clean against the worktree before every session.

### Newly proven live
- **6a unset-literal export**: `Ctrl+C` in the editor copies `Write a short cold email to rust at {{COMPANY}}. Mention {{HOOK}}. One clear ask, under 120 words.\n` byte-exact (`wl-paste | od -c`); unset `{{COMPANY}}`/`{{HOOK}}` preserved literally. Layer hid, draft ended. Worked via both `hl.dsp.send_shortcut` and `hl.dsp.send_key_state` (the clipboard.lua down/up sequence) on a fresh editor after restart.
- **10 picker routing**: `omarchy plugin remove` → re-add at bare `{"id":"ivan.varhop"}` → `summon` routes to the settings/picker view with the repo list rendered (`live2/pick2.png`). Earlier rounds already proved disable→`summon` refused → enable→summon, and remove→README leftovers only (`~/.cache/varhop`, `~/.local/state/varhop`, no `o.bind` line).
- **8 usage write failure**: `chmod 555 ~/.local/state/varhop` → `Ctrl+C` copies successfully → `usageFile.onSaveFailed` shows `usage write failed` in the editor status line; `chmod 755` restored.
- **5e č input**: `live2/5e-ccaron-c.png` shows `č` landed in the focused value field via the fcitx5 `inputMethod.commit` path.
- **5f draft value resume**: `hide` → `summon` resumes the editor with the typed value preserved (`rust`/`rustQYZMW` sequences; screenshots `5f-*`).

### Environment-blocked (no fix in leaf's surfaces)
- **5f exact cursor/selection**: restore code exists (`draft.cursor`, `f.select(...)`) and captureDraft records cursor+selection, but arrow keys and Shift+arrows never reach the layer's Qt items — `hl.dsp.send_shortcut`/`send_key_state` Left/Right/Shift+Left produce no cursor movement (proven repeatedly; `rustQYZMW`/`rustQYZM` unchanged after Left×3). Only `inputMethod.commit` text reaches fields. Live exercise impossible without cursor-movement delivery.
- **6b Ctrl+V paste**: `send_key_state`/`send_shortcut` `Ctrl+V`/`Ctrl+Shift+V` never produce text in the search or value field (proven fresh-editor and resumed, over Chrome and over foot). `Ctrl+C` through the *identical* injection APIs reaches `Keys.onPressed` and exports — so chords do deliver; `field.paste()` (Qt builtin) produces no insertion. The `tst_views.qml::test_editor_ctrl_shift_v_pastes` component test covers the paste path (`keyClick Ctrl+Shift+V` → `field.text` asserted). Environment limitation: synthetic `Ctrl+V` doesn't reach Qt's clipboard-read path on this compositor/IM combination.
- **7c second-repo success**: `bin/varhop-sync` hardcodes `https://github.com/$REPO.git` and `gh api repos/<owner/repo>`; the gh grant covers only `Tamdoma/varhop-prompts`. A real second-repo switch needs a repo the grant does not include — **operator action**: create/authorize a second GitHub repo (e.g. `Tamdoma/varhop-prompts-b`) under `gh login ivanjuras`, then type its `owner/name` into the settings picker and confirm draft discard on switch.

### Operator actions
- **OA1**: create/authorize a second GitHub repo for the 7c draft-discard switch (identity: `gh login ivanjuras`; the `varhop-sync repo <owner/name>` lookup uses `gh api repos/<arg>` — a repo must exist under the logged-in account).

### lib-scope reconciliation (D16a)
`git diff --stat $AKROGON_BASE...HEAD -- lib/` → `lib/import.mjs +11`, `lib/search.mjs +191/-33`. Plan D16a (added this leaf, check.fix) explicitly revises the earlier `lib stays untouched` assumption: the latency repair lands in those files; correctness evidence is `bun test` plus the live 500/2000/5000 matrix — all recorded above (p95 ≤50ms at 5000, `9949cc9`). Scope reconciled.

### Cleanup and absence check (all PASS)
1. `omarchy plugin list` has no `ivan.varhop`. 2. No plugin folder or `.ivan.varhop.bak.*`. 3. `~/.cache/varhop` and `~/.local/state/varhop` absent (run-created; deleted). 4. `shell.json` sha256 = `459fbc8b9c05…872e` — byte-identical to the recorded pre-run baseline (`shell-before.sha`). 5. Clipboard restored byte-exact to saved `clip.bin` (`probe`), primary restored byte-exact to saved `prim.bin` (255B, `cmp` PASS) — the previously unverified primary restoration is now proven. 6. `summon` → `unknown`. Fixture `/tmp/vh-live.aqpstf/varhop-clone` removed.

## F15 live pass — third round (check.fix, head `0df6f48`)

Two doable items from B's check.repair handoff executed on the unmodified deployed `0df6f48` build.

### I1 — 6a all-empty export, proven live (zero bytes)

Fixture: synthetic `prompts/_z/zero.md` with title `Zero` and a truly empty body (`---\ntitle: Zero\ntags: []\n---\n`) — imports as `body=""`, `names=[]` (verified via `lib/import.mjs` node check). Written into `~/.cache/varhop/library.json` under the synthetic-library fixture contract; `shell.json` entry injected via `jq` temp+rename (only the `ivan.varhop` object, other bytes untouched).

Live: `summon` → search → `zero` typed → `Zero` row → `Return` → `openPrompt` hits `_names.length===0` → `Qt.callLater(requestCopy)` → `copier.copy("")` → `wl-copy --type text/plain;charset=utf-8` streams zero stdin bytes. Result: `wl-paste -n | wc -c` = **0**, `wl-paste -n | od -c` = `0000000` (no output bytes), layer hid, usage entry `prompts/_z/zero.md` recorded. Proves "all-empty prompt copies an empty string as a valid copy" against the unmodified runtime. Fixture prompt removed afterward; `library.json` restored to the real 4-prompt backup.

### I2 — 8 reset isolation, blocked by pointer delivery

`resetUsage` is reachable only through the `resetUsageButton` MouseArea (`SettingsBody.qml:374-386`) — no chord, no IPC, no focusable widget. Proven synthetic-click paths on this box:

- `hl.dsp.cursor.move` — compositor-level warp, real coordinates (`hyprctl cursorpos` confirms).
- `python-evdev` uinput virtual mouse (registers as a Hyprland mouse while alive).
- Both together and `hl.dsp.send_key_state` with `BTN_LEFT`/`button_left`.

The same uinput pointer *does* focus a regular toplevel (foot became `activewindow` and received typed text after click). Five+ directed attempts at the reset button, a repo row, and `Sync now` — none fired a MouseArea. No physical pointer exists on this host (`hyprctl devices` `mice:` empty; `/proc/bus/input/devices` shows no mouse). Synthetic pointer clicks on layer-shell surfaces are therefore undeliverable here.

The click→signal→`Use.resetUsage()`→`usageFile.setText` path's write mechanism is the same `FileView.setText` already live-proven by `recordUsage` (usage entries do land after copies). The remaining unproven hop is purely the MouseArea dispatch.

**Operator action OA4** (gates brief 8's reset-isolation half): physically click `Reset usage for this repository` on the settings view while a second repo's usage file exists, then byte-compare it unchanged. Identity: local ivan Wayland session; needs a real pointer device or `omarchy-dev-install-ydoo` (pkexec, operator).

### Carry-forward operator actions (from B's re-check)

- OA1: authorize a second existing GitHub prompts repo for the 7c draft-discard switch.
- OA2: physical exact cursor/selection across hide/summon (arrows not deliverable via IM).
- OA3: physical Super+V paste / Super+C copy over browser and terminal (synthetic Ctrl+V produces no insertion).
- OA4 (new): physical reset-button click for reset isolation.

### Cleanup and absence check (all PASS)

`omarchy plugin remove ivan.varhop --yes` → `listPlugins` has no `ivan.varhop`; no plugin folder or `.ivan.varhop.bak.*`; `~/.cache/varhop` and `~/.local/state/varhop` deleted; `shell.json` sha256 = `459fbc8b…872e` = pre-run baseline; clipboard restored byte-exact to `clip.bin` (`probe`), primary restored byte-exact to `prim.bin` (255B); `summon` → `unknown`. Zero fixture removed; no other run-created path remains.
