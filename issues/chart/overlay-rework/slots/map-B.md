# Slot B independent territory map

2026-10-13. Read the intake, failed-leaf records, relevant chart locks, current implementation, installed Omarchy components and installed akrogon source. No other slot's map was read. No repository or runtime state was changed.

Path abbreviations below: `R` = `/home/ivan/Work/omarchy-customizations/varhop`, `W` = `/home/ivan/.akrogon/worktrees/varhop/overlay-plugin`, `S` = `/usr/share/omarchy/shell`, `A` = `/home/ivan/Work/infra/akrogon`. Every abbreviated citation resolves under these absolute roots. F1–F7 refer to the seed. OA1–OA4 refer to the pending operator actions, not the older review's separately numbered findings.

## Evidence that changes the map

- **B1. Failure is a recorded proof blocker.** The state says `failed`, cause `blocked`, originating in `check.fix`, with four fix rounds and OA1–OA4 named. It does not say the implementation must be deleted. The inspected worktree is clean at `0df6f48e7e8718d53eb26f8eb06ce44ae094fbf2`. Latest recorded configured check is 77 pass, zero fail. Those tests do not settle the outstanding live behavior. Sources: `R/issues/open/varhop/overlay-plugin/state.yaml:2`, `:16`, `:35`; `review-B.md:415`, `:419`, `:429` under the same leaf. Git status and rev-parse were run read-only in W.
- **B2. F1, F2 and F5 have direct implementation evidence.** The repository list repeats all `root.repos`, independent of the typed field. Text sizes are fixed pixels. The editor gives every source segment a full-width row in a Column, including separate TextAreas for first occurrences. Sources: `W/qml/SettingsBody.qml:188`, `:219`; `W/qml/EditorBody.qml:250`, `:259`, `:282`, `:296`; `W/qml/SearchBody.qml:109`, `:200`.
- **B3. F3 has a concrete live-update risk, but the reported initial theme mismatch is not diagnosed.** Root colors read Commons.Color, yet each Loader assigns `item.colors = root.colors` once rather than installing a binding. Inference: replacing root's color object on theme changes leaves existing views with the previous object. The card itself binds directly to the menu palette. Also, foreground uses the global role while Omarchy's emoji overlay uses `menu.text`. Sources: `W/Varhop.qml:63`, `:775`, `:821`, `:863`, `:898`; `S/plugins/emojis/Emojis.qml:27`. Confidence is high in the assignment distinction, lower in its contribution to the operator's observed initial appearance. Inspect actual rendered values before claiming a complete F3 cause.
- **B4. F4 is not explained by a missing alpha operation.** `Color.menu.background` already composes `menu.background-alpha`, defaulting to 1.0. Varhop and Omarchy's emoji overlay both consume this role. Varhop additionally draws `menu.scrim` behind the card. A screenshot alone cannot distinguish the chosen surface policy from wrong runtime values or compounded backdrop opacity. Sources: `S/Commons/Color.qml:75`, `:100`; `W/Varhop.qml:759`, `:775`; `S/plugins/emojis/Emojis.qml:27`, `:31`. Cause remains low confidence without a live comparison.
- **B5. Navigation behavior exists to reuse.** Editor Ctrl+P emits findAnother, whose root handler captures the draft and restores search. Settings routing captures editor state before unloading it and records the source view. The visible controls are missing from these view definitions. Sources: `W/qml/EditorBody.qml:216`, `:243`; `W/Varhop.qml:792`, `:803`, `:866`, `:923`; `W/qml/SearchBody.qml:92`; `W/qml/SettingsBody.qml:104`.

## Material forks

### Q1. What does removing the failed overlay mean?

This comes first because it changes every proposed leaf.

