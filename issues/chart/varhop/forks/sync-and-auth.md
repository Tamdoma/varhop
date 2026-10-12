# Sync and auth

## Question
Q1. How does varhop authenticate to GitHub (reuse the existing `gh` login, its own token, or a device-flow login), and where does any credential live?
Q2. How does it get and keep a local copy of the prompt repo (git clone into a cache and pull, or a commit-pinned API snapshot), and where does that copy live?
Q3. When does it refresh (on open, on a timer, manual only), and what does the overlay show while refreshing, offline, or after a failed refresh?
Q4. What does the repo picker in settings list (own repos, orgs, any `owner/repo` typed in, private repos), and is it one repo or several?

### Carries
- form-factor taken: Omarchy shell overlay plugin in QML/JS; external work runs through Quickshell `Process` (forks/form-factor.md).
- repo-format taken: prompts under `prompts/<category>/[<subcategory>/]<name>.md`, README outside `prompts/` ignored, lenient load with visible per-file errors (forks/repo-format.md).
- Operator: "settings ... connect GitHub and choose a repo" with the standard structure (INTAKE.md).
- Merged map slots/map-merged.md D2 open: A,C clone with git/gh into a cache and pull in background; B commit-pinned API snapshot, atomic publish, no git state.
- Live surface (A, 2026-10-12): `gh` 2.102.0 logged in as ivanjuras via keyring, scopes gist, read:org, repo, workflow; git 2.56.0.

## Findings
Independent notes: slots/sync-and-auth-A.md, -B.md, -C.md. Merged: slots/sync-and-auth-merged.md. Rebuttals: slots/sync-and-auth-rebuttal-B.md, -C.md.
- Settled by all slots: reuse the stored `gh` login, no stored credential, command-scoped git helper `!gh auth git-credential` (C probed private clone fails without it, works with it), prompts disabled and a timeout per process, `gh auth login` shown as the fix. gh ships with every Omarchy install (install/user/mise.sh:9). Git cache, not API snapshot (B revised). Cached library shows instantly, refresh on summon behind a cooldown, manual refresh, no hidden timer. Open draft never changed by a refresh. One github.com repo, picker from `/user/repos` (owned, collaborator, org) plus typed `owner/repo`, saved via `shell.updateEntryInline` (PluginShellApi.qml:62-64).
- Location: B,C (after rebuttal) `~/.cache/varhop/`; missing cache is the "cloning" state, not an error. Omarchy wipes nothing broad under ~/.cache (C: only migrations/1790528634.sh:28).
- Copy form: A,C working shallow clone + `fetch --depth 1 origin HEAD` + `reset --hard FETCH_HEAD`, enumerate with `git ls-tree -r -z` regular files only (from B). B holds bare clone + `cat-file` for byte fidelity; C measured checkout byte-identical with no `.gitattributes` and notes bare reads need a per-file Process or a `cat-file --batch` parser.
- Cooldown: A 10 min, B conceded 10, C conceded 5. B,C: failed attempts start the cooldown; manual refresh bypasses it except GitHub rate-limit holds.
- Publish only after fetch, reset, read and index all succeed; else keep the previous library (B M2).
- Repo switch: B prepare new source separately and retire the old after success; C delete then re-clone.
- Account change: C store the gh login name with the selection, reconfirm repo when it differs; B also keys cache by account and repo id and scrubs GH_TOKEN/GITHUB_TOKEN/GH_HOST/GH_REPO from the process env.
- Off route for v1 (B M4): local-directory source, several repos.
- C2 review (pi, slots/review-C2.md S1-S4): 1a only with (i) checkout transforms neutralized via `$GIT_DIR/info/attributes` on `prompts/**` with a CRLF-attributes fixture proof, and (ii) two clone slots, refresh the inactive one and switch after a successful index, so a failed refresh never leaves a half-updated tree on disk. 2b 5 min (git fetch is not REST quota); last-attempt time stored outside shell.json. 3a via the same two-slot swap, settings write last, generation number per async completion. 4a plus numeric account and repo ids in settings, and `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO` argv prefix (Process.environment cannot unset).
- C2 gaps owned here: empty repo (no commits) and repo without `prompts/` are named states; typed `owner/repo` validated to a strict pattern before any URL, path or argv; size warning from API repo size; per-operation timeouts via Timer + kill (clone longer than fetch). Volatile state (cooldown, usage) in a state-dir file, never shell.json (shell.qml:129,142 watchChanges).

## Taken

2026-10-12 operator: `1a | 2 - manual pull, no automatic | 3a | 4a`
- Q1 1a: shallow working clone under `~/.cache/varhop/`, read from disk, with C2's two amendments: `$GIT_DIR/info/attributes` neutralizes checkout transforms on `prompts/**` (proof: CRLF-attributes fixture reads byte-identical to blobs), and two clone slots, refresh the inactive one and switch only after fetch, checkout, read and index succeed (foreclosed: bare clone + cat-file).
- Q2 operator choice, not an offered option: no automatic refresh at all. The first clone runs when a repo is chosen; afterwards the library changes only on a manual pull (Ctrl+R in the overlay, "Sync now" in settings). The footer shows when the copy was last updated. Foreclosed: refresh on summon, cooldowns, timers. The cooldown-timestamp state item is moot.
- Q3 3a: the old library stays until the new repo imports; selection is saved last; a generation number tags every async completion (foreclosed: delete then clone).
- Q4 4a: the gh login name plus numeric account id and repo id are stored with the selection; a mismatch asks to reconfirm the repo through the Q3 path; processes run under `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO` (foreclosed: cache keyed per account/repo id).
- Also binding from Findings: reuse the stored `gh` login with the command-scoped helper, no stored credential, prompts disabled, per-operation timeouts; `/user/repos` picker plus a strictly validated typed `owner/repo`; selection in shell.json via `updateEntryInline` (full object), volatile state elsewhere; empty repo and missing `prompts/` are named states.
