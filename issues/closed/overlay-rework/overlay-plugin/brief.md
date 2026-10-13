# Brief: overlay-plugin

## What
Land the existing `ivan.varhop` Omarchy overlay plugin on main, with its behavior unchanged. This leaf adopts the existing branch and worktree `overlay-plugin` at 0df6f48 (33 commits ahead of main, worktree clean). Its first step checks that HEAD is 0df6f48 and the tree is clean.

It also adds one piece of reusable live-proof machinery inside the plugin repo: a uinput keyboard helper. The helper creates a virtual keyboard, sends a named key sequence to the focused surface, reads back an observable result, reports pass or fail, and cleans up on both outcomes (device closed, clipboard and primary selection restored byte-equal).

The leaf makes only the smallest repair needed for its checks to pass on untouched code, and records each repair with its reason. None of the seed's asks (F1-F7: picker filtering, look, inline editor, Back and Settings controls) belong here. They belong to `overlay-rework`.

## Why
The plugin exists only on an unmerged branch. Main has no manifest, QML or views, so the rework cannot branch from main until this code lands. The rework's live criteria type into the overlay, and main has no reusable keyboard driver for that. The failed leaf's proofs were one-off commands that nobody could rerun.

## Done-criteria
1. The blocking `test` check passes at the final commit.
2. The implementation report has a criterion-to-evidence table. It lists every done-criterion of the archived brief (issues/chart/overlay-rework/archive/overlay-plugin/brief.md) with its evidence at 0df6f48 (archive implementation/report.md "Done-criterion evidence") or at this leaf's final commit. Rows for 5f (exact resume), 6b (Super+C/V over browser and terminal), 7c success (repo switch with draft) and the reset-button click are marked "owned by overlay-rework". Any row whose evidence a repair in this leaf invalidated is re-proven at the final commit.
3. Live install and summon at the final commit (live). `omarchy-plugin-validate` passes on the repo root. The installed copy at ~/.config/omarchy/plugins/ivan.varhop is moved to this leaf's final commit in place (origin set to this leaf's worktree, fetch, hard reset, `omarchy-restart-shell`). `omarchy-shell shell summon ivan.varhop` shows the overlay, the shell log shows no QML errors for the plugin, and the `ivan.varhop` entry in ~/.config/omarchy/shell.json is byte-identical before and after.
4. The uinput helper passes a known-good case (live). With the overlay summoned on search, it sends a key sequence that types a marker, moves the caret, selects with Shift+Left and replaces the selection, and the read-back field text equals the expected string.
5. The helper fails a deliberate break (live). With the overlay summoned and focused on search, the same sequence is sent with one marker key deliberately not delivered and the expected string unchanged. The helper reports fail with the expected and observed text. After both runs no virtual device remains, and the clipboard and primary bytes equal their saved copies. (B,C)
6. Final live state: the plugin is installed and enabled at this leaf's final commit. As the last live step, the installed clone's origin is set to `file:///home/ivan/Work/omarchy-customizations/varhop`, with no fetch or reset after that change in this leaf. The door moves it to merged main after the merge (CHART.md Pending steps) (B,C). Also, and the shell.json `ivan.varhop` entry (repo, login, accountId, repoId) is unchanged. Existing ~/.cache/varhop and ~/.local/state/varhop are left byte-identical, or restored byte-identical from the leaf's own backup when a check had to write there.

Live runs share one resource, the operator's omarchy-shell session with its keyboard focus and clipboard, so they run one after another.
