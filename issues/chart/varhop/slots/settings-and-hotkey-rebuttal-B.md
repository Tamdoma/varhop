# Settings and hotkey: rebuttal B

- **F1 Attribution corrections.** D-a: B measured Super+Alt+P free on this machine, not stock Omarchy generally (B Q1: `hyprctl -j binds`, 258 records, 2026-10-13). D-b: B proposed Resume from search only. I now concede extending it to settings when a draft exists. The rejected-options merge also overstates B: I rejected a second shortcut mechanism and an additional settings surface, but did not establish that third-party menu integration is impossible or explicitly reject `hyprctl keyword` by name. Keep those stronger claims under the slots that proved them.

- **F2 Conflict-check omissions.** Hold B Q1: validate a bounded chord vocabulary, show submap as well as description, and distinguish an incomplete keycode/layout/catch-all check from “free.” Known collisions must prevent presenting a line as ready to add. A modmask+named-key warning alone drops these qualifications. Evidence: B's measured read and `/usr/share/omarchy/default/hypr/helpers.lua:138-156`, read 2026-10-13. No automatic takeover.

- **F3 Dropped clipboard/persistence behavior.** Restore explicit Ctrl+V **and** Ctrl+Shift+V paste, and native selection-copy for both copy variants in search/settings. The browser/terminal proof alone does not specify this behavior (`clipboard.lua:20-47`, read 2026-10-13). Also preserve B's save qualification: `updateEntryInline` replaces the full existing entry; false can mean unchanged and true is not a durability acknowledgement (`shell.qml:1094-1137`, same date). Add save/error read-back to the proof list.

- **D-c Hold Back from settings.** Returning to the prior search/editor view preserves context. Concede C's first-run Esc hides, since there is no prior view. The locked editor/search Esc rules remain intact. Evidence: B Q2/Q3 and copy-and-close Taken.

- **D-d Hold Ctrl+R in the editor.** Pull targets the committed selected repo and cannot change the draft. This follows sync-and-auth Taken's “Ctrl+R in the overlay.” Concede inert Ctrl+R in picker text fields to avoid ambiguity while choosing a replacement, and prevent competing operations during import. This picker exception was C's position, not B's original one.

- **D-e Hold current-repo reset.** Do not erase another repo's history. Search Taken explicitly scopes usage by repo id. Storage failures stay visible. A second-press confirmation does not justify widening deletion scope.

- **N1 Hold fresh picker after disable.** The `(B,C)` tag supports lost selection, not C's cached-repo pre-highlight proposal. B did not endorse that. Do not infer selection from cache (`PluginRegistry.qml:541-542,555-557`, read 2026-10-13). Cached-repo suggestions require an explicit new choice and the existing identity/reconfirmation checks.

- **N2/N3 Hold paths-only cleanup and one summon chord.** No Delete local data button or second settings shortcut in v1. These add mechanisms beyond the requested settings and native lifecycle. I concede using `shell summon` instead of my proposed initial `shell toggle` route, provided that exact command remains covered by the pending third-party proof. It is a changed proposal, not something B already measured.
