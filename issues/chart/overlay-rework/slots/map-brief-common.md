# Opening map brief (chart door, varhop, 2026-10-13)

You are a charting peer. Build your OWN territory map, blind: do not read other slots' map files. Do not edit any repo file. Write only your return file.

## Intake
1. GitHub seed Tamdoma/varhop#1 (verbatim mirror): /home/ivan/Work/omarchy-customizations/varhop/issues/seeds/1-overlay-live-test-variables-render-as.md
   F1 picker unfiltered, F2 fonts small and not Omarchy fonts, F3 theme not inherited, F4 panel opaque, F5 variables must stay inline in the prompt text (no stacked per-variable fields), F6 no visible back, F7 no visible settings entry.
2. Failed leaf `overlay-plugin` (phase failed at check.fix, cause blocked, fix rounds 4): operator-only live items OA1 second GitHub repo, OA2 physical cursor/selection resume, OA3 physical paste over browser/terminal, OA4 physical reset-button click. Files: /home/ivan/Work/omarchy-customizations/varhop/issues/open/varhop/overlay-plugin/{brief.md,design.md,state.yaml,plan.md,review-B.md,implementation/report.md}
3. Operator note, verbatim: "Look at the pooled issues, we need to resolve all of them." and "We also need to decide what to do with the overlay plugin, which has failed as a leaf. I think it needs to be removed."
   Treat "removed" as unclear: it could mean drop the failed leaf and its branch, re-chart a new overlay leaf, or drop the plugin. Map the options; do not decide.

## Live surfaces
- Leaf worktree, branch overlay-plugin, head 0df6f48: /home/ivan/.akrogon/worktrees/varhop/overlay-plugin (Varhop.qml, qml/*.qml, lib/*.mjs, test/)
- Merged prerequisites on main: prompt-core (lib/*.mjs), repo-sync (bin/varhop-sync). Repo root: /home/ivan/Work/omarchy-customizations/varhop
- Original chart and locks: /home/ivan/Work/omarchy-customizations/varhop/issues/chart/varhop/CHART.md and forks/*.md (variable-editing, settings-and-hotkey, search, copy-and-close are most relevant), proofs-overlay.md
- Omarchy shell: /usr/share/omarchy/shell (Commons/Style.qml, Commons/Color.qml, other overlays/plugins for how they get fonts, theme and transparency)
- akrogon command: `akrogon --help` (what it offers for a failed leaf: retry, abandon, removal)

## Existing locks
All forks in issues/chart/varhop/CHART.md "Forks taken" are locked unless the intake contradicts them. F5 contradicts the editor shape of variable-editing (values-only stops rendered as separate fields); flag exactly which locks it reopens.

## Task
Write a territory map, proportional, with:
1. Material forks (questions whose answer changes the outcome), each with options and what each option could break or invite later, not only now.
2. Questions a practitioner (QML / Quickshell / Omarchy plugin author) would ask.
3. Pitfalls over the work's lifetime and what removes each.
4. How the failed leaf should be disposed (keep branch as base, restart, close), with evidence from the akrogon command and the leaf state.
5. Proposed split by destination: leaves, parallel vs dependent, and which F-items/OA-items each covers. Say which OA items are still needed if the done-criteria change.
Cite file:line for every claim about code. Mark low-confidence items.