| Option | Outcome | What it could break or invite later |
|---|---|---|
| O1 | Keep the current leaf and branch, revise its contract through charting, then recover to planning. | Preserves repair history and regression tests. Old criteria and new criteria must be reconciled explicitly or review repeats the same blocked loop. Recovery retains fix_rounds. |
| O2 | Retire the old leaf as superseded, create a new overlay contract, retain its branch/head as the implementation base. | Separates the new inline requirement from the old contract. Needs an explicit record/branch ownership transfer so two leaves do not both claim the same unmerged implementation. Akrogon has no built-in abandon operation. |
| O3 | Retire the old leaf and restart the overlay from main, keeping old evidence as reference. | Removes the current UI implementation from the new base, but discards repaired integration and requires re-proving it. The branch also contains search/import performance changes beyond main, so copying only QML loses part of the working baseline. |
| O4 | Drop the overlay product altogether. | Leaves the existing prompt-core and repo-sync work, but abandons the chart's hotkey/search/editor destination. F1–F7 become cancelled work, not fixed defects. A replacement app would require a separately chosen destination and reopening form-factor. |

No option is selected here. Preserve the current head and evidence until the operator resolves Q1. The source of O3's extra loss is `R/issues/open/varhop/overlay-plugin/plan.md:22` and `implementation/report.md:170`. Read-only `git diff --stat main...overlay-plugin -- lib bin` shows changes to `lib/import.mjs` and `lib/search.mjs`. Existing prerequisites report merged at `R/issues/open/varhop/prompt-core/state.yaml:2` and `R/issues/open/varhop/repo-sync/state.yaml:2`.

### Q2. Which mechanism can meet the inline editor contract?

This is an engineering fork to resolve with evidence, not an invitation to reopen values-only editing.

- **O5. One flowing text document with editable variable ranges.** It directly presents the complete prompt. It must protect prose through every mutation path, maintain ranges as values change length, distinguish repeated occurrences and preserve per-name undo. A key-only guard would be an insufficient design because the existing input paths include direct native paste calls and IME commit (`W/qml/FieldKeys.js:9`, `W/qml/EditorBody.qml:208`).
- **O6. A flowing read-only prompt with a native input positioned at the active occurrence.** This keeps prose outside the writable model. It introduces layout and caret-position work for wrapped and multiline values, mirrored occurrences, scrolling and font changes. It is acceptable only if the active input participates visually in the prompt and does not recreate a separate variable form.

Both must rebuild copied text from original segments plus values, as the current `W/lib/rebuild.mjs:1` does. Do not infer copy bytes from displayed text. Neither mechanism is proven here. A small disposable feasibility probe, if chosen by the door, should cover adjacent variables, repeats, multiline values, empty/unset states, selection, paste and reflow before committing to one.

**Exact lock accounting:** F5 supersedes the separate-stop presentation chosen in `R/issues/open/varhop/overlay-plugin/plan.md:11` and narrows the previously open mechanism in `R/issues/chart/varhop/forks/variable-editing.md:31`. It does **not** contradict values-only/prose-fixed, unique-name Tab order, mirrors, wrap, reset, exact cursor/selection resume, newline entry, per-variable undo, grammar or source-based rebuild at that fork's `:27`–`:30`. The current stacked rendering was a leaf mechanism, not an operator mandate to use a form. Changing to whole-body editing would require a new operator decision. The existing accepted input-normalization policy also remains locked.

### Q3. What surface should “inherits theme and transparency” match?

- **O7. Match Omarchy's menu/emoji/clipboard overlay surface, including its configured alpha and scrim.** This follows the inspected sibling convention and avoids a second visual configuration system. If the active menu alpha is 1, faithful inheritance is still opaque. Confirm whether that is the surface the operator means.
- **O8. Match a different named Omarchy surface or explicitly require translucency even when menu is opaque.** This may match the desired appearance, but changes the surface policy and needs a specified role/alpha source. A hard-coded alpha would diverge from later theme changes. Do not solve this by changing the user's global theme as part of a plugin repair.

Font inheritance is already settled by the request. Use the actual shell font family and size tokens, with sizing that follows the font. Omarchy exposes menuFamily and scaled sizes at `S/Commons/Style.qml:318`, `:323`, and its emoji overlay derives dimensions from those tokens at `S/plugins/emojis/Emojis.qml:35`–`:43`. The outstanding question is the comparison surface, not whether to invent plugin font settings.

### Q4. How does the filtered repository picker accept input?

