# Settings and hotkey: rebuttal C (disagreements only, 2026-10-13)

RC1. D-c: hold B,C. Esc in settings returns to the invoking view; Esc in a first-run settings hides. Settings is a view opened over preserved search/editor state, not a third workflow stage. Copy-and-close locked Esc for editor and search, not this then-nonexistent view. Closing a popup back to its underlying surface is also the local pattern (Ui/Dropdown.qml:179). A's hide-everywhere rule would make checking sync status from the editor cost a full re-summon and resume cycle.

RC2. D-d: hold B,C, read as every stage, not every widget. Ctrl+R in the editor is safe by the sync lock (a pull never changes the open draft) and is exactly where staleness is noticed. Inside picker text fields it stays inert (C P7); the picker's own list refresh is a different action and must not be silently aliased to a library pull.

RC3. D-e: concede A,B. Reset usage clears only the currently selected repo's namespace. The store was repo-scoped to stop one repo's data affecting another (search Taken); a reset in repo settings should honor the same boundary instead of erasing unseen repos. Label it "Reset usage for this repository" and the separate whole-file wipe disappears.

RC4. Wrong mechanism in Agreed, conflict check: merged tags C for `hyprctl binds -j`; C proposed plain `hyprctl binds`. Do not lock the JSON form into the contract. Omarchy's own keybindings listing deliberately parses the plain output because Hyprland 0.56.0 emits invalid JSON for binds in some cases and older versions broke on quoted args (omarchy-menu-keybindings:300-303). Either parser is a leaf detail; the agreed line should say "query live binds", not name `-j`.

RC5. Dropped point (B Q1): the settings chord field must not interpolate free text into a Lua line. Restrict it to a validated modifier-plus-key vocabulary before rendering `o.bind("...")`; a pasted quote or newline from an unconstrained field goes straight into the user's executable Hyprland config. My C notes said "editable text field" without that constraint, so this corrects C as well as the merge.

RC6. N4: oppose B's preserve-across-repo-change. A manual pull preserving the draft's original template is settled (same repo identity). Replacing the repo is a different act: keeping the draft then needs repo-qualified draft identity so the Draft marker, pinned Resume, and the usage increment on copy do not silently attach to a same-path prompt in the new repo. Simpler contract: if a draft exists, choosing a different repo warns that a successful switch discards it (a failed or cancelled import leaves it untouched, per sync's prepare-then-commit). One repo identity at a time across library, draft, markers, and usage.

RC7. N5: agree B. Find another prompt returns to the previous query and selection in the same session; query edits after that still reset selection to the top per search Taken. It is a return to the list the user came from, not a fresh search.
