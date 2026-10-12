# Settings and hotkey: blind notes B

Read the corrected brief, intake, chart, this fork's Question/Carries and the related Taken sections. No other slot's settings-and-hotkey notes were read. These are recommendations, not operator decisions. Research was read-only on 2026-10-12 and refreshed on 2026-10-13. Only this return file was written.

## Q1. Global hotkey, ownership and conflicts

**Pick.** Suggest **Super+Alt+P**, with the user adding one line to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + ALT + P", "Varhop prompts", { panel = "ivan.varhop" })
```

Use the normal Omarchy binding mechanism. Settings offers a chord field and a copyable line, but does not edit Lua, reload Hyprland or install a second global-shortcut implementation. The actual binding lives in Hyprland configuration. Do not persist a separate “current hotkey” setting that can disagree with it. A suggestion is not an installed default. Cost: one manual setup step, including opening the overlay initially from `omarchy-shell shell toggle ivan.varhop` before a binding exists. That invocation is a proposed setup route whose actual third-party behavior still needs the chart's pending proof.

For conflict checking, query `hyprctl -j binds` when checking the proposed chord. Show matching chord, description and submap. A known collision should prevent presenting the line as ready to add. Never generate `o.rebind` automatically. Let the user choose another chord, or deliberately replace the old action in their configuration. Restrict the settings chord field to a documented modifier/key vocabulary that can be validated and safely rendered into the Lua string. Do not accept arbitrary Lua. If keycodes, layout aliases or submap catch-all bindings cannot be resolved, say the check is incomplete and point to Omarchy's keybindings listing. “No matching named binding in this snapshot” is not a lifetime reservation or proof that every physical layout delivers it.

**Rejected options.** Automatic writes to the existing Lua file require editing executable user configuration and owning conflict replacement, reload errors and uninstall cleanup. A plugin-owned generated Lua file still needs a user-added `require`, so it adds a file without removing initial setup. A packaged-default edit is overwritten on updates. A new shortcut service duplicates a working host mechanism. No suggested chord at all leaves first setup unnecessarily open-ended.

**Evidence.**

- Tier `operator`: `issues/chart/varhop/INTAKE.md`, Scope and Source, read 2026-10-12/13: custom, fast access is requested. The already taken form-factor binding shape constrains the mechanism, not the chord or writer.
- Tier `better-than-training`: `/home/ivan/.config/hypr/hyprland.lua:14` and `:16-21`; `/home/ivan/.config/hypr/bindings.lua:3-18`, read 2026-10-13. Personal overrides load after defaults. Existing replacements explicitly unbind their old actions. [Omarchy hotkeys](https://omarchy.org/manual/hotkeys/), read 2026-10-13, directs custom bindings to that user file.
- Tier `better-than-training`: `/usr/share/omarchy/default/hypr/helpers.lua:58-100`, `:138-156`, and `/usr/share/omarchy/default/omarchy/shortcuts`, read 2026-10-12/13; [upstream helpers](https://github.com/basecamp/omarchy/blob/master/default/hypr/helpers.lua), read 2026-10-12. Third-party `ivan.varhop` is absent from the registered shortcut list. Its panel table becomes a command invoking shell toggle, rather than the process-free global dispatcher used by listed built-ins. Preserve that supported path instead of modifying the allowlist.
- Tier `better-than-training`, measured: `hyprctl -j binds` on 2026-10-13 returned 258 records. Super+Alt+P (mask 72, P), Super+Ctrl+J/U (mask 68), Ctrl+P/R/comma (mask 4) and Ctrl+Shift+P (mask 5) had no matching named binding or nonzero-keycode binding with those modifier masks. Alternatives J/U are examples, not extra defaults. This is a current-machine observation, not a summon or physical-key test.
- Tier `better-than-training`: `/usr/share/omarchy/bin/omarchy-menu-keybindings:565-599`, `:681-682`, read 2026-10-13. The listing derives records and can create/replace cache files, even with `--print`. I inspected its source and the existing `/home/ivan/.cache/omarchy/keybindings-43e1c7353598218ed01911cf82f4e504a3bf8f106d7f64355a9c7d995d2c1fbd.records`, rather than running a potentially writing listing command under this read-only brief. Live conflict measurements used Hyprland's JSON read.

**Pitfalls and removal.** Keep one owner for the binding by leaving it in user Lua. Prevent silent replacement by reporting known conflicts and never generating a takeover. Refresh the check at setup rather than claiming the chord stays free. The chart door's pending real third-party summon/hide/toggle and binding proof must remove the remaining runtime uncertainty before handoff. Include first-open focus/layer checks on each monitor as already carried by form-factor.

**Question missing from the fork.** Does “custom shortcut in settings” require a one-click installer, or is a checked copyable config line sufficient? My recommendation deliberately has the latter cost. If the operator needs the former, that is an explicit change in the configuration-writing contract, not an implementation detail.

## Q2. Settings surface and first run

**Pick.** Use one Settings view inside the overlay, reachable by a visible Settings action and Ctrl+comma from search or editor. Keep the current search state and exact editor cursor/selection while showing it. A Back action and settings Esc return to the prior view. The locked editor/search Esc rules still apply in their own views.

Settings contains GitHub login/account status and the existing login repair instructions, the repository picker plus validated `owner/repo` entry, Sync now, last successful import time, current load/sync errors, shortcut setup from Q1, and an explicit **Reset usage for this repository** action. Reset deletes only the selected repo's copy counts/recency, immediately updates empty-query recents and ranking, and reports write failures. It does not alter the clone, selection or draft. Cost: a small view and a reset operation, without a second settings panel or menu extension.

With no saved repo, opening goes directly to the repo picker within Settings. If `gh` authentication is missing or invalid, show its repair step there before an actionable picker. Choosing a repo initiates the already locked initial import. Do not turn opening Settings or the overlay into an automatic pull. With an existing library, repo replacement continues showing the old library until successful import, as taken. Sync now and Ctrl+R operate on the current committed selection. Show an in-progress state while one import/pull is active so another action cannot start a competing operation.

Save the complete merged plugin settings through `shell.updateEntryInline("ivan.varhop", fullSettings)`. Do not write a separate preferences file or put usage/error history in `shell.json`. The boolean result means changed versus unchanged, not a general durability acknowledgement. Do not classify every false result as a write error or report durable success solely from true. Persistence/error behavior needs the existing save proof and an appropriate read-back. The enabled plugin entry must already exist.

**Rejected options.** A separate Omarchy menu/panel creates another navigation and installation surface without an inspected generic preferences entry point for arbitrary overlays. A bar widget would add an unsolicited desktop element. New OAuth/token fields conflict with reuse of the stored `gh` login. Additional appearance, matcher or editor options expand v1 beyond the intake and locked behavior. A general “reset everything” action combines independent data owners and is unnecessary.

**Evidence.**

- Tier `operator`: intake and sync-and-auth Taken, read 2026-10-12/13, require repo selection/settings and already choose gh reuse, full-object save and manual sync. Search Taken requires the repo-scoped usage store. These decide what belongs here, without reopening authentication or ranking.
- Tier `better-than-training`: `/usr/share/omarchy/shell/services/PluginShellApi.qml:46-64`, `/usr/share/omarchy/shell/shell.qml:1094-1137`, read 2026-10-13. The installed API provides own-plugin lifecycle and settings callbacks. Host replacement copies the supplied object onto an existing entry, rather than patching individual keys or inserting a missing entry. The attempted [upstream PluginShellApi URL](https://github.com/basecamp/omarchy/blob/master/shell/services/PluginShellApi.qml) returned 404 on 2026-10-13. The [shell host reference](https://github.com/basecamp/omarchy/blob/master/shell/shell.qml) opened but redirects to a different branch/revision. Installed code is the evidence for this machine, not an assumed match with the public tree.
- Tier `better-than-training`: `/home/ivan/.config/omarchy/plugins/ivan.clock/Panel.qml:152-160` and `BarWidget.qml:45-52`, read 2026-10-12/13. This installed clone merges its complete existing settings before persistence. It does not establish a global-hotkey registration facility. No Lua binding files were found in the installed `ivan.*` plugin directories during the 2026-10-12 inspection.
- Tier `better-than-training`: `/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc:215-220`, read 2026-10-13, exposes plugin management, not a generic third-party preferences route. `/usr/share/omarchy/shell/plugins/bar/widgets/Spacer.manifest.json:19`, `shell/plugins/panels/weather/manifest.json:8-19` and `shell/shell.qml:1442-1465` expose named **bar-widget** settings metadata. Source searches of shell QML/JS and installed `ivan.bar` found no consumer implementing arbitrary overlay preferences. There is no installed `shell/plugins/settings` directory. This does not prove no future host settings UI can exist.
- Tier `better-than-training`: `/home/ivan/.config/omarchy/shell.json`, read 2026-10-12, currently has a top-level `ivan.notifications` entry and no `ivan.varhop` entry. [Omarchy's shell configuration reference](https://github.com/basecamp/omarchy/blob/quattro/shell/README.md), read 2026-10-13, describes inline entry settings. The installed host code governs this machine where a branch reference differs.

**Pitfalls and removal.** Preserve the full settings object to prevent erasing repo identity fields during another settings change. Keep text fields' native clipboard behavior separate from editor export. Error, repo and account strings are plain text as required by the Omarchy skill. Cancel/back from first run leaves no selected repo. Auth errors stay visible and do not silently substitute identities. The required save proof must verify unrelated entries survive and failures are observable.

**Question missing from the fork.** What happens to a draft when the user explicitly replaces its repo? Recommend preserving the source-backed in-memory draft with its original repo/prompt identity while it remains open, rather than silently rebuilding it from the replacement library. This needs an explicit operator choice if it is not already in the settled draft contract. Reset usage targets the selected library's repo, never a different repo just because its draft is present.

## Q3. Keys inside the overlay

**Pick.** Use these fixed keys for v1, with labels beside the corresponding actions:

| Key | Scope and action |
| --- | --- |
| Ctrl+P | Editor: Find another prompt, keeping the draft and returning to search. |
| Ctrl+Shift+P | Search: activate the pinned Resume draft action when a draft exists. |
| Ctrl+R | Overlay: the already locked manual pull for the selected repo. |
| Ctrl+comma | Search/editor: open Settings without losing either view's state. |
| Esc | Settings: Back. Editor/search: retain their locked hide/clear rules. |

Resume restores the draft's exact editing position. With no draft, there is no pinned action to invoke. Preserve the last search query/selection when using Find another prompt. That does not alter search Esc's clear-then-hide rule. Pull completion preserves result selection by prompt id and does not rewrite the draft. Cost: two prompt-navigation shortcuts to learn. A visible action remains available for each.

Match intended modifier combinations exactly, and keep navigation actions out of ordinary text-input handling. Preserve Tab/Shift+Tab, Enter, value undo/redo and the existing Ctrl+C/Ctrl+Shift+C export contract. Accept both Ctrl+V and Ctrl+Shift+V as native paste in editable fields. In search/settings, both copy variants should copy text selection and must never invoke editor export. Do not intercept Super+C/V separately or synthesize another forwarding layer.

**Rejected options.** Reusing editor Esc for Find would violate the taken hide behavior. Enter to return to search would remove multiline value entry. Tab for settings/navigation would break variable cycling. A shortcut that alternately finds/resumes depending on view hides two different actions behind one label. Ctrl+C or Ctrl+Shift+C for navigation is already reserved. User-remappable in-overlay shortcuts add a settings and conflict system the intake does not require.

**Evidence.**

- Tier `operator`: copy-and-close, variable-editing and search Taken/Carries, read 2026-10-12/13, fix existing keys and owe these navigation bindings. Ctrl+P/Shift+P are my recommendation, not a settled choice.
- Tier `better-than-training`: the live Hyprland read under Q1 found no matching compositor bindings for the proposed Ctrl chords on 2026-10-13. This removes known global interception on this machine, not editor/IME collisions or future user bindings.
- Tier `better-than-training`: `/usr/share/omarchy/default/hypr/bindings/clipboard.lua:1-14`, `:20-47`, read 2026-10-13; [upstream clipboard bindings](https://github.com/basecamp/omarchy/blob/master/default/hypr/bindings/clipboard.lua), source reference, installed code inspected 2026-10-13. Super clipboard forwarding targets the focused surface but chooses Ctrl versus Ctrl+Shift from the active underlying window's terminal tag. Thus a focused overlay above a terminal needs both paste forms. [Omarchy universal clipboard documentation](https://omarchy.org/manual/hotkeys/#universal-clipboard), read 2026-10-13, explains those two forms. Physical behavior still needs verification.

**Pitfalls and removal.** State-scoped key handling prevents search/settings selection copy from closing the app. A leaf done-criterion must exercise direct Ctrl keys and physical Super+C/V with the overlay over both a browser and a terminal, including key release, repeated use and selected-variable paste. No wtype forwarding is added. Verify Ctrl+P, Resume and Settings preserve the exact draft selection, and Ctrl+R cannot edit a value or replace a draft through refresh.

**Question missing from the fork.** Is returning to the prior search query preferred to clearing it when Find is invoked? Recommend preserving it. This is separate from the already decided behavior of pressing Esc in search.

## Q4. Removal, disable, updates and customization

**Pick.** Follow native plugin lifecycle commands. Do not add install/uninstall hooks or deletion triggered by unloading the plugin. State explicitly that native removal cleans the plugin entry/source, while manual binding and external cache/usage remain user-owned. Provide precise cleanup locations as part of setup/removal guidance, without a new cleanup service. Cost: full removal of those retained files is manual.

| Resource | Native lifecycle result and proposed v1 policy |
| --- | --- |
| `~/.config/hypr/bindings.lua` line | Not removed by plugin disable/remove. User deletes the Varhop line. |
| `~/.cache/varhop/` two clone slots | Not removed by native lifecycle. Retain unless the user deliberately deletes this Varhop-owned cache. |
| Repo-scoped usage/state files | Not removed by native lifecycle. Retain until the explicit per-repo usage reset or user cleanup of the documented Varhop-owned state directory. |
| `shell.json` plugin entry, including selected repo | Disable removes the entry. Re-enable inserts `{ id: "ivan.varhop" }`, so the picker is required again. Remove disables first when active. |
| Plugin source under `~/.config/omarchy/plugins/ivan.varhop/` | Removal deletes a git checkout, unlinks a symlink, or backs up a non-git folder. |
| Stored shared `gh` login | Never removed or logged out by Varhop cleanup. |

Do not work around disable by mirroring the selected repo into a second preferences file. That would reopen the taken storage ownership. Existing external cache is not permission to infer a selected repo after re-enable. Updates use `omarchy plugin update`; the in-memory draft is lost on reload/update as already accepted. Never treat unload or destruction as uninstall, because the same path also occurs on code reload.

For v1, customizable means the global shortcut, GitHub repo/library content and inherited Omarchy theme. Usage can be reset. Search rules, variable grammar, editor navigation and animations have the chosen product behavior. No custom keymap, independent palette, per-repo ranking knobs or cache retention configuration.

**Rejected options.** Auto-cleaning on plugin teardown risks destroying state during updates. An uninstall hook is not part of the inspected native command contract. Automatic deletion of shared gh credentials or user-authored prompt repositories exceeds ownership. Preserving selection outside shell.json adds a duplicate source of truth. Patching packaged lifecycle scripts would break compatibility with normal updates.

**Evidence.**

- Tier `better-than-training`: `/usr/share/omarchy/bin/omarchy-plugin-add:120-174`, read 2026-10-13: clone, validate, move, rescan, optionally enable. `/usr/share/omarchy/bin/omarchy-plugin-disable:22-24` delegates to `setPluginEnabled`. `/usr/share/omarchy/shell/services/PluginRegistry.qml:524-542`, `:555-557`, read 2026-10-13, shows fresh entry insertion and removal of the entire third-party entry, including settings. [Upstream registry](https://github.com/basecamp/omarchy/blob/master/shell/services/PluginRegistry.qml), source reference, installed code inspected 2026-10-13.
- Tier `better-than-training`: `/usr/share/omarchy/bin/omarchy-plugin-remove:69-123` and `omarchy-plugin-update:67-79`, `:130-131`, read 2026-10-13. Removal does not touch binding/cache/state; updates validate and rescan. [Upstream remove command](https://github.com/basecamp/omarchy/blob/master/bin/omarchy-plugin-remove) and [update command](https://github.com/basecamp/omarchy/blob/master/bin/omarchy-plugin-update), source references, installed versions govern the conclusions.
- Tier `practitioner` for user-owned customization: the Omarchy maintainer team's [first-hand plugin/cloning guide](https://omarchy.org/manual/shell-plugins/#cloning-a-built-in-to-modify-it), read 2026-10-13, advocates edits in user copies rather than packaged sources. That agrees with preserving package ownership. Tier `better-than-training` for lifecycle semantics: the same [official manual](https://omarchy.org/manual/shell-plugins/), read 2026-10-13, documents no install hooks and native removal. Searches for Omarchy plugin settings/hotkey practitioner accounts found no stronger independent case addressing this exact third-party overlay lifecycle; installed code determines the recommendation.

**Pitfalls and removal.** Tell the user before disable that it removes selected-repo settings, and make re-enable route through the picker. Never infer selection from leftover cache. Only explicit usage reset changes copy history. A leaf lifecycle check must prove disable/re-enable removes/recreates the entry, update retains configured selection when the entry remains, and remove leaves the specified binding/cache/state. The chart's external-operation proof requirements remain pending for actual add/disable/update/remove calls. None was run under this read-only brief.

**Question missing from the fork.** Is losing repo selection on disable acceptable? It is native behavior on this installed shell, not just on uninstall. If the operator requires disable/re-enable to preserve it, that contradicts the current single-entry settings contract and must be settled before leaf design.

## Proof limits

Installed baseline inspected: omarchy-dev and omarchy-settings-dev `4.0.0.r6912.gdefbf90-1`, Hyprland `0.56.2-4`, Quickshell `0.3.2-4`, Qt `6.12.0-2`. File/line citations describe that baseline. Public GitHub source links were checked on 2026-10-13 and redirect from basecamp/master to omacom/quattro, except the PluginShellApi URL, which returned 404. They identify the corresponding project but do not establish parity with the installed revision. No desktop configuration, plugin source, cache, clipboard, credential or library was changed. Source inspection and free-chord measurements do not replace the pending third-party runtime, persistence or lifecycle proofs.