- **O9. Filter the loaded list locally as the existing field changes, retaining exact owner/repo Enter lookup and row selection.** This is the smallest extension of F1. Empty query restores all rows. A partial query needs a clear no-match state and must not silently select another repository.
- **O10. Make it a navigable suggestion picker where Enter selects the highlighted match.** This is a larger interaction change. It needs a rule separating a typed exact repository from a highlighted partial match, and must preserve lookup of an authorized repo absent from the displayed list.

The existing CLI already paginates `/user/repos`, and exact lookup is a separate operation (`R/bin/varhop-sync:86`, `:92`). Filtering does not require network requests per keystroke. Installed `SearchableDropdown` provides local case-insensitive substring filtering and keyboard selection (`S/Ui/SearchableDropdown.qml:74`, `:126`), but uses a popup and imports `qs.Commons` (`:3`). Reusing it is not behaviorally or test-harness equivalent to the current plain QtQuick field. Its availability is an implementation reference, not a reason to widen F1.

### Q5. What live evidence will the next contract require, and who can supply it?

- **O11. Preserve the required outcomes and arrange the existing operator actions on the final build.** This retains confidence but requires the named repository grant and physical input availability before another leaf is dispatched into the same blocker.
- **O12. Explicitly narrow selected done-criteria to component checks or defer named live acceptance.** This changes the assurance delivered, not necessarily the product behavior. Record each removed live gate, its residual risk and owner. A component test passing does not establish that paste works in the real overlay.
- **O13. Retain autonomous live criteria and first deliver missing input/proof machinery.** This introduces a real prerequisite destination and time cost. It needs a known-good case passing and a deliberate break failing. No particular new tool is established as sufficient by this map.

The old chart already deferred middle-click, dead keys and IME preedit until after merge, but kept exact resume and the browser/terminal key-state proof as done-criteria (`R/issues/chart/varhop/forks/variable-editing.md:33`, `R/issues/chart/varhop/forks/settings-and-hotkey.md:59`). Do not silently extend that deferral to OA2/OA3. The report's claim of an environment limitation is not proof that the plugin's paste integration works (`R/issues/open/varhop/overlay-plugin/review-B.md:430`, `:455`).

## Practitioner questions

- **P1. Where does a click on a repeated inline value place the caret?** The existing lock selects the shared name and makes the next Tab advance to the next unique name. Its present implementation focuses the first occurrence (`W/qml/EditorBody.qml:371`). The inline design must specify occurrence position without accidentally changing the shared-value contract.
- **P2. How are zero-width values revisited and reset without adding visible prompt text?** The model distinguishes an empty value from an unset token (`W/lib/rebuild.mjs:8`). Test adjacent empty variables and an empty value at the beginning/end of a line. Marking an active range must not become copied content.
- **P3. Which mutations cross a variable boundary?** Selection spanning prose, Backspace/Delete at edges, native context-menu paste, IME composition, and undo must all preserve fixed prose. Current separate TextAreas structurally isolate values (`W/qml/EditorBody.qml:282`), so that guarantee cannot be assumed after replacement.
- **P4. Can colors and font changes reach an already-open view without destroying its draft?** Test both open and hidden states. The root uses conditional Loaders (`W/Varhop.qml:813`, `:854`, `:884`) and the current color injection is a snapshot. Retain the plain QtQuick testing boundary by passing reactive style properties unless deliberately replacing that architecture (`R/issues/open/varhop/overlay-plugin/brief.md:6`).
- **P5. Do larger fonts still fit settings, result rows and the card?** Current dimensions include a 34-pixel repo field, 26-pixel repository rows, 44-pixel result rows and a 560-by-480 capped card (`W/qml/SettingsBody.qml:192`, `:224`; `W/qml/SearchBody.qml:185`; `W/Varhop.qml:771`). Font-token substitution alone can create clipping. Verify content sizing, wrapping and scrolling at the user's text size.
- **P6. Do visible Back and Settings actions preserve the same state as shortcuts?** Use the same transitions. Keep editor Esc as hide, Back as return to the prior search, and settings Back as return to its source view. Those meanings are already locked (`R/issues/chart/varhop/forks/copy-and-close.md:26`, `R/issues/chart/varhop/forks/settings-and-hotkey.md:33`, `:36`). F6/F7 require visible access, not new navigation semantics. Keyboard focus for new controls must not consume the editor's unique-name Tab cycle.

