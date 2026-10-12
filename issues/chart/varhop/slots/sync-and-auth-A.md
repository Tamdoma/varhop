# sync-and-auth: blind notes (slot A)

Read 2026-10-12. Tiers: [OP] operator, [SRC] inspected file or live probe, [MK] own knowledge.

## Q1 Auth
Pick: reuse the `gh` login. varhop runs `gh` and `git` through Quickshell `Process`; git auth comes from gh's credential helper. varhop stores no token. Reason: the operator is already logged in with `repo` scope [SRC `gh auth status`, 2026-10-12]; no secret file, no OAuth app to register. Cost: gh becomes a hard dependency. On this machine gh is a user binary in ~/.local/bin, not an Omarchy package [SRC `pacman -Qo /usr/bin/gh` → no owner; install/ has no github-cli]. Settings must show "gh missing" / "gh not logged in" with the exact fix command.
Rejected:
- Own PAT stored in a plugin file. Reason: plain-text secret under ~/.config, rotation is manual.
- Device-flow login inside the overlay. Reason: needs a registered OAuth app and client id; duplicates what `gh auth login` already does.

## Q2 Local copy
Pick: shallow clone into `~/.cache/varhop/<owner>/<repo>` (`gh repo clone <repo> <dir> -- --depth 1`), refresh with `git fetch --depth 1 origin` + `git reset --hard origin/HEAD`, then rebuild one JSON index. Overlay reads only the index. Reason: git gives atomic switch to a commit, works for private repos via gh, zero REST pagination. Cost: a git working tree on disk; a local edit in the cache is wiped by reset (it is a cache, documented).
Rejected:
- REST tarball/contents snapshot (B's map). Reason: needs untar or one call per file; reimplements what git does. Its gain (no git state) is small for a read-only cache.
- Cloning into the plugin folder. Reason: `omarchy plugin update` owns that folder.

## Q3 Refresh
Pick: on overlay open, show the cached index immediately; start a background refresh if the last sync is older than 10 min; manual "Sync now" in settings. Footer shows "synced 5m ago" or the error. Offline or failed: keep cached list, show the error once, no modal. Reason: open must be instant [OP "instant fuzzy search"]. Cost: a prompt pushed seconds ago may need a second open.
Rejected: timer in the background (wakes git while unused); manual only (stale by default).

## Q4 Repo picker
Pick: one repo in v1. Picker lists `gh repo list` for the user and their orgs (private included), plus a free `owner/repo` field. Reason: intake says "choose a repo"; one id scheme. Cost: switching repos re-clones.
Rejected: several repos merged (id collisions, not requested).

## Evidence
- [SRC] `gh auth status` 2026-10-12: ivanjuras, keyring, scopes gist, read:org, repo, workflow. `gh api rate_limit` core 5000/h.
- [SRC] /usr/share/omarchy/shell/plugins/clipboard/Clipboard.qml:265-284 `Process` blocks; state precedent ~/.local/state/omarchy/clipboard-history.json; plugins/agents/Main.qml:377 uses ~/.cache/omarchy/.
- [SRC] No first-party shell QML calls gh or git (grep, 2026-10-12).

## Pitfalls
- P1 gh absent or logged out: settings check runs `gh auth status`, shows the fix.
- P2 Default branch renamed or force-pushed: `reset --hard origin/HEAD` after `git remote set-head origin -a`.
- P3 Two refreshes at once: one Process at a time, a second request is dropped while running.
- P4 Huge repo: depth 1 and `--filter=blob:none` not needed for md; note only.
- P5 Index written half-way: write temp file, rename.

## Questions the fork does not ask
- Q5 Should the plugin depend on gh at all for other Omarchy users, or fall back to plain git with an https URL for public repos?
