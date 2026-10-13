# Plan: overlay-plugin

Build the `ivan.varhop` Omarchy shell overlay plugin on top of the already-merged prompt-core (`lib/*.mjs`) and repo-sync (`bin/varhop-sync`, `bin/varhop-fetch`, `~/.cache/varhop/library.json`) leaves. Debate is off (`debate: no`), so this plan is direct synthesis from brief.md and design.md.

## Decisions

- D1: The repo root is the plugin root. `manifest.json` sits at `/` (the `omarchy plugin add file://<clone>` checkout becomes `~/.config/omarchy/plugins/ivan.varhop`, and `omarchy-plugin-validate` requires entry points relative to the plugin dir). `entryPoints.overlay` = `Varhop.qml`.
- D2: `Varhop.qml` is the only file that imports Quickshell modules or `qs.*`. It owns OverlayWindow, the shell API (`shell.summon/hide/updateEntryInline`, `manifest.__sourceDir`), FileView I/O, Process children (varhop-sync, Copier), view routing and the draft. Every interactive view is plain QtQuick (+ `QtQuick.Controls`) so `qmltestrunner` can load it; colors and callbacks arrive as properties.
- D3: Views import `../lib/*.mjs` directly (proven: `lib/qml-smoke.qml` loads them in the QML engine). Rebuild/token/search/usage logic is not duplicated in QML.
- D4: Draft state is plain data owned by the root: `{promptId, values:{}, activeName, cursor, selection, undos/redos}` where undos/redos are the per-variable chronological stacks. It survives hide/reopen in memory only. Esc in editor hides and keeps it; Ctrl+Shift+P resumes it; **every** hide or view switch captures the current editor state into the draft (resumed drafts are re-captured too, not only `draft===null`), and a recreated editor restores values **and** undo/redo stacks for the matching promptId only. A successful copy or a confirmed repo switch clears it.
- D5: Editor editing uses one `TextEdit` per unique variable name (the "stop"), with remaining occurrences rendered as read-only mirrors (styled `Text`/`TextEdit` readOnly). Clicking a mirror makes its stop the active value. Per-variable undo/redo = the stop's own undo stack plus a small action stack for the empty→unset Delete reset. Tab/Shift+Tab walk unique names with wrap. A zero-variable prompt opens ready and immediately requests copy.
- D6: Text input behavior (paste, copy of field selection, chord vocabulary, exact-modifier chords) is implemented inside the views' key handlers: `TextInput`/`TextEdit` get `Keys.onPressed` handling Ctrl+V/Ctrl+Shift+V paste and Ctrl+C/Ctrl+Shift+C copying only `selectedText` (Qt does not paste Ctrl+Shift+V natively — proofs-overlay.md row 13). Keys match exact `event.modifiers`.
- D7: Selection persistence: root reads `~/.config/omarchy/shell.json` through a watched `FileView` (the shell injects no settings into overlays — shell.qml:1396+), takes `plugins[]` entry `id == "ivan.varhop"`, and writes with `shell.updateEntryInline("ivan.varhop", {repo,login,accountId,repoId})` then re-reads the file to confirm (false can mean unchanged; only the read-back is durable).
- D8: Sync flow per design: generation counter, `varhop-sync sync <owner/repo> <cache> --generation <n>` (+ `--expect-account/--expect-repo` on repeat syncs of a saved repo), stale-generation completions ignored, then read `staged-<n>.json`, `importLibrary(files)`, save selection with read-back, then `varhop-sync accept <cache> <n>`, then swap the in-memory library. Any earlier failure keeps old library/selection and shows the error. `identity-mismatch` shows the reconfirm prompt; confirm runs the repo-change path. A repo-change failure **after** the entry write restores the previous durable selection via `updateEntryInline` and confirms the rollback with a config read-back before clearing `lastError`; when the rollback read-back cannot confirm the restore, the surfaced error says the previous selection could not be restored instead of reporting a generic sync failure.
- D9: `library.json` is accepted only when `repoId` equals the saved repoId; mismatch names it in settings and offers Sync now, including a mismatch discovered while the overlay was closed. Usage state at `~/.local/state/varhop/usage-<repoId>.json` via `FileView` with `atomicWrites: true`, `parseUsage` on read, `recordCopy`/`resetUsage` on write; save/load failures are surfaced, never silently reset. After a **parse** failure (malformed JSON), ordinary `recordCopy` writes are gated off so an unreadable history file is never overwritten by a successful copy; the surfaced error persists and the explicit settings Reset action is the recovery. A `FileNotFound` load failure is first-run absence and resets state.
- D10: `Copier.qml` (Quickshell.Io only) wraps `wl-copy --type text/plain;charset=utf-8` with `stdinEnabled`, a timeout property, and `success`/`failed` outcomes covering: non-zero exit, timeout, and `running`→false with no `exited` (failed start, proofs-overlay.md row 21). Copy success ends the draft and hides; failure keeps the draft and shows the error.
- D11: Search latency: each keystroke search logs one JSON line `varhop-search {"key":<ms>,"frame":<ms>}` where `frame` is captured in the `onFrameSwapped` handler of the OverlayWindow's `QQuickWindow` (`panel.contentItem.window` Connections; PanelWindow is a QQuickWindow so `frameSwapped` exists). The live check parses `journalctl --user _PID=<quickshell-pid>` for p95 ≤ 50 ms.
- D12: All displayed repo/error strings use `textFormat: Text.PlainText`; `Image`/`Loader` never receive user strings (criterion 9 structural guarantee plus a component assertion).
- D13: Live-run sequence is serial against the operator's one shell session, keyboard focus and Wayland clipboard (shared resource in readiness.yaml grant). Every live run after a code change starts with `omarchy-restart-shell` (proofs-overlay.md row 14/19). Clipboard and primary are saved/restored byte-exact around the run; the run's own `varhop-sync` child is the only one pkilled.
- D14: Chord field validates a modifier+key whitelist (SUPER/SHIFT/CTRL/ALT/META + key name), runs a conflict probe (Process `hyprctl binds -j` parsed with invalid-JSON tolerance, or an injected list in component checks), warns on collision, shows the ready `o.bind(...)` line only when free, and is never persisted.
- D15: Summon routing: `open()` resumes an existing draft, else opens settings at the picker when no repo is selected, else settings when a stored `libraryMismatch` exists (the cache was rejected before summon), else search. Esc in settings returns to the view it came from or hides on first run. `omarchy-shell shell summon ivan.varhop` is the no-bind fallback.
- D16a (scope correction, added in check.fix): the 4g latency budget is met inside `lib/search.mjs`/`lib/import.mjs` (query-state LRU, character masks, import-time bodyMask) — the earlier assumption that `lib/*` stays untouched is revised; those files' correctness evidence is `bun test` (rank order unchanged, equality proven by the existing search tests plus the unchanged API/ordering contract) and the live 500/2000/5000 matrix, not component tests.