## Lifetime pitfalls and what removes them

- **R1. Re-charting erases outstanding evidence.** Carry an explicit old-criterion → new-criterion → evidence/owner table, including every OA item. Preserve useful tests and commits irrespective of leaf naming. The last review expressly leaves live acceptance incomplete (`R/issues/open/varhop/overlay-plugin/review-B.md:435`).
- **R2. Old code is tested after a UI repair.** Record the deployed revision, verify the installed files, restart the shell after product changes, then run one final-build verification batch. The existing proof demonstrated updates retaining old loaded QML until restart (`R/issues/chart/varhop/proofs-overlay.md:57`, `:58`). Do not count tests of the replaced editor as proof of the inline editor.
- **R3. Native-looking styling freezes on the first theme.** Use live dependencies for palette/font properties and verify a theme/text-size change with a draft present. The shell replaces merged theme values and applies them to Style (`S/Commons/Color.qml:208`). Remove the snapshot at the view boundary rather than adding refresh buttons or a plugin-specific theme cache.
- **R4. New buttons reproduce OA4.** MouseArea-only controls lack the existing native button's keyboard path. Omarchy's Button has opt-in focus and Return/Enter/Space activation (`S/Ui/Button.qml:32`, `:66`–`:69`), while reset is currently only a MouseArea (`W/qml/SettingsBody.qml:374`). Keyboard activation can prove reset isolation if the revised criterion allows it, but does not prove physical mouse delivery.
- **R5. Inline display becomes the source of copied content.** Keep source segments and values as the authoritative model, preserving the existing rebuild contract. Test literal pasted token syntax, repeats, CRLF source and final newline. Source reconstruction already distinguishes unset and empty (`W/lib/rebuild.mjs:5`).
- **R6. Multiple leaves compete for the operator's desktop.** Parallelize independent code work only where useful, and serialize Wayland/clipboard/live runs. Save, restore and compare both selections and record fixture ownership. The existing design identifies the shared keyboard/clipboard resource (`R/issues/open/varhop/overlay-plugin/design.md:136`), and readiness names exact cleanup obligations (`readiness.yaml:36`–`:40` under that leaf).

## Failed-leaf disposal: actual command support

Read-only `akrogon --help` was attempted. It throws a Usage error, listing `phase`, `close`, `park`, `unpark`, etc. It advertises no retry, abandon or remove verb. `command -v` and `readlink -f` resolve the executable to `A/src/akrogon.ts`; its dispatcher confirms the verb set (`:53`–`:188`).

- **C1. Recovery exists through phase.** After the blocker/contract is resolved, the operator can choose an active phase, for example `akrogon phase overlay-plugin plan.synthesis` for a revised plan or `akrogon phase overlay-plugin check.fix` for remaining execution. Recovery omits `--slot`. Failed cannot jump directly to merged. Source: `A/src/routing.ts:37`, `A/src/phase.ts:351`, `A/docs/guide/phases.md:69`. Recovery keeps fix_rounds (`A/src/phase.ts:159`). A new slug does not solve the missing physical proof.
- **C2. Close is for a GitHub source identity.** It is not a leaf-abandon command. The dispatcher requires the source pattern and `--by` (`A/src/akrogon.ts:110`). Closing Tamdoma/varhop#1 would not retire the branch, nor prove its seven observations resolved.
- **C3. Park is not an escape for this allocated leaf.** It moves a whole issue folder and rejects a leaf with a tab or worktree (`A/src/park.ts:23`, `:55`). Current state has both (`R/issues/open/varhop/overlay-plugin/state.yaml:18`). It also operates on the parent issue name, not this nested leaf slug.
- **C4. Retirement needs an explicit administrative procedure.** The inspected command offers no failed-leaf cancellation state (`A/src/routing.ts:2`). Its documented automated branch/worktree cleanup follows merged completion (`A/docs/guide/merge.md:57`). If O2/O3/O4 is chosen, settle how records are archived, ownership transferred, and branch/worktree retained or removed before creating colliding replacement records. Do not fake merged or delete evidence merely to empty the board. Exact cancellation procedure remains unresolved, not assumed to be supported.

