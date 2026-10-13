# Map A (blind)

## Forks
M1 Disposal of failed leaf overlay-plugin. akrogon has no abandon command (`akrogon` usage line: install|init|config|preflight|phase|next|pull|close|park|unpark|pause|unpause|sync|status|...); docs/guide/problems.md:16-27 only covers resuming a failed leaf at an active phase. A changed contract is new intake, not an edit of the emitted brief (shapes.md). Options:
 a. Retire the leaf folder (archive plan/reviews/report into the new chart), keep branch 0df6f48 as the base a new leaf adopts (same slug so worktree setup adopts the branch). Keeps proven sync/search/copy/latency work. Risk: carries the stacked-field editor and 4 fix rounds of patches; planner must decide what to keep.
 b. Retire leaf, delete branch and worktree, new leaf starts from main. Clean, costs rework of proven parts (latency matrix, sync, copier).
 c. Resume failed leaf with operator doing OA1-OA4, then file F1-F7 as a follow-up leaf. Keeps contract, but OA2/OA3 test an editor F5 replaces, so the proofs are wasted.
 Removal is a step on main by the door (issues/ paths), plus worktree/branch/tab cleanup.
M2 Editor shape (F5) reopens variable-editing lock "editor mechanism left to leaf design" and done-criteria 5. Inline: one flowing TextEdit where only token ranges are writable (C's original mechanism in variable-editing Findings). Keeps: values only, Tab per unique name, mirrors, Delete reset, copy rebuilt from source. Pitfall: guarding prose in a TextEdit (IME, paste, undo) is the hard part; done-criterion "typing in prose leaves prose unchanged" stays.
M3 Theme/fonts/transparency (F2-F4). Style.qml:323-335 exposes font.menuFamily and size tokens; Color.qml:100-107 menu.* composed with menu.background-alpha default 1.0, so the panel is opaque unless the theme sets that alpha. Operator's "transparent" surfaces are Hyprland window opacity 0.93 (~/.config/hypr/terminal-opacity.lua:1), which does not apply to layer surfaces. Options: plugin uses Commons.Color.menu.* as-is and the operator sets menu.background-alpha (affects all Omarchy menus) / plugin applies its own fixed alpha (e.g. 0.93) / plugin setting.
M4 Picker filter (F1): filter /user/repos list by substring on typed text, Enter selects top match vs exact typed. Small.
M5 Visible back and settings (F6/F7): header buttons (back arrow, cog) plus keep chords. Pitfall: layer surfaces reject synthetic clicks on this host (report.md third round), so any mouse-only control is not agent-provable; every control must also have a key.
M6 Live done-criteria the agent cannot prove (OA1-OA4, report.md:198-205). Options: move them to a one-time operator check after merge (precedent operator 4a in variable-editing Taken) / operator does them before merge / drop. OA1 needs a second repo: operator creates a throwaway prompts repo, a human prerequisite.

## Practitioner questions
- How do other Omarchy overlays (Commons menus) render text: font.menuFamily + Style.font tokens? Copy their pattern.
- Is a single TextEdit with read-only spans viable in Qt Quick, or use per-token inline TextInputs in a Flow (breaks line wrap of prose)?

## Split
One issue, destination "overlay usable daily". Leaves could be: L-a theme+fonts+transparency+visible controls+picker filter (F1-F4,F6,F7), L-b inline editor (F5). They touch the same files but are independently checkable; parallel. Or one leaf if branch reuse is chosen (both edit the adopted branch; two leaves cannot both adopt one branch). With M1a, one leaf is simpler.

## Low confidence
- That akrogon worktree setup adopts an existing same-slug branch for lifecycle leaves (only stated for direct-route continuation in chart-issues SKILL.md).