- D16: Tests: `bun test` spawns the two QML runs — `QT_QPA_PLATFORM=wayland QT_IM_MODULE=fcitx /usr/lib/qt6/bin/qmltestrunner -input qml/tst_views.qml` and `QT_QPA_PLATFORM=wayland quickshell -p qml/tst_copier.qml` — plus a static `test/plugin.test.ts` manifest check. Test files are committed before product code (this commit).

## Read-first

- `issues/open/varhop/overlay-plugin/brief.md`, `design.md`, `readiness.yaml` (leaf folder; done-criteria, locked decisions, grants/fixtures)
- `issues/chart/varhop/proofs-overlay.md` — row 13 (no native Ctrl+Shift+V), 14/19 (restart loads new code), 16 (wayland qmltestrunner), 21 (failed Process start)
- `issues/chart/varhop/proofs-sync.md` — `bin/varhop-sync` output shapes
- `lib/import.mjs` (`importLibrary`), `lib/search.mjs` (`rank`, `DISPLAY_CHUNK`, `fold`), `lib/tokens.mjs` (`splitSegments`, `uniqueNames`), `lib/rebuild.mjs` (`rebuild`), `lib/usage.mjs` (`parseUsage`, `recordCopy`, `resetUsage`, `HALF_LIFE_MS`)
- `bin/varhop-sync` (status|repos|repo|sync|accept contract and error JSON `{error,message,fix,stderr}`, exit classes 2–9) and `bin/varhop-fetch` (bundle shape: `{version,generation,repo,repoId,accountId,login,commit,fetchedAt,status,slot,files,errors}`, staged file)
- `/usr/share/omarchy/shell/Ui/OverlayWindow.qml` (fresh surface per open; layer Overlay on open — the D-criterion layer 3)
- `/usr/share/omarchy/shell/plugins/emojis/Emojis.qml` (overlay entry shape: `open(payload)`, `close()`, `toggle()`, OverlayWindow + keyCatcher, `Commons.Color`, `Style`)
- `/usr/share/omarchy/shell/shell.qml` 1095–1144 (`updateEntryInline`), 1173–1260 (summon/hide/toggle/isPluginOpen), 1314–1425 (Loader injects `shell`, `manifest` with `__sourceDir`)
- `/usr/share/omarchy/shell/services/PluginShellApi.qml` + shell.qml 594–668 (scoped plugin shell: `updateEntryInline` limited to own id)
- `/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes` (`Process.stdinEnabled`, `FileView.setText/setData`, `atomicWrites`, `saved/saveFailed`)
- `/usr/share/omarchy/bin/omarchy-plugin-validate` (manifest schema: schemaVersion 1, id/name/version/kinds/entryPoints, no symlinks, `omarchy.*` reserved)
- `/usr/share/omarchy/default/hypr/bindings/clipboard.lua` (Super+C/V → `hl.dsp.send_key_state` CTRL or CTRL SHIFT)
- `docs/reference-index.md`, `learnings/LESSONS.md` (empty; no active lessons)

