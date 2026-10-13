# Intake: overlay-rework

## Scope
Destination varhop. Resolve the pooled overlay work: GitHub report Tamdoma/varhop#1 (F1-F7) and the failed leaf overlay-plugin (operator-only items OA1-OA4), including what happens to that leaf.

## Provenance
- GitHub: Tamdoma/varhop#1
- Operator: chart-issues args 2026-10-13
- Operator: mid-turn note 2026-10-13

## Source: Tamdoma/varhop#1
# Overlay live test: variables render as stacked form fields, no visible back or settings, picker unfiltered, theme not inherited

Source: Tamdoma/varhop#1
URL: https://github.com/Tamdoma/varhop/issues/1

Origin repo: Tamdoma/varhop

Unverified intake.

## Observation
Operator live test of the `ivan.varhop` overlay (leaf `overlay-plugin`, worktree head `0df6f48`, installed via `omarchy plugin add`, opened with `omarchy-shell shell summon ivan.varhop` and Super+Alt+P). Operator's words: "It's all very clunky."

- F1. Repo picker: typing in the `owner/repo` field does not filter the repository list. The full `/user/repos` list stays shown. Only an exact typed `owner/repo` plus Enter, or a click on a row, selects.
- F2. Fonts are too small and do not follow the Omarchy font settings.
- F3. The overlay does not pick up the operator's Omarchy theme.
- F4. The panel is opaque, not transparent like the operator's other Omarchy surfaces.
- F5. In the editor, each `{{NAME}}` variable gets its own line with its own form field. The operator wants the variables to stay inline inside the prompt text so the prompt always looks the same, with no per-variable form fields.
- F6. There is no visible back button or discoverable back key from the editor to the prompt list.
- F7. There is no visible settings entry point (no cog or button). The operator could not find where settings live.

Screenshots of the picker were shared in the operator session (not attachable here).

## Location
Project `Tamdoma/varhop`, plugin `ivan.varhop`, files `Varhop.qml`, `qml/SettingsBody.qml`, `qml/EditorBody.qml`, `qml/SearchBody.qml` on branch `overlay-plugin` (`0df6f48`). Leaf: `issues/open/varhop/overlay-plugin`, currently `failed` at `check.fix` awaiting operator checks OA1–OA4.

## Reproduction
1. `omarchy plugin add file:///home/ivan/.akrogon/worktrees/varhop/overlay-plugin --enable --yes`
2. Super+Alt+P (or `omarchy-shell shell summon ivan.varhop`). Picker opens. Type any text: list does not narrow.
3. Type `Tamdoma/varhop-prompts`, Enter, open a prompt with variables: variables appear as stacked fields.
4. Look for a back control or a settings control: none visible.
Frequency: every time.

## Expected behavior
- Picker narrows as the operator types.
- Font family, sizes, colors and transparency follow the active Omarchy theme and font settings.
- Variables stay inline in the prompt text and are edited in place, so the prompt keeps its shape.
- A visible way back from the editor to the prompt list.
- A visible way into settings.

## Urgency
Blocks the leaf from meeting its destination ("a themed overlay ... replaces Notion for prompts", `brief.md:12`). Live operator checks OA2/OA3 test the current editor and would be invalidated by an editor redesign. Workaround: type the full `owner/repo` and Enter in the picker. The keys Ctrl+P (editor → search) and Ctrl+, (toggle settings) exist but are only documented in `README.md`.

## Suspected cause
- F5: the design left the editor mechanism open (`design.md:34` "Editor mechanism left to leaf design"). The brief fixes only behavior: Tab walks unique names, values mirror to every occurrence (`brief.md:45`). The implementation renders a `Column`/`Repeater` of `TextArea` stops with read-only mirrors (`qml/EditorBody.qml:8`, `:250-297`). The inline requirement was never written down.
- F1: the picker is a plain `Repeater` over `root.repos` with no filter on the field text (`qml/SettingsBody.qml:218-234`). The design calls only for a `/user/repos` list plus a validated typed `owner/repo` (`design.md:95`, `brief.md:25`).
- F2: every text uses a hard-coded `font.pixelSize` of 11–14 and sets no `font.family` (`qml/SettingsBody.qml:122`, `:198`, `:230` and more). Omarchy exposes `Commons.Style.font` size tokens and `menuFamily` (`/usr/share/omarchy/shell/Commons/Style.qml:323-335`). The plugin does not reference `Commons.Style`.
- F3: views read colors through `c(name, fallback)` with hex fallbacks (`qml/SettingsBody.qml:35-41`), fed from `Commons.Color` in `Varhop.qml:62-70`. Whether the fallbacks are what renders was not verified.
- F4: the panel fills with `Commons.Color.menu.background` (`Varhop.qml:775`). Whether that token carries the theme's alpha was not verified.
- F6/F7: back and settings exist only as keys (`qml/EditorBody.qml:222-229` Esc hides, Ctrl+P finds another; README Ctrl+,). No visible control was specified in `design.md`.
Whose view: reporter observations, agent cause reading.
Files read: `issues/open/varhop/overlay-plugin/{brief.md,design.md}`, worktree `qml/SettingsBody.qml`, `qml/EditorBody.qml`, `qml/SearchBody.qml` (grep), `Varhop.qml` (grep), `README.md`, installed `/usr/share/omarchy/shell/Commons/Style.qml` (installed Omarchy copy, not this repo's source).
Not inspected: how other Omarchy overlays obtain transparency, the actual rendered color values, `SearchBody.qml` styling in full.
Related reports: none found (Tamdoma/varhop, `--author @me` since 2026-10-11 and "overlay editor theme", states all, limits 30/10).

## Source: operator chart-issues args 2026-10-13
Look at the pooled issues, we need to resolve all of them. Consult with slot B and C which are already  active in this herder tab.

## Source: operator mid-turn note 2026-10-13
We also need to decide what to do with the overlay plugin, which has failed as a leaf. I think it needs to be removed.

## Agent findings
- Failed leaf state: issues/open/varhop/overlay-plugin/state.yaml (phase failed, cause blocked at check.fix, fix_rounds 4, reason OA1-OA4). Final B re-check: no product defect open, check 77 pass (review-B.md). Branch overlay-plugin 0df6f48 is 33 commits ahead of main, holding the whole plugin plus latency edits in lib/search.mjs and lib/import.mjs (slots/map-C.md section 1).
- Opening maps: slots/map-A.md, slots/map-B.md, slots/map-C.md. Merged: slots/map-merged.md.
