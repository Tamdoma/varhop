# sync-and-auth: merged notes (A)

Sources: slots/sync-and-auth-A.md, -B.md, -C.md (2026-10-12).

## Agreed
- Q1 Reuse the stored `gh` login; varhop stores no credential (A,B,C). Git runs with a command-scoped helper `-c credential.helper= -c 'credential.helper=!gh auth git-credential'`, never global `gh auth setup-git` (B,C). Prompts disabled (`GIT_TERMINAL_PROMPT=0`, `GH_PROMPT_DISABLED=1`) and a timeout per process (B,C). No `gh auth token` extraction (B). Missing login shows `gh auth login` as the fix (A,B,C). gh ships with every Omarchy install via mise (C: install/user/mise.sh:9; A's "not an Omarchy package" was wrong).
- Q2 Git cache, not API snapshot; B revised its map position (A,B,C). Shallow, single source, never inside the plugin dir (A,B,C). Refresh only replaces data after a successful fetch, so failure keeps the previous library (A,B,C). Overlay reads one prebuilt index, written temp+rename (A,B).
- Q3 Show cached library instantly, refresh on summon behind a cooldown, manual refresh, no timer while hidden (A,B,C). Footer states: refreshing / updated N ago / refresh failed with reason / offline only when a network failure says so (B,C). The open draft is separate from the library and never changed by a refresh (B,C).
- Q4 One github.com repo (A,B,C). List via `/user/repos` with default affiliation (owned, collaborator, org) and pagination, plus typed `owner/repo` validated before use (B,C; A's `gh repo list` misses org repos). Selection saved via scoped `shell.updateEntryInline` into shell.json, full object each write (B,C).

## Disagreements
- D-a Copy form. A,C: shallow working clone, `fetch --depth 1 origin HEAD` then `reset --hard FETCH_HEAD`, read files from disk (mirrors omarchy-plugin-update:43-48). B: bare shallow clone, read blobs with `git ls-tree -r -z` + `git cat-file blob`, no checkout (avoids line-ending/smudge transforms, symlinks never followed).
- D-b Location. A,B: `~/.cache/varhop/...` (disposable remote data, rebuilt on next refresh). C: `~/.local/state/omarchy/varhop/` (only offline source; cleanup tools wipe ~/.cache). B keys the path by account id + repo id.
- D-c Cooldown. A,C: 10 min. B: 5 min, and a failed attempt also starts the cooldown.
- D-d Account binding. B: tie cache and pending work to account id; an account change invalidates and asks to reconfirm the repo. A,C: not addressed.

## Operator-level questions raised
- Repo switching: B keeps the old source until the new one imports; C deletes and re-clones. Both fine for one repo.
- Empty new repo selectable with a "No prompts yet" state (B Q2b), local-directory source for testing (C Q8), several repos later (C Q7).
