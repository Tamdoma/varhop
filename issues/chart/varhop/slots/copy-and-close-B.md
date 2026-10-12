# Copy and close: blind notes, slot B

Read date: 2026-10-12. Recommendations remain proposals. I read the supplied Question/Carries, intake and all four locked Taken sections. I did not read another slot's copy-and-close notes. Variable editing, value normalization, manual sync and source-based export stay locked.

## Evidence

- **E1. Operator, 2026-10-12.** `issues/chart/varhop/INTAKE.md:31-33` requires interruption to fetch values elsewhere and Ctrl+C to copy the entire prompt and close. `forks/copy-and-close.md:9-14` carries source-based export, exact cursor/selection resume, empty versus unset, and refresh isolation. These are stronger than another launcher's defaults.
- **E2. Practitioner, read 2026-10-12.** [Federico Terzi, Espanso architecture limitation](https://github.com/espanso/espanso/discussions/1226), answer dated 2021-08-04. Espanso's creator explains that expansion sometimes uses the clipboard, and that its then-current restoration could recover text but not images or files. This is historical firsthand evidence of the additional clipboard-state problem automatic injection creates, not a claim about every current Espanso backend.
- **E3. Better-than-training, inspected/read 2026-10-12.** Installed Quickshell is `0.3.2-4`, Qt base `6.12.0-2`, wl-clipboard `2.3.0`. `/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes:997-1004` makes clipboardText writable. [Quickshell 0.3.2 source](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/core/qmlglobal.cpp), lines 229-240, delegates to the application-wide QClipboard, with a void setter. [Versioned documentation](https://quickshell.org/docs/v0.3.2/types/Quickshell/Quickshell/) warns clipboard reads are empty without a focused Quickshell window. A changed signal or own cached read is not an external delivery acknowledgement.
- **E4. Better-than-training, source read 2026-10-12.** [Qt 6.12 Wayland clipboard](https://raw.githubusercontent.com/qt/qtbase/v6.12.0/src/plugins/platforms/wayland/qwaylandclipboard.cpp), lines 77-128, stores MIME data and creates a seat-owned data source through data-control or the ordinary data device. Ownership is independent of the plugin's visual window. [Wayland data transfer](https://wayland.app/protocols/wayland#wl_data_source:event:send) asks the source client to write data on demand. Hiding a window does not end its application process. Process exit removes that source unless another client has retained/reoffered the data. QML reload in the same process is distinct from process restart.
- **E5. Better-than-training, source/docs read 2026-10-12.** [wl-copy manual](https://man.archlinux.org/man/wl-copy.1.en) documents background ownership, explicit MIME type, newline trimming only when requested, and sensitive hints. [wl-copy 2.3.0 source](https://raw.githubusercontent.com/bugaevc/wl-clipboard/v2.3.0/src/wl-copy.c), lines 50-99 and 257-317, forks the serving child after setting selection, reads stdin through a temporary file that is unlinked while its descriptor remains open, and offers plain-text formats. [Copy-action source](https://raw.githubusercontent.com/bugaevc/wl-clipboard/v2.3.0/src/types/copy-action.c), lines 46-58, sets selection and runs a Wayland round trip before its completion callback. Child ownership ends on replacement/cancellation. This supports an independent clipboard owner, not proof of any target application's paste result.
- **E6. Better-than-training, inspected/read 2026-10-12.** `/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes:130-145,187-190` exposes stdinEnabled, started/exited and write. [Process 0.3.2](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/Process/) accepts argument arrays and writable stdin. [Implementation](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/io/process.cpp), lines 169-175 and 318-320, closes the write channel when stdinEnabled becomes false and writes QString as UTF-8. Lines 290-298 show FailedToStart emits runningChanged without exited. An implementation waiting only for exited can hang on a missing binary.
- **E7. Better-than-training, inspected 2026-10-12.** `/usr/share/omarchy/shell/plugins/clipboard/Clipboard.qml:216-233` has distinct paste and copy-only paths, hiding before launching detached helpers. `/usr/share/omarchy/bin/omarchy-clipboard-paste-text:48-62` accepts new text as argv, rejects an empty argument, pipes it to wl-copy, then types or sends Shift+Insert unless copy-only. It does not gate injection on a checked copy result. The file helper `omarchy-clipboard-paste-file:24-33` copies a file then optionally injects Shift+Insert. `plugins/emojis/Emojis.qml:149-152` dismisses before its helper; `omarchy-menu-emoji-insert:13-20` uses sensitive foreground wl-copy, sends Shift+Insert, then kills its owner. Neither injection nor the emoji owner's short lifetime suits delayed manual pasting.
- **E8. Better-than-training, inspected/measured 2026-10-12.** Clipboard plugin `manifest.json:11` is keepLoaded. `Clipboard.qml:21,41,76-85,284-289` watches text and writes up to 500 history entries to `~/.local/state/omarchy/clipboard-history.json`. `capture.sh:15-17` skips sensitive/password-hinted data. `ClipboardHistory.js:8-10,59-66` drops whitespace-only entries and deduplicates others. `pgrep -a wl-paste` found the actual text and image capture watchers. Read-only `timeout 3s wl-paste --list-types` returned `image/png`; no payload was read and nothing was copied. Ordinary varhop text would enter this history if capture succeeds. That is a source-supported expectation, not a varhop copy measured here.
- **E9. Better-than-training, inspected 2026-10-12.** `services/PluginShellApi.qml:46-59` exposes scoped summon/hide/toggle. `shell.qml:731-737,1213-1227` confines third-party hide/toggle to its own plugin and invokes close on hide. `shell.qml:1392-1394` keeps a keepLoaded overlay instance alive when hidden. `Ui/OverlayWindow.qml:54-56,74-80` unmaps the visual surface on hide. `shell.qml:1266-1271,1509-1518` clears panel instances during full plugin reload, despite keepLoaded. Authentication-service retention is a different mechanism, not proof of ordinary panel-state retention.
- **E10. Better-than-training, inspected 2026-10-12.** `omarchy-plugin-update:130-131` calls rescanPlugins after an update; `shell.qml:1788-1789` routes that to full plugin reload. `omarchy-restart-shell:84,98` kills the old shell and launches another. Normal theme switching calls the running shell's applyTheme (`omarchy-theme-set:188-254,473-485`); `shell.qml:1764-1777` updates Commons.Color. `Commons/Color.qml:226-240` loads startup files without watching them and documents runtime IPC updates. A normal palette update is not a shell restart. No restart, update or theme change was performed here.
- **E11. Better-than-training, docs/source read 2026-10-12.** [Raycast snippets](https://manual.raycast.com/snippets) exposes Copy to Clipboard and Paste to Active App as separate primary actions. [Alfred clipboard](https://www.alfredapp.com/help/features/clipboard/) makes auto-paste configurable, enables history separately, and provides retention/clear controls. [Espanso forms](https://espanso.org/docs/matches/forms/) collects values before submission. These demonstrate product choices, not a reason to add both actions to varhop.
- **E12. Better-than-training, docs/source read 2026-10-12.** [Walker README](https://github.com/abenz1267/walker/blob/master/README.md) describes an Elephant-backed launcher with clipboard history. [Elephant clipboard source](https://raw.githubusercontent.com/abenz1267/elephant/master/internal/providers/clipboard/clipboard.go), lines 345-347 and 517-543, defaults activation to Copy and passes text through stdin to its configured command. [Setup](https://raw.githubusercontent.com/abenz1267/elephant/master/internal/providers/clipboard/setup.go), line 94, defaults that command to wl-copy. `pacman -Q walker elephant` reports neither installed here. [Current Omarchy clipboard manual](https://omarchy.org/manual/clipboard/) describes shell-provided history. Walker/Elephant is comparison evidence, not the installed clipboard service.

Practitioner synthesis: Terzi's firsthand report shows why injection brings restoration behavior that copy-only does not need. Raycast and Alfred make paste and copy distinct choices, while Elephant's copy action provides a local Wayland precedent for stdin transport. The operator specifically chose copying followed by manual placement. My recommendation therefore uses one copy action, without injection, delays or restoration of the previous clipboard.

## Q1. Clipboard transport and completion

### Pick, reason and cost

**D1. Copy only the rebuilt body through `wl-copy --type 'text/plain;charset=utf-8'`, using stdin, then hide and finish that draft.** No title, front matter, category, UI labels, filled markers or added newline. Empty output is valid and must replace the previous clipboard with empty text. Commit native preedit before building the output, using the locked value-normalization policy.

Use a tracked Quickshell Process with argv containing only the executable and MIME flag. Enable stdin before starting, write the frozen output on started, then set stdinEnabled false to send EOF. Hide and clear the draft only on normal exit code 0. Failed start, nonzero/crashed exit or a bounded timeout leaves the draft available with “Copy failed” and operation/exit/stderr context. A proposed five-second copy deadline prevents indefinite waiting; it is not a measured performance figure. No automatic alternate clipboard transport or automatic injection.

Reason: stdin avoids argv exposure/size limits, the serving child separates copied-text lifetime from shell lifetime, and process completion provides an observable failure path. Cost: a small process launch, wl-clipboard as an installation dependency, and wl-copy's own unlinked temporary backing data. Ordinary copied text also follows Omarchy's existing history policy. Exit 0 establishes command completion, not that a target has pasted successfully or that no later copy can replace it.

### Rejected options

- **O1. Quickshell.clipboardText as the sole transport.** Valid and smaller for an ordinary focused copy, but the setter has no success result and ownership depends on the shell process. Comparing its own getter does not prove a target can receive the data. I prefer the explicit process result and independent owner here, not a fallback between both.
- **O2. New text passed to omarchy-clipboard-paste-text.** Puts the body in argv, rejects empty output, and supplies injection behavior this workflow does not need. Its history-index route cannot write a newly composed prompt.
- **O3. Foreground owner tied to the overlay, paste-once, or the emoji helper.** Ends useful clipboard availability when that owner is killed or data is first requested. Clipboard watchers can themselves request data. Manual paste may occur later or repeatedly.
- **O4. Automatically paste into the previously focused app.** Adds target/focus tracking, keyboard injection and app-specific paste behavior. The intake's explicit action is copy-and-close. No saved-focus target, restoration delay or paste option is needed in v1.

### Evidence

E1, operator; E2, practitioner; E3-E8/E11-E12, better-than-training, all read 2026-10-12. E5-E6 support the proposed command/input lifecycle. No clipboard write proof was run under this read-only brief.

### Pitfalls and removal

**R1. The view disappears before copy fails.** Freeze one output snapshot, show a short Copying state, suppress duplicate copy requests, and finish the draft only after the tracked success result. Detect failed start separately from exited and bound the pending operation. Keep the pending operation outside the disposable visual surface so Escape/hide does not destroy it.

**R2. Transport changes the body.** Use UTF-8 stdin, an explicit plain-text MIME type and no shell interpolation or trim-newline option. The leaf must compare exact clipboard bytes, including CRLF, Unicode, tabs, trailing newline, no final newline, empty output and a substantial multiline value. Then prove real paste after hiding into a browser and terminal. These are pending criteria.

**R3. Copied text disappears when its UI closes.** Let wl-copy's serving child own it until replacement. Prove clipboard availability after hide and after the shell process restarts, without relying on a history manager to reoffer it. The independent-owner expectation is source-based, not a live result from this turn.

### Question not asked

**Q5. Is ordinary Omarchy history retention acceptable for copied prompts?** Recommend following the current system policy, without a new privacy setting. History stores substituted text, even if varhop's draft is memory-only. A request to suppress history requires an explicit different transport policy, not an unsupported “private copy” claim.

## Q2. Unset variables at copy

### Pick, reason and cost

**D2. Copy unset tokens as-is without blocking or a confirmation.** Show a small unset count while editing so the state is visible before Ctrl+C. Explicit empty values copy nothing and are not counted as unset. Every value remains plain data under the locked parser/export contract.

Reason: preserves partial prompts and the requested one-keystroke action. Cost: the user can intentionally or accidentally paste an unfinished token. The count makes that state visible but does not guarantee they will notice it.

### Rejected options

- **O5. Block unless every variable is filled.** Adds mandatory completion the operator did not request and prevents deliberate partial prompts.
- **O6. Confirm at copy time.** Adds another interaction to the fast action and gives an accidental omission the same prompt as an intentional partial copy.
- **O7. Delete unset tokens or replace them with empty text.** Confuses unset with the separately locked empty state and silently changes authored content.

### Evidence

E1, operator carry, 2026-10-12, fixes how empty and unset render. Raycast's required-argument behavior is comparison evidence from the earlier variable fork, not authorization to impose it here. The unset-count/no-gate recommendation is my judgment.

### Pitfalls and removal

**R4. Literal pasted braces are incorrectly counted as missing fields.** Count unset states in the original parsed name model, never occurrences in the exported string. Escaped tokens and literal value content do not create missing fields.

### Question not asked

**Q6. Should unset names be listed, or is a count sufficient?** Recommend a count beside the existing active-name/stop indicator. A larger validation panel is not needed for a nonblocking copy policy.

## Q3. Selection versus whole-prompt copy

### Pick, reason and cost

**D3. Ctrl+C in the prompt stage always copies the whole rebuilt prompt and finishes it, regardless of selection. In search, it copies the selected query text normally and leaves search open.** A selected result row is not an opened draft and Ctrl+C there does not export it. Other settings inputs keep ordinary selection-copy behavior.

Reason: the editor follows the operator's explicit shortcut, while search has no whole prompt to export. Cost: Ctrl+C cannot extract a small passage while in the prompt stage. No extra selection-copy shortcut is added without a request.

### Rejected options

- **O8. Selection-copy in the prompt whenever text is selected.** Every navigated variable is selected, so the requested whole-prompt action would usually copy just one value.
- **O9. Ctrl+C exports the highlighted search result.** Bypasses opening/reviewing it and creates different behavior depending on focus/result state.
- **O10. Treat Ctrl+C as whole-prompt export everywhere.** Makes ordinary query/settings selection-copy unavailable and needs an implicit draft target even outside the editor.

### Evidence

E1, operator, read 2026-10-12, governs prompt-stage Ctrl+C. [Qt Keys priorities](https://doc.qt.io/qt-6/qml-qtquick-keys.html#key-handling-priorities), better-than-training, read 2026-10-12 in the variable fork, places interception before the attached editor's native handling. E7/E11 show separate application actions but do not settle varhop's stage rule.

### Pitfalls and removal

**R5. Native TextEdit copies the active selection before the app acts.** Put accepted BeforeItem interception on the focused native prompt input and every focusable prompt text view. Stage-scope shortcuts so search keeps native copy. During composition, commit the pending value before exporting. Test selected token, filled value, ordinary prose selection, no selection, query selection and zero-variable prompts.

### Question not asked

**Q7. Does Omarchy's Super+C also mean whole-prompt copy?** This matters on this system because the desktop supplies unified copy keys. The settings/hotkey fork must inspect their actual forwarding into the plugin. Do not invent a second implementation before checking that binding.

## Q4. Escape, summon and draft lifetime

### Pick, reason and cost

**D4. Escape hides from both prompt and search. A hidden unfinished prompt resumes exactly on summon. Successful copy ends its draft, so the next summon opens fresh search.** Hidden search can retain its query/result position for the same loaded session. Escape, outside dismissal and the summon key's hide toggle must use the same preserve-draft path. Preserve source revision, values, semantic undo histories, active occurrence, cursor, selection and scroll position in the keepLoaded plugin model, not in the remapped window.

Provide a deliberate “Find another prompt” action to enter search and replace the current draft when another prompt is selected. Its keyboard binding belongs to settings-and-hotkey. Search entry alone does not reset values. One in-memory draft is sufficient. The choice to open another prompt is the deliberate replacement, without adding a discard confirmation.

**Lifetime: ordinary hide/summon and normal theme changes retain the draft. Full plugin reload, plugin update that invokes reload, shell QML reload, shell restart/crash, plugin disable/removal and logout need not retain it in v1.** Do not persist drafts or undo histories to shell.json or another disk file. keepLoaded preserves hidden instances, not re-created ones. An update to any plugin can trigger the host's full panel reload, so this limit is broader than updating varhop alone. A custom theme hook that restarts the shell falls under restart, not ordinary palette change.

Reason: satisfies in-session interruption without adding recovery storage. Cost: unfinished values are lost when their owning plugin instance is rebuilt. Already copied text has its separate wl-copy lifetime and remains replaceable by any later system copy.

### Rejected options

- **O11. Escape discards.** Makes the most obvious dismissal key destroy the interruption state required by the intake.
- **O12. Escape returns to search, then a second Escape hides.** Adds an intermediate stage to the common “go obtain a value elsewhere” action. Use the deliberate search action for choosing another prompt.
- **O13. Summon always starts fresh search.** Hides the unfinished draft rather than resuming the task.
- **O14. Persist drafts through updates/restarts.** Adds disk retention, recovery ownership and schema/history handling beyond the requested in-session workflow.
- **O15. Assume keepLoaded preserves panel state through reload.** The inspected host clears its panel model. Retention comments for authentication services do not transfer to ordinary overlays.

### Evidence

E1, operator, and E9-E10, better-than-training, inspected 2026-10-12. Local code distinguishes hide, plugin reload, process restart and theme IPC. No lifecycle event was induced during this turn.

### Pitfalls and removal

**R6. Every reopen reconstructs the editor and loses exact selection.** Capture state before visual hide and restore it after focus/layout is ready, without selectAll or selecting the first stop. The leaf must demonstrate partial selection and cursor resume after using another app and after a theme change.

**R7. Generic close destroys a draft after both Escape and copy.** Define distinct preserve-on-hide and finish-after-copy transitions. The host's close callback is the preserve path. Copy success explicitly finishes the same pending draft before hiding, so host close cannot recreate or erase an unrelated draft.

**R8. Reload persistence is promised accidentally.** The user-facing contract says drafts last until copy, deliberate replacement or plugin/shell reload. Tests establish hide/theme retention and a fresh state after reload. No durable recovery is claimed.

### Question not asked

**Q8. What happens when another prompt is selected with an unfinished draft?** Recommend the deliberate replacement rule above, with no multi-draft store or confirmation. Returning from search without choosing another must still allow resuming the retained draft through an explicit Resume action.

## Limits

Only this return file was written. Clipboard inspection was metadata-only. No clipboard write, paste injection, history read/clear, setting change, shell restart, theme change or plugin update occurred. The selected copy command and lifecycle behavior remain pending real proofs. Documentation/source inspection does not count as a successful varhop copy.
