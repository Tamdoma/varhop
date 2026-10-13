# Brief: overlay-rework

## What
Rework the merged `ivan.varhop` overlay so it is pleasant for daily use, as the operator reported in Tamdoma/varhop#1 (F1-F7):
- The settings repo picker filters as you type and is one Tab control with arrow rows (picker fork).
- Fonts, colors and surface follow Omarchy's menu, one font size step up, with live theme bindings (look fork).
- Variables are edited inline in one guarded text box showing the whole prompt (editor fork).
- A fixed header gives visible Back and Settings buttons, reachable by keyboard (controls fork).
- The final-build live criteria that the failed leaf could not prove (proof-bar fork) are owned here.

It consumes from `overlay-plugin` (blocked-by): the plugin code on main and the uinput keyboard helper with its pass/fail read-back. It consumes from prompt-core `lib/tokens.mjs` segments and `lib/rebuild.mjs` copy rebuild, and from repo-sync `bin/varhop-sync` (`repo`, `status`, list) and `library.json`, as pinned in their designs. It reimplements none of them.

## Why
The overlay works but the operator finds it clunky (Tamdoma/varhop#1): the picker does not filter, the look does not match Omarchy, `{{NAME}}` values are edited in a separate box, and Back and Settings are invisible. The failed leaf also left four operator-only proofs (OA1-OA4) that a uinput keyboard can now do.

## Done-criteria
Component checks run in the blocking `test` check. Live checks run in the operator's omarchy-shell on the installed copy moved to this leaf's commit in place (origin set to this worktree, fetch, hard reset, `omarchy-restart-shell`), driven by overlay-plugin's uinput helper. Live runs share one resource, the operator's shell session with its keyboard focus and clipboard, so they run one after another.

1. Picker:
   - Typing in the repo field narrows the list to case- and accent-insensitive substring matches on fullName, in stable A-Z order, never reordered by the query. After each text change the highlight goes to the exact match, else the first match.
   - No highlight shows until typing or an arrow. Enter on an empty field does nothing.
   - With zero matches a line says Enter looks up owner/repo. Enter runs the existing repoRe and `varhop-sync repo` path, and the result applies only if the field text is unchanged when it returns.
   - The picker is one Tab stop. Up and Down wrap over rows and Enter takes the highlight. The list shows about 8 rows, with loading, could-not-list and no-match lines taken from the list process exit. The highlight follows the repo ID across a refresh, and the selected repo shows a "current" marker. Esc clears the filter first.
2. Look:
   - Text uses the Omarchy menu font family (menuFamily). Query, headings and editor body are heading size, titles and controls title size, metadata body size, with row and field heights derived from those tokens. A component case at a larger base size shows no clipping.
   - The card uses the Emojis surface recipe: BorderSurface with `menu.background`, `Border.surfaceSpec("menu","border",...)`, `Style.cornerRadius`, `menu.scrim`, `menu.text`, `menu.selected*`, `Style.spacing`, and a `Style.space(560)` by `Style.space(480)` card clamped by gapsOut. Muted, accent and urgent stay foundational colors.
   - Colors and fonts are bound live with no snapshot object. A component case with a contrasting test palette (menu.text differs from foreground) shows each open view adopting the new roles after the change. The card follows `menu.background` including its alpha, with no alpha code of its own.
3. Editor:
   - The prompt shows as one PlainText text box with values inline. Only the active value accepts typing, Backspace, Delete, paste and IME commit, and prose never changes. Mirrors of a value update together.
   - An unset value shows `{{NAME}}` wholly selected when active. Filled values keep a faint highlight, and adjacent values do not visually merge.
   - A click on any occurrence edits that occurrence in place and makes its name active. Tab and Shift+Tab walk unique names with wrap.
   - Copy still rebuilds from segments. Per-name undo and redo work across Tab, Delete empties then unsets, and undo of that reset works. Native text undo is unreachable. Middle-click paste onto prose is rejected. Rejected edits do not copy or cut, and the clipboard changes only on an explicit copy or paste action. (C)
4. Controls:
   - A fixed header row at the top of every view, outside the view loaders. Search shows the "Prompts" title and a Settings button. Editor shows Back, the prompt title (plain text, elided first) and Settings. Settings shows Back, or Close when the existing backRequested branch would hide, the "Settings" title, and an empty right side.
   - Buttons are worded with the shortcut printed in muted text ("Back  Ctrl+P", "Settings  Ctrl+,"). A click, Enter on the focused button and the shortcut give the same resulting state (view, draft values, cameFrom, query and selection), including the settings-to-editor round trip and the library-mismatch route.
   - Ctrl+Tab moves focus from the body to the header in every view, and plain Tab reaches the header in search and settings. In the header, Tab moves between buttons, Enter, Return and Space press one, and Esc or Ctrl+Tab return focus to the body with caret, selection, active variable and picker highlight unchanged. Nothing gives a header button the initial focus.
   - Esc in the body keeps its current meaning in every view.
5. Every mouse-activated action has a keyboard equivalent through the same action path: picker and search rows through their one composite Tab control, an editor occurrence through Tab to its name, and header and settings controls through Tab where the body allows it or Ctrl+Tab, then Enter. Settings "Reset usage for this repository", activated by Tab and Enter, clears only the current repository's usage entries, and the other prompts repository's usage file stays byte-identical (live). (C)
6. Final-build live criteria (live, uinput helper):
   - OA1: switching from Tamdoma/varhop-prompts to Tamdoma/varhop-prompts-b with a draft open warns, discards the draft only after the import succeeds, and shows the second repo's prompts. The run ends switched back to Tamdoma/varhop-prompts with the shell.json entry restored.
   - OA2: hide then summon resumes the draft with the exact cursor and selection set by the helper. Both selection ends and the active cursor end are observed through a following edit or movement, then export and clipboard compare. (B)
   - OA3: with varhop focused over a browser and over a terminal window, the Super+V and Super+C bind sequences paste into the focused value and copy the rebuilt prompt (`wl-paste` byte compare).
   - Ctrl+Tab reaches the overlay and moves focus to the header.
7. Final live state: installed and enabled at this leaf's final commit, origin set to `file:///home/ivan/Work/omarchy-customizations/varhop` as the last step with no fetch or reset after it (B,C), the shell.json `ivan.varhop` entry unchanged, existing ~/.cache/varhop and ~/.local/state/varhop byte-identical or restored from the leaf's backup.
8. The implementation report ends with the post-merge operator checklist: a physical Super+V paste over a browser and a terminal, a mouse click on a row, a value, Back and Settings, IME preedit inside a value, and middle-click paste.