## Interfaces

Root ↔ views (all views are `Item` with injected props; names are contracts, exercised by `qml/tst_views.qml`):

- `SearchBody` props: `rows` `[{id,title,detail,fileName,draft,snippet}]`, `draftPromptId`, `query`, `colors`; signals: `queryEdited(q)`, `queryCleared()`, `hideRequested()`, `accepted(id)`, `resumeDraft()`, `pullRequested()` (Ctrl+R). ObjectNames: `queryField`, `resumeDraftRow`, `resultRow<i>`.
- `EditorBody` props: `prompt` `{id,title,body,names}` (derives segments via `lib/tokens.mjs`), `draft`, `copier` (object with `copy(text)` + `failed` signal, or null), `colors`; method `openPrompt()`; readonly `activeName`, per-name `values`; signals: `copyRequested()` (Ctrl+C/Ctrl+Shift+C anywhere, and once on `openPrompt()` for a zero-variable prompt), `hideRequested()` (Esc — draft kept by root), `findAnother()` (Ctrl+P), `pullRequested()`. ObjectNames: `value<i>` (one editable TextEdit per unique name, first-appearance order), `mirror<j>` (read-only repeats). Delete on a value empties it; Delete on empty restores `{{NAME}}` (Ctrl+Z/Y step through both).
- `SettingsBody` props: `syncStatus` (varhop-sync status JSON), `lastPull`, `lastError`, `loadErrors` `[{kind,path,line,message}]`, `selection`, `binds` `[{modmask,key,description,submap}]`, `repos`, `colors`; readonly `chordState` (`typing|conflict|ready`); signals: `repoChosen(fullName)`, `syncNow()`, `resetUsage()`, `hideRequested()`/`backRequested()` (Esc), `pullRequested()` (inert inside `repoField`/`chordField`). ObjectNames: `repoField`, `chordField`. Chord vocabulary: modifiers SUPER/SHIFT/CTRL/ALT/META joined with `+` plus one key name; conflicts match `binds` on modmask+key and warn with `description`.
- `Copier` props: `command` `[string]`, `timeoutMs`; methods `copy(text)`; signals `succeeded()`, `failed(reason)`.
- Root holds `view` enum (`settings|search|editor`), `opened`, `draft`, `library`, `usage`, `selection`, `generation`, sync `Process`, `Copier`, three `FileView`s (shell.json, library.json, usage), and `Process` children for `varhop-sync status|repos|repo|sync|accept` and the `hyprctl binds -j` probe.