The latest report records the runtime plugin and test fixtures already removed (`R/issues/open/varhop/overlay-plugin/implementation/report.md:209`). That historical cleanup is distinct from deleting the failed leaf, its branch or the product. This map did not inspect or mutate the current desktop installation.

## Proposed destination and work split

**L1, varhop: revised overlay delivery**, either the recovered leaf under O1 or a successor under O2/O3. A single completion owner is the smallest default because the overlay implementation is still unmerged and the requested result is the integrated plugin. It owns F1–F7 and whichever OA1–OA4 gates survive Q5. It consumes the already-merged prompt-core and repo-sync contracts. It must explicitly retain or replace the branch's performance repairs noted in B1/O3, rather than treating main's core as byte-identical.

Within L1, two independently checkable work areas can proceed in parallel after their injected style and navigation interfaces are fixed:

| Area | Coverage | Ordering |
|---|---|---|
| U1 shell/settings/search presentation | F1, F2, F3, F4, F6, F7. Picker selection/switch and reset paths feed OA1/OA4. | Can develop alongside U2. Own shared root routing/style integration explicitly. |
| U2 inline editor | F5, applying U1's style contract. Exact selection, copy/paste and resume feed OA2/OA3. | Can develop alongside U1. Final root integration and live checks depend on both. |
| U3 final deployed acceptance | All F-items plus retained OA gates and existing locked behavior affected by the changes. | Depends on U1/U2. Desktop runs are serialized. |

This is a proposed work decomposition, not an instruction to spawn agents. If the operator requires separate leaves, first identify one owner for the unmerged common plugin base. Then shell/picker and inline-editor repair leaves can be independent after that base, with a final integration dependency. Do not invent a separate foundation leaf solely for scheduling convenience or pretend two branches independently own the retained implementation.

**L2, conditional proof-machinery destination:** only if O13 is selected and a specific missing capability is established. It precedes the live-dependent product leaf and covers whichever of OA2/OA3/OA4 it actually demonstrates. Repository/destination is unresolved. No general Omarchy or akrogon cleanup feature is proposed.

**If O4 is chosen:** cancel the product repair scope explicitly. There is no F-item implementation leaf and no OA acceptance obligation for a product that is no longer being delivered. Record retirement and resource disposition separately. Keep the already-merged core/sync work unless the operator explicitly expands removal to it.

### OA carry-forward under changed criteria

| Item | Still required when | Can cease to be a merge gate only when |
|---|---|---|
| OA1 | Real successful repository switch with a draft remains a criterion. Authorize a second existing readable prompt repo, its identity and retention/cleanup terms. | That live criterion is explicitly replaced or the feature is dropped. Synthetic usage isolation does not require this GitHub grant. Source: `R/issues/open/varhop/overlay-plugin/review-B.md:439`–`:443`. |
| OA2 | Exact cursor/selection resume remains a live criterion. Run it on the final inline editor, not the old stacked form. | An approved replacement proves that outcome autonomously, or the live gate is explicitly narrowed/deferred. Inline redesign alone does not remove it. Source: same review `:445`–`:449`. |
| OA3 | Real browser/terminal paste-copy behavior remains required. Verify both value and search fields and treat a physical failure as a product finding. | An approved reliable live route proves it, or the live gate is explicitly narrowed/deferred. A component pass alone is insufficient. Source: same review `:451`–`:455`. |
| OA4 | The physical reset-button click itself remains required. Reset isolation still needs a second local repo-id usage file and byte comparison. | The revised criterion accepts another demonstrated UI activation path, such as a focusable button, or the physical gate is explicitly deferred. Calling reset logic directly would not prove the UI path. Source: `R/issues/open/varhop/overlay-plugin/implementation/report.md:186`–`:205`; `W/Varhop.qml:914`. |

The original post-merge middle-click/dead-key/IME checks remain separate obligations unless explicitly changed (`R/issues/open/varhop/overlay-plugin/design.md:155`). The decisive next operator choice is Q1. The decisive technical uncertainty for retained product work is an inline editor that preserves the locked input and draft semantics, with a verification plan that can actually finish.
