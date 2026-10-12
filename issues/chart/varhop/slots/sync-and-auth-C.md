# Sync and auth: blind notes, slot C (2026-10-12)

Tiers: [OP] operator, [SRC] inspected file or live probe on this machine, [DOC] URL read 2026-10-12, [MK] own knowledge.

## Facts inspected

- gh 2.102.0 at ~/.local/bin/gh is a mise wrapper (mise has 2.100.0, 2.101.0, 2.102.0 installed). Omarchy installs gh for every user: /usr/share/omarchy/install/user/mise.sh:9 `omarchy-mise-install gh`. No pacman package owns it. [SRC]
- `gh auth status`: logged in as ivanjuras via keyring, git protocol https, scopes gist, read:org, repo, workflow. `gh api user/orgs` lists 3 orgs (Tamdoma, MDConsultingNY, Gospodnja-Obnova). `gh api rate_limit` core 5000/5000. [SRC probe]
- omarchy-shell process environment (/proc/<pid>/environ): PATH contains /usr/share/omarchy/bin, ~/.local/share/mise/shims, ~/.local/bin; XDG_STATE_HOME, XDG_CACHE_HOME set. So a Quickshell `Process` finds `gh` and `git` by name. [SRC]
- ~/.gitconfig has `credential.https://github.com.helper=!/home/ivan/.local/share/mise/installs/gh/2.100.0/.../gh auth git-credential` (written by `gh auth setup-git`, absolute path of a now superseded version; still works only because mise.sh:1-3 sets `upgrade.auto_prune false`). No system gitconfig. [SRC]
- Scratch probe, private repo ivanjuras/kybern (3.1 MB), `GIT_TERMINAL_PROMPT=0`: `git -c credential.helper= clone https://...` fails `could not read Username`; `gh repo clone X -- --depth 1` 1.7 s; `git -c credential.helper= -c 'credential.helper=!gh auth git-credential' fetch --depth 1` 0.9 s; `git ls-remote origin HEAD` 0.75 s; `gh repo sync` 1.2 s; `gh api -i repos/X/branches/main -H "If-None-Match: <etag>"` returns 304. Scratch deleted. [SRC probe]
- Omarchy never calls `gh`; all network git lives in bin scripts, none in shell QML (Explore pass over /usr/share/omarchy/shell and bin). [SRC]
- /usr/share/omarchy/bin/omarchy-plugin-add:11-12 `GIT_TERMINAL_PROMPT=0`, `GIT_SSH_COMMAND=ssh -oBatchMode=yes`; :120 `git clone`. omarchy-plugin-update:43 `git -C dir fetch --quiet origin HEAD`, :48 compares `rev-parse HEAD` to `FETCH_HEAD`, :67 `merge --ff-only`, :73 `reset --hard ORIG_HEAD` on failed validation. omarchy-update-available:9-14 `GIT_TERMINAL_PROMPT=0 timeout 10 git fetch`. omarchy-theme-install:56 clones into ~/.config/omarchy/themes/<name>; omarchy-theme-update:5-9 `git pull` per theme. [SRC]
- /usr/share/omarchy/shell/services/PluginRegistry.qml:663-687 `inotifywait -m -r` on ~/.config/omarchy/plugins reloads a plugin on any close_write/create/delete/move under its dir; :736 ignores only `.git` paths. [SRC]
- services/PluginShellApi.qml:1-70 scoped shell for third-party plugins: `summon`, `hide`, `toggle`, `isPluginOpen`, `updateEntryInline(id, settings)`, `mutateShellConfig`. shell.qml:1099-1130 `updateEntryInline` writes `{id, ...settings}` into `plugins[]` of ~/.config/omarchy/shell.json (atomicWrites, shell.qml:36-37). Operator's shell.json already holds `plugins: [{id: "ivan.notifications"}]`. [SRC]
- First-party state files: ~/.local/state/omarchy/clipboard-history.json (plugins/clipboard/Clipboard.qml:21,251-258), ~/.local/state/omarchy/settings/weather.json via FileView watchChanges (plugins/panels/weather/Panel.qml:98-104), ~/.cache/omarchy/agents-disabled.json (plugins/agents/Main.qml:377). [SRC]
- Quickshell 0.3.2-4: `Process` has `command`, `workingDirectory`, `environment`, `running`, `stdout`, `stderr`, `exited(exitCode, exitStatus)` (/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes:56-141); `StdioCollector`, `SplitParser` (:285-328); `Quickshell.cacheDir/stateDir/dataDir/env` (quickshell-core.qmltypes:1007-1055). Example with exit code: plugins/bar/widgets/SystemUpdate.qml:39-49. [SRC]
- gh manual: `gh auth token` prints active account token; `gh auth setup-git` installs gh as git credential helper; `gh repo list [owner] --json --limit --visibility`; `gh repo clone X -- <gitflags>` honors `git_protocol`; `gh api --paginate --jq --cache -H -i`; env `GH_TOKEN`, `GH_PROMPT_DISABLED`, `GH_NO_UPDATE_NOTIFIER`, `NO_COLOR` (https://cli.github.com/manual/gh_auth_token, gh_auth_setup-git, gh_repo_list, gh_repo_clone, gh_api, gh_help_environment). [DOC]
- GitHub REST: 5000 req/h authenticated; 304 on `If-None-Match` is free; `/user/repos` default affiliation owner,collaborator,organization_member, per_page max 100; contents API 1000 files per dir, 1 MB full features; trees recursive cap 100k entries / 7 MB; tarball is a 302; device flow needs an OAuth app with device flow enabled, user types a code at github.com/login/device, poll interval ~5 s (https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api, .../rest/repos/contents, .../rest/git/trees, .../rest/repos/repos, .../apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps). [DOC]
- Comparable tools: chezmoi keeps a clone at ~/.local/share/chezmoi, `chezmoi update` = git pull then apply (chezmoi.io/reference/commands/update). Oh My Zsh checks on shell open with a day frequency, `git pull --rebase` (github.com/ohmyzsh/ohmyzsh README, tools/upgrade.sh). Homebrew auto-updates at most every 24 h, `HOMEBREW_NO_AUTO_UPDATE` (docs.brew.sh/Manpage). tlrc caches pages, `auto_update`, `max_age` 2 weeks (github.com/tldr-pages/tlrc README). Raycast store extensions update in background with a manual check (manual.raycast.com/extensions). VS Code Settings Sync is a cloud service and pauses on conflict (code.visualstudio.com/docs/configure/settings-sync). [DOC]

## Q1 Authentication and credential location

Pick: reuse the user's `gh` login. varhop stores no credential. Every git network call runs as `git -c credential.helper= -c 'credential.helper=!gh auth git-credential' ...`, and every listing call is `gh api` or `gh repo list --json`. If `gh auth status` exits non-zero, settings shows gh's stderr and the line `run: gh auth login` for the user to do in a terminal.
Reason: gh is an Omarchy default tool (mise.sh:9), already logged in here with the `repo` scope, reachable from the shell PATH, and holds the token in the keyring. The inline helper means varhop does not depend on the user having run `gh auth setup-git` (proved: without a helper the private clone fails; with the inline helper it works). Omarchy's own tooling already runs git subprocesses with prompts disabled (omarchy-plugin-add:11-12), so this is the ecosystem idiom.
Cost: hard dependency on gh being installed and logged in; users with a fine-grained token exported only as `GH_TOKEN` in their terminal are not covered, since the shell process does not carry that variable; private repos need the classic `repo` scope or a fine-grained token with Contents read.

Rejected:
- Own OAuth device flow with token in keyring. Needs an OAuth app registration owned by someone, device flow enabled, a polling loop in QML, and a keyring write from QML through yet another subprocess (secret-tool). It duplicates what gh already does on every Omarchy install.
- Pasted personal access token in settings. The only settings store the scoped shell offers is plain JSON in shell.json; a state file is also plain text. That stores a secret worse than the keyring gh already uses.
- SSH deploy key or any git URL. No repo picker, manual key management, and the operator asked for "connect GitHub and choose a repo" [OP].

Pitfalls:
- A hardcoded gh path rots. The operator's own ~/.gitconfig points at gh 2.100.0 inside mise's install dir; it survives only because auto_prune is off. Remove: resolve `gh` by name through PATH, never by path.
- Any interactive prompt (username, ssh host key, gh login) hangs the Process forever. Remove: Process `environment` sets `GIT_TERMINAL_PROMPT=0`, `GIT_SSH_COMMAND=ssh -oBatchMode=yes`, `GH_PROMPT_DISABLED=1`, `GH_NO_UPDATE_NOTIFIER=1`, `NO_COLOR=1`, and wrap with `timeout 20` like omarchy-update-available:9.
- Wrong or missing scope gives a cryptic 404 on private repos. Remove: on clone or fetch failure, show gh/git stderr verbatim in the settings view, and show `gh auth status` output (scopes line) in settings.

## Q2 Local copy

Pick: shallow git clone of the chosen repo into `~/.local/state/omarchy/varhop/repo/` (one directory, replaced when the repo choice changes). Refresh = `git -C dir fetch --depth 1 origin HEAD`, then if `rev-parse HEAD` differs from `rev-parse FETCH_HEAD`, `git reset --hard FETCH_HEAD`, then re-index. The clone is the offline cache; the working tree is read-only from varhop's point of view.
Reason: mirrors omarchy-plugin-update:43-48 and omarchy-theme-update step for step, so there is one network mechanism in the whole ecosystem. One subprocess per refresh instead of one API call per file. `fetch origin HEAD` tracks the remote default branch without storing a branch name, so a main/master rename does not break anything. Reset only runs after a successful fetch, so a failed refresh leaves the previous tree untouched. Measured: 1.7 s first clone, 0.9 s fetch for a 3 MB repo.
State dir, not cache dir: the clone is the only offline source of prompts, and `~/.cache` is routinely wiped by cleanup tools. First-party precedent for user data the shell must keep is ~/.local/state/omarchy (clipboard history, weather settings). Not inside the plugin dir: PluginRegistry.qml:663-687 reloads the plugin on any file change under it, and omarchy-plugin-update:67-69 refuses to fast-forward a dirty plugin checkout.
Cost: `git` (pacman, 2.56.0) and `gh` are hard runtime dependencies; a shallow clone cannot show history or diffs (not needed); disk is the repo size.

Rejected:
- Commit-pinned API snapshot (merged map D2, B). Needs tree + N contents calls or tarball + redirect + `tar` extraction + atomic directory swap, all orchestrated from QML with no gain over one `git fetch`. The 1000-files-per-directory and 1 MB contents caps are extra failure modes git does not have. "No git state" is not a benefit: the shell host already tolerates a `.git` directory in every installed plugin.
- Full clone. History is unused; `--depth 1` is free to add.
- `gh repo sync`. Works (1.2 s) but fails on any local change and needs cwd in the repo; the explicit fetch + reset is the same two steps with a defined failure path.

Pitfalls:
- Two refreshes at once (open twice fast, or manual key during auto refresh) collide on git's index.lock. Remove: one `refreshing` boolean in the plugin; triggers while true are ignored.
- Repo choice changes while a fetch runs. Remove: cancel the Process (`running = false`), delete the directory, clone fresh.
- Picked repo has no `prompts/` directory. Remove: after clone, show one error row "no prompts/ folder in <repo>" per repo-format's lenient-load rule.
- `reset --hard` while the user is editing a prompt. Remove: the open draft lives in memory as template + values (merged map line 9); a refresh only replaces the search index.

## Q3 Refresh timing and display

Pick: refresh on overlay open when the last successful fetch is older than 10 minutes, plus a manual refresh key (Ctrl+R) always allowed. No timer while hidden. The cached index shows instantly; the fetch runs behind it. A one-line footer status: "updated 3 min ago", "refreshing", "offline, showing copy from <date>" (fetch failed with a network error), or "refresh failed: <first stderr line>" (any other failure). First run with no clone shows "cloning <owner/repo>" in place of the list; no repo chosen shows "choose a repository in settings".
Reason: prompt repos change only when the user edits them, and a fetch costs under one second, so refresh-on-open with a cooldown gives fresh data at the second open without a background network loop. This is the Oh My Zsh / Homebrew / tlrc pattern (check at use with a cooldown), not the VS Code cloud-sync pattern. Treating fetch failure as the only offline signal avoids a separate connectivity check.
Cost: a prompt edited and pushed less than 10 minutes after the previous open needs Ctrl+R.

Rejected:
- Periodic Timer while hidden. Network and wakeups on a laptop for a repo that changes rarely; the plugin is keepLoaded, so the timer would run all day.
- Manual only. Stale by default, the user forgets.
- Refresh on every open without cooldown. A fetch per hotkey press; Oh My Zsh marks its equivalent "not recommended".

Pitfalls:
- Fetch outlives the overlay (user opens, hides within a second). Remove: let the Process finish; reindex on exit regardless of visibility, since the plugin is resident.
- stdout parsing of git. Remove: only exit code and `rev-parse` output are read; never parse progress text.

## Q4 Repo picker

Pick: one repo in v1. The picker lists `gh api user/repos?per_page=100&sort=updated --paginate --jq '.[] | {nameWithOwner: .full_name, private: .private}'`, which with the default affiliation covers owned, collaborator and organization repos in one call, plus a text field that accepts `owner/repo` or a GitHub URL for anything not listed, validated with `gh repo view <x> --json nameWithOwner`. Private repos are listed and cloneable (scope `repo`). The chosen `nameWithOwner` is written with `shell.updateEntryInline("ivan.varhop", {repo: "..."})` into shell.json's `plugins[]` entry.
Reason: the operator says "choose the repository" (singular) and "I'll create a new repo from scratch" [OP]; several repos would need id disambiguation (id = path) and category merging with no stated need. `user/repos` beats `gh repo list` per owner because it already includes the three orgs this account belongs to. updateEntryInline is the shell's own settings path for third-party plugins (PluginShellApi.qml:62-64), atomic, and survives plugin updates since it is outside the plugin dir.
Cost: accounts with hundreds of repos page through several 100-item calls (within 5000/h); the picker needs a filter box; settings live in shell.json, so a shell.json reset loses the choice.

Rejected:
- Several repos. Defer until the operator asks; recorded as Q7 below.
- Own settings file under ~/.local/state/omarchy/settings/varhop.json (weather precedent). Works, but it is a second settings store next to the one the scoped shell already provides for plugins.
- `gh repo list` only. Misses org and collaborator repos unless called per org.

Pitfalls:
- Repo renamed or transferred. Remove: GitHub redirects old names for git; on 404 show the error and reopen the picker.
- shell.json `plugins[]` entry replaced wholesale by updateEntryInline (shell.qml:1125-1129). Remove: always write the full settings object, never a partial one.

## Questions the fork does not ask

Q5 Is "run `gh auth login` in a terminal" acceptable as the only sign-in step, given gh ships with Omarchy and the operator is already logged in?
Q6 Should the cache be editable (user edits a prompt in the overlay, varhop commits and pushes)? My pick is no for v1; the clone is read-only and reset on every refresh.
Q7 One repo now; is a second repo (for example an org-shared library plus a personal one) expected within the year? That changes id = path to id = repo + path now.
Q8 Should varhop accept a local directory instead of a GitHub repo (`repo: /path`)? It costs nothing with the git design (skip fetch) and gives a no-network dev and test path.
Q9 Expected repo size: hundreds of files, or thousands? Shallow clone covers both, but indexing on every refresh is in QML/JS and should be measured above ~2000 files.