Manifest (validated by `omarchy-plugin-validate`): `{schemaVersion:1, id:"ivan.varhop", name:"Varhop", version:"1.0.0", kinds:["overlay"], keepLoaded:true, entryPoints:{overlay:"Varhop.qml"}}` plus optional description/author.

## File/criterion checklist — waves

Shared test resource: the Wayland clipboard/session (`QT_QPA_PLATFORM=wayland` tests and every live check touch the same seat/clipboard), so all waves serialize → serial-solo run; A implements the whole plan.

### Wave 1 — U1: views + component tests

Owns: `qml/SearchBody.qml`, `qml/EditorBody.qml`, `qml/SettingsBody.qml`, `qml/FieldCopyPaste.qml` (shared Keys handling for paste/copy), `qml/tst_views.qml`, `test/views.test.ts` (bun wrapper spawning qmltestrunner).
Criteria covered: brief 3 (settings rendering, chord field, paste/copy in fields), 4 (rows rendering incl. Draft marker, snippet, resume-draft row click, result click), 5 (Tab walk, mirrors, Delete empty→unset, undo/redo, right-click paste, mirror click, copy-failure keeps draft), 9 (plain text). Prerequisite: none. Committed test files only, product QML written here (serial-solo: same seat writes tests then code).

### Wave 2 — U2: Copier + Process-failure tests

Owns: `qml/Copier.qml`, `qml/tst_copier.qml`, `test/copier.test.ts` (bun wrapper spawning `quickshell -p`; saves/restores clipboard around the run). Criteria covered: brief 6 (false / missing binary / sleep-10-timeout → failure each; component half of "copy failure keeps draft" lands in U1's view test). Prerequisite: none for files; runs after U1 only because of the shared clipboard.

### Wave 3 — U3: root, manifest, README, live wiring

Owns: `manifest.json`, `Varhop.qml`, `qml/SyncRunner.qml` (Process wrapper for varhop-sync verbs, if the root stays cleaner with it), `README.md`, `test/plugin.test.ts` (static manifest shape check), `test/make-library.sh` (synthetic library generator for the latency/search live runs — a fixture, not proof machinery). Criteria covered: brief 1, 2, 3 (live portions), 4 live, 5 live (incl. č, inputMethod.commit, draft resume), 6 live, 7, 8, 10. Prerequisite: U1 + U2 (imports their QML; their signals are its contract).

Docs affected: `README.md` only (install steps, `o.bind("SUPER + ALT + P", "Varhop prompts", { panel = "ivan.varhop" })` suggestion line, repo format, `omarchy-restart-shell` step after an update, leftover paths: bind line, `~/.cache/varhop`, `~/.local/state/varhop`). No other agent or human doc is affected; `docs/reference-index.md` gains no entry (README already indexed).

## Verification

`checks`: `akrogon run-check --name 'test' -- sh -c 'flock … bun install && akrogon guard own-modules && bun test --pass-with-no-tests'` — must exit 0 with all planned tests green at implement end. Sizes: seconds; rerun: any change to `test/`, `qml/`, `manifest.json`, `lib/`, `bin/`.

### Done-criteria → proof map

| # | Criterion (short) | Proof | Size | Rerun trigger |
|---|---|---|---|---|
| 1a | `omarchy-plugin-validate` passes | live: `omarchy plugin validate <repo>` exit 0 (run against a local git clone made by the live script: `git clone` of this worktree to `<scratch>/varhop-clone`) | sec | manifest.json / file set change |
| 1b | `plugin add file:// --enable --yes`, summon shows overlay at layer 3 on each monitor | live: `omarchy plugin add file://<clone> --enable --yes`; for each of HDMI-A-1, DP-1, DP-2: `hyprctl dispatch focusmonitor <name>`, `omarchy-shell shell summon ivan.varhop`, `hyprctl layers -j` shows level 3 with namespace `varhop`; `omarchy-shell shell hide ivan.varhop` | min | OverlayWindow usage, manifest |
| 1c | colors from Commons.Color, no QML errors | live: `journalctl --user _PID=$(pgrep -f "quickshell -n") --since <run> -o cat` contains no line with `ivan.varhop` + `qml:` error; grim screenshot inspected | sec | any .qml change |
| 1d | update keeps shell.json byte-identical; restart loads new code | live: record entry sha256, commit marker change to clone, `omarchy plugin update ivan.varhop --yes`, compare entry bytes; `omarchy-restart-shell`, summon, marker visible | min | root wiring |
| 2a | no selection → settings at picker; Esc hides | live: fresh install state, summon, screenshot/journal shows picker; `send_key_state ESC` hides (layer gone) | sec | settings routing |
| 2b | pick `Tamdoma/varhop-prompts` → sync → search shows all prompts; entry read-back has repo+login+ids | live: picker row click (synthetic), wait for `varhop-sync` exit, jq reads `~/.config/omarchy/shell.json` entry fields; search row count == `library.json` prompts | min | sync flow, picker |
| 2c | typed `owner/repo` selects via `varhop-sync repo`; malformed refused | live: type valid repo; type `bad repo` stays unrefused field, no process spawn (journal) | sec | picker field |
| 2d | restart → search from saved selection; library.json sha256+fetchedAt unchanged | live: `omarchy-restart-shell`, summon shows search; `sha256sum` and `.fetchedAt` equal pre-restart values | min | load order |
| 2e | repoId-mismatched library not loaded; settings names mismatch + Sync now | live: jq-rewrite `library.json.repoId` to temp+rename, summon → settings shows mismatch | sec | library guard |
| 2f | `pkill -f varhop-sync` mid Ctrl+R keeps library/selection, shows error | live: trigger Ctrl+R, `pkill -f varhop-sync` while running, library.json sha256 unchanged, settings/search shows error | sec | sync error path |
| 2g | jq repoId-only entry change → Ctrl+R gets identity-mismatch, reconfirm prompt, saves nothing until confirmed | live: temp+rename jq edit of plugins entry, Ctrl+R, `varhop-sync` exits 5, overlay shows actual ids; entry bytes unchanged | sec | D8 flow |
| 3a | Ctrl+, toggles settings; Esc returns to source view | live: summon, `send_key_state CTRL COMMA` twice; open from search vs first-run Esc behavior | sec | keys |
| 3b | settings shows gh login+scopes, last pull | live: settings screenshot/journal: `ivanjuras`, scopes list, `fetchedAt` | sec | settings view |
| 3c | logged-out status → `gh auth login` fix; failed pull error; merged load errors | component: `tst_views.qml` injects `{authenticated:false}` status, a sync error object, and mixed bundle+import errors; asserts rendered text | sec | settings view |
| 3d | Ctrl+V/Ctrl+Shift+V paste, Ctrl+C/Ctrl+Shift+C copy field selection | component: `tst_views.qml` with real Wayland clipboard, keyClick into chord/typed fields | sec | FieldCopyPaste |
| 3e | chord field: warn SUPER+CTRL+P, ready SUPER+ALT+P, refuse out-of-vocab | component: injected binds list; live: same check against `hyprctl binds -j` | sec | chord field |
| 4a | typing selects top prompt; edits reset to top; Up/Down wrap; Enter opens editor first stop | live: synthetic library, wtype query, journal/screenshot; `send_key_state` Up/Down/Return | min | search view |
| 4b | rows show title, category path+description, filename when needed, Draft marker, body snippet | live + component: synthetic lib rows rendered (component asserts role texts; live confirms on real shell) | sec | rows |
| 4c | pinned Resume draft row with chord; click resumes; row click opens | live shows the pinned row; component: `tst_views.qml` mouseClick on pinned row → draft resumed; on a result row → opened | sec | search view |
| 4d | Ctrl+R keeps selected id or top row | live: select row, Ctrl+R to same library, selection still that id; then to a library missing it → top row | sec | sync+selection |
| 4e | Esc clears non-empty query, then hides | live: type query, ESC once (query cleared), ESC (hide) | sec | esc logic |
| 4f | search field paste/copy chords don't export | live: pre-set clipboard, Ctrl+V in field pastes; Ctrl+C copies selection, not the prompt (wl-paste compare) | sec | FieldCopyPaste |
| 4g | p95 ≤ 50 ms at 500/2000/5000 prompts (half 20KB bodies), 200 keystrokes | live: `test/make-library.sh` writes synthetic `library.json` with saved repoId; `wtype` 200 chars; journal p95 of `varhop-search` lines | min | search perf |
| 5a | Tab/Shift+Tab walk unique names w/ wrap; typed value mirrors; zero-variable copies | live + component: keyClick Tab/Backtab; mirrors show value; `tst` zero-variable emits copyRequested on open | sec | editor |
| 5b | edits in prose unchanged; Enter in value = newline; multiline copies | live + component: click prose, type → prose text unchanged; Enter inserts `\n`; wl-paste compare multiline | sec | editor |
| 5c | Delete empty→unset; per-variable undo/redo incl. reset; mirrors follow | component: `tst_views.qml` keyClick Delete twice; undo/redo walks | sec | editor |
| 5d | Ctrl+V/Ctrl+Shift+V literal paste; right-click menu paste; mirror click activates; next Tab → next name | component: paste both chords into value; mouseClick RightButton → menu Paste lands; click mirror then Tab order | sec | editor |
| 5e | č via `hl.dsp.send_key_state` lands; `Qt.inputMethod.commit()` before copy | live: `send_key_state ccaron` into value (fcitx path, proofs-overlay.md row 17); copy via Ctrl+C, journal/console shows commit called | sec | editor input |
| 5f | hide→summon resumes draft with exact cursor+selection | live: select+cursor, hide, summon → same value active, cursor/selection restored | sec | draft |
| 6a | Ctrl+C/Ctrl+Shift+C → wl-paste byte-equal rebuilt text; unset = `{{NAME}}`+count; all-empty copies empty; ends draft+hides | live: `wl-paste --no-newline` byte compare for three cases; layer gone; `hyprctl layers` + draft cleared (reopen shows fresh) | min | copy path |
| 6b | Super+C/V key-state sequences land over browser and terminal-tagged windows | live: focus chrome window then foot window beneath overlay, `hl.dsp.send_key_state` CTRL V / CTRL SHIFT V and C variants (clipboard.lua:34-47), paste lands / copy exports | min | key handling |
| 6c | Copier false / missing binary / sleep-10 timeout each report failure | component: `tst_copier.qml` under `quickshell -p`; three failure modes | sec | Copier.qml |
| 6d | reported copy failure keeps draft, shows error | component: inject failing copier stub; assert draft props intact + error text | sec | error path |
| 7a | Ctrl+P → previous query+selection; Ctrl+Shift+P resumes draft, inert without | live: open prompt, Ctrl+P → search with prior query/row; hide+resume | sec | navigation |
| 7b | Ctrl+R pulls in every view, draft unchanged, inert in picker fields | live: Ctrl+R in search/settings/editor → pull runs, draft intact; type in picker field + Ctrl+R → no process spawn | sec | keys |
| 7c | repo switch with draft warns; discards only after successful import; failed switch keeps draft | live: attempt switch → warn shown; fail path (pkill sync) keeps draft; success clears it | min | switch flow |
| 8 | successful copy → empty-query recent; reset clears only repo's entries; write failure + malformed shown, never silent reset | live: copy a prompt → empty query lists it first; settings reset → other repo's file untouched; `chmod 555` usage dir → write failure shown; corrupt file → shown, file kept | min | usage I/O |
| 9 | `<b>x</b>`/`<img>` strings render literally, no request | component: `tst_views.qml` asserts `textFormat === Text.PlainText` on all rendered Text items containing the hostile strings; Image source check = none | sec | text format |
| 10 | disable+enable → picker; `omarchy plugin remove` leaves only README paths | live: `omarchy plugin disable/enable ivan.varhop`, summon → picker (entry wiped); `omarchy plugin remove ivan.varhop --yes` → plugin dir gone, entry gone, `~/.cache/varhop`, `~/.local/state/varhop`, bind line remain | sec | lifecycle |

Live-run restart boundary: `omarchy-restart-shell` runs once at the start of each contiguous live verification batch after the last product-code change lands; proofs 1b–10 share one shell session sequentially (shared resource). If a fix lands mid-run, restart and rerun from the failed criterion's step only.

### Planned tests committed before product code (this commit, intended red)

Intended-red output (2026-10-13, `bun test` on the pre-product tree):
- `test/plugin.test.ts`: `(fail) manifest.json declares the ivan.varhop overlay plugin` — manifest.json absent.
- `test/views.test.ts`: `(fail) view component checks pass under qmltestrunner on wayland` — qmltestrunner cannot compile `qml/tst_views.qml`: `SearchBody`/`EditorBody`/`SettingsBody`/`SignalSpy` types missing (files not yet written).
- `test/copier.test.ts`: `(fail) copier reports failure for exit!=0, failed start and timeout` — `quickshell -p` exits 255: `tst_copier.qml[33:9]: Copier is not a type`.

- `test/plugin.test.ts` — `manifest.json` exists at repo root with schemaVersion 1, id `ivan.varhop`, kinds `["overlay"]`, `keepLoaded: true`, `entryPoints.overlay` = `Varhop.qml`, no symlinked entry point. Red now: manifest missing.
- `test/views.test.ts` — spawns `QT_QPA_PLATFORM=wayland QT_IM_MODULE=fcitx /usr/lib/qt6/bin/qmltestrunner -input qml/tst_views.qml`; asserts exit 0 and `Totals:` line shows 0 failures. Red now: `qml/tst_views.qml` missing → runner exits non-zero.
- `test/copier.test.ts` — saves `wl-paste` clipboard, spawns `QT_QPA_PLATFORM=wayland quickshell -p qml/tst_copier.qml`, restores clipboard; asserts exit 0 and output has no `copier-probe failures:` line. Red now: file missing → quickshell exits non-zero.
- `qml/tst_views.qml` — QtQuick TestCase loading views as `Component` (plain QtQuick; Quickshell absent by design): logged-out status fix text, failed-pull error text, merged load errors, chord conflict/ready/refuse states, settings field paste+copy, pinned resume-row click, result-row click, Draft marker+snippet rendering, editor Tab wrap/mirror/Delete-undo/redo/zero-variable copy-request, right-click paste, mirror click, copy-failure keeps draft, PlainText assertion sweep.
- `qml/tst_copier.qml` — standalone quickshell config: `Copier { command: ["false"] }`, `["nonexistent-varhop-bin"]`, `["sleep","10"]` with 500 ms timeout → three `failed()` signals; plus a `wl-copy` success case on a marked string.

## Notes for review

- Verified on this machine (2026-10-13, `hyprctl binds -j`): key `P` is bound at modmask 64 (SUPER alone, "Pseudo window"), 65 (SUPER+SHIFT, "Google Photos") and 68 (SUPER+CTRL, "Power"). No SUPER+ALT (72) bind exists, so `SUPER + ALT + P` is free as the README suggestion, and `SUPER+CTRL+P` correctly warns with the existing "Power" description (modmask bits: SHIFT=1, CTRL=4, ALT=8, SUPER=64).
- Held disagreement preserved (design): no live selection-save failure injection exists; the accept-after-read-back order is the proof, plus live sync-failure case 2f.
- No credential/env vars needed: `akrogon status` shows no `Missing:` lines; `env_names: []` and gh login reuse is via the machine keyring per the grant.
- Latency 50 ms at 5000×20 KB bodies is a real risk: `rank` folds the whole body corpus into `search.body` at import; `fold()` runs once per file at import (importLibrary), not per keystroke. Per keystroke it is `terms.every(body.includes(term))` over ≤5000 strings only when structured matches < 50 — O(total bytes) per keystroke worst case ≈ 50 MB scan; may exceed 50 ms → if the 5000 run is red, the fix is inside this leaf's wiring (throttle body search by chunking via `Qt.callLater`/`Timer` slices or short-circuit after DISPLAY_CHUNK body hits). Resolution: the 5000 run was red and the fix landed in `lib/search.mjs`/`lib/import.mjs` per D16a (added in check.fix); the ListView virtualization stays in `SearchBody`. The stale `lib/ stays untouched` clause is superseded by D16a. Check: `git diff --stat $AKROGON_BASE...HEAD -- lib/` shows the touched files and `bun test` proves rank order unchanged.
