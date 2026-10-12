# Sync and auth: blind notes B

Read date: 2026-10-12. These are recommendations, not operator decisions. I read the brief, intake, Question/Carries and decided Taken sections. I did not read another slot's sync-and-auth notes. Research operations were read-only. The only write is this return.

## Context and comparable practice

**F1. Operator tier.** `issues/chart/varhop/INTAKE.md:14`, `:20`, `:32`, `:34` require immediate local search, a lightweight overlay, interrupted editing and a GitHub repo choice. `forks/form-factor.md:20` fixes QML/JS shell-plugin delivery. `forks/repo-format.md:25` and `:28` fix folder depth, optional inline metadata, lenient per-file errors and preservation of arbitrary Markdown bodies. No migration, metadata sidecar or source version manifest is proposed here. The brief's upgraded runtime supersedes the older runtime mentioned in the form-factor carry.

**F2. Practitioner synthesis.** Tom Payne, maintainer of the deployed multi-machine dotfile manager chezmoi, explains why one source avoids ambiguous composition in his [design account](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/) (practitioner tier, read 2026-10-12). Its [update command](https://www.chezmoi.io/reference/commands/update/) pulls a local source before applying it. The Espanso team, which ships a snippet launcher and package manager, documents [local config synchronization](https://espanso.org/docs/sync/) and [external packages](https://espanso.org/docs/packages/external-packages/). Its GitHub/GitLab package downloads use platform APIs, while generic Git sources use clone. Microsoft's team ships [VS Code Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync/), including local backups and conflict handling for bidirectional changes. Those three product documents are better-than-training tier, not independent case studies. They support keeping usable local data separate from remote work, but disagree on transport because their requirements differ. API package installation suits immutable platform-specific packages. Editable multi-machine settings justify merges. Varhop consumes one source and edits only a temporary rendered prompt, so it needs neither merges nor uploads. My synthesis is one local published library, with remote refresh unable to overwrite an active draft. These comparisons do not prove varhop's failure behavior.

**F3. Live surface, better-than-training tier, measured 2026-10-12.** `pacman -Q omarchy-dev quickshell qt6-base` reports `4.0.0.r6912.gdefbf90-1`, `0.3.2-4`, `6.12.0-2`. Git is `2.56.0`. `gh auth status` reports active `ivanjuras`, HTTPS, keyring, scopes `gist`, `read:org`, `repo`, `workflow`. No token was extracted. `rg` found no `gh` reference in `/usr/share/omarchy/shell` or `/usr/share/omarchy/bin`. There is a first-party Git pattern, not evidence of an existing shell GitHub-auth abstraction.

## Q1. Authentication and credential location

### 1. Pick, reason and cost

**D1. Reuse the stored github.com `gh` login.** Let `gh api --hostname github.com` perform API authentication. For HTTPS Git operations, supply the command-scoped helper `-c credential.https://github.com.helper= -c 'credential.https://github.com.helper=!gh auth git-credential'`. Clear `GH_TOKEN`, `GITHUB_TOKEN`, `GH_HOST` and `GH_REPO` overrides for these processes, making the displayed account match the stored-login choice. Set `GIT_TERMINAL_PROMPT=0`. Do not run global `gh auth setup-git`, logout or account switching from varhop.

Settings should show the account returned by `/user` and a Check connection action. When no stored login exists, show the operator command `gh auth login --hostname github.com --web`, then let the operator retry. Varhop stores account/repo identity, never a credential. `gh` owns credential storage. On this machine that is the keyring. Cost: `gh` and its login remain prerequisites, account choice is shared with other CLI usage, and environment-token-only authentication is outside this v1 choice.

### 2. Rejected options

- **O1. An app-owned personal token.** Adds another secret, token entry, storage and expiry path without satisfying a current unmet requirement.
- **O2. An app-owned device flow.** Adds OAuth application registration and credential lifecycle. Browser login through `gh` already supplies this setup capability.
- **O3. Extract `gh auth token` into QML for requests.** Unnecessary token exposure in application memory and potential diagnostics. Reuse authenticated commands instead.
- **O4. Implicit SSH or a global Git-helper change.** SSH key access can differ from the displayed GitHub account. Changing the operator's global Git configuration is unnecessary for a reader.

### 3. Evidence: tier, source and date

Better-than-training, read 2026-10-12: [gh auth login](https://cli.github.com/manual/gh_auth_login) describes system credential storage and its possible plaintext fallback. Therefore do not claim all `gh` installations use a keyring. [gh auth token](https://cli.github.com/manual/gh_auth_token) prints a credential. [gh environment](https://cli.github.com/manual/gh_help_environment) documents token-variable precedence. [gh api](https://cli.github.com/manual/gh_api) authenticates requests. [gh auth setup-git](https://cli.github.com/manual/gh_auth_setup-git) documents the CLI credential-helper integration.

Measured on 2026-10-12: `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO gh api --hostname github.com user --jq .login` returned `ivanjuras`. A private repository from the accessible-repo probe returned a HEAD SHA through `git ls-remote` using the helper above, with those overrides removed and terminal prompts disabled. This establishes private Git read access in the current terminal environment, not in the eventual shell-plugin process. `gh auth git-credential --help` confirms the installed helper protocol command.

### 4. Pitfalls and removal steps

- **R1. API and Git use different credentials.** Use the same stored-login environment and explicit HTTPS host for both. The implementation must repeat the private read probe from the actual Quickshell process.
- **R2. Account changes during refresh.** Associate every operation and published cache with account ID and repo ID. A connection recheck that reports a different account invalidates pending results and requires repo confirmation.
- **R3. Disconnect affects other applications.** Clear varhop's selection and its account-bound local copies. Leave shared `gh` authentication alone.
- **R4. Credentials enter diagnostics.** No token extraction, authorization-header output or HTTP debug logging. Retain operation, status, exit status and sanitized stderr as structured diagnostic fields.

### 5. Questions the fork does not ask

**Q1a. Must varhop authenticate as a different account from the operator's active stored `gh` account?** My default is no. A yes answer changes D1. **Q1b. Is github.com sufficient?** My default is yes. Enterprise-host support is not implied by the intake.

## Q2. Local source and storage

### 1. Pick, reason and cost

**D2. Choose the Git-cache family, refined to a shallow bare clone plus fetch, never pull into a working checkout.** Resolve the selected repo's default branch, clone its HTTPS URL with `--bare --depth=1 --single-branch --no-tags`, and fetch that explicit branch on later refreshes. Resolve the fetched revision once. Enumerate its prompt tree with `git ls-tree -r -z` and read regular-file blobs by object ID with `git cat-file blob`. Reading committed objects avoids checkout line-ending and smudge transformations and eliminates local merge conflicts.

Build the complete candidate library in memory, including the locked visible authoring errors, then atomically save one self-contained `library.json` containing source identity, revision and prompt data. Publish the candidate only after `FileView.saved`. A transport, object-read or save failure leaves the previous published library available and reports the failure. This is the selected offline behavior, not a second transport fallback. Valid deletions take effect on a successful refresh.

Use `${XDG_CACHE_HOME:-~/.cache}/varhop/github.com/<account-id>/<repo-id>/` for `source.git` and `library.json`. Store only the durable connection/selection settings through the plugin's scoped `updateEntryInline` API in `~/.config/omarchy/shell.json`. The cache is disposable remote data. Keep it out of the plugin code checkout at `~/.config/omarchy/plugins/*`. Make the cache directory private to the user. Cost: Git objects plus a derived JSON copy use extra disk, first import reads every relevant blob, and a shallow clone still downloads unrelated current-tree blobs. These costs are acceptable for the operator's new prompt repo, but corpus size is unmeasured.

This revises my opening API preference. Atomic publication does not require API transport, and bare object reads remove the Git working-tree state that motivated that earlier preference.

### 2. Rejected options

- **O5. Clone and ordinary pull in a live checkout.** Introduces mutable source files, possible merge conflicts and checkout transformations into a read-only consumer.
- **O6. Commit-pinned API tarball.** Viable, but needs archive streaming, staging, extraction/path handling and a full archive transfer on changed revisions. The existing Git tools provide consistent object reads without archive extraction. If Git becomes an unacceptable dependency or the corpus makes Git transport inappropriate, this choice deserves reconsideration.
- **O7. Contents API request per prompt.** Increases network operations with library size. Directory listing and size restrictions require additional handling. Reading files from a moving branch can mix revisions unless every call pins the same SHA.
- **O8. Read directly from GitHub for each search/open.** Makes the requested instant access depend on the network.

### 3. Evidence: tier, source and date

Better-than-training, read 2026-10-12: [Git clone](https://git-scm.com/docs/git-clone) specifies bare/no-checkout and shallow single-branch behavior. Bare clones need an explicit later fetch target, rather than assumptions about ordinary remote-tracking refs. [ls-tree](https://git-scm.com/docs/git-ls-tree) exposes object types, modes and NUL-delimited paths. [cat-file](https://git-scm.com/docs/git-cat-file) supports object content reads, with transformations requiring explicit filter options. [GitHub contents and archives](https://docs.github.com/en/rest/repos/contents) documents directory listings capped at 1,000 entries, content-size limitations, archive redirects and private archive links expiring after five minutes. [gh repo clone](https://cli.github.com/manual/gh_repo_clone) follows configured transport for shorthand names and can add a fork's parent as upstream. Explicit Git HTTPS source selection avoids that implicit parent behavior.

Live code inspected 2026-10-12: `/usr/share/omarchy/bin/omarchy-plugin-update:9`, `:43`, `:48`, `:67`, `:72` disables terminal prompts, fetches before comparison, fast-forwards and validates plugin code. Reuse the asynchronous fetch/check idea, not its code-update merge/rollback procedure. `/usr/share/omarchy/shell/services/PluginShellApi.qml:62` and `/usr/share/omarchy/shell/shell.qml:665`, `:1099`, `:1136` expose scoped settings persistence. Pass the complete proposed plugin settings object because this API replaces the entry's settings. `/usr/share/omarchy/shell/shell.qml:139` uses atomic FileView configuration writes. `/usr/share/omarchy/shell/plugins/notifications/Service.qml:22`, `:25`, `:820`, `:870` distinguishes persistent state from regeneratable cache. Its actual path is hardcoded under home, so it does not prove XDG override support.

[FileView 0.3.2](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/FileView/) documents atomic replacement, asynchronous completion and save-failure signals. The shell settings API returns whether an entry changed, not a disk-save acknowledgement. Selection persistence failure behavior therefore needs an implementation proof.

### 4. Pitfalls and removal steps

- **R5. Mixed revisions or half a library.** Read one resolved revision, serialize refresh work, then publish only a completed and saved candidate.
- **R6. Markdown is changed by transport.** Read raw regular blobs. Do not enable text conversion, trim collected output or rebuild bodies line by line. Prove leading/trailing whitespace, CRLF, Unicode and blank paragraphs through the actual Process collector.
- **R7. Repository links become prompt text or local filesystem traversal.** Accept regular blob modes only. Show visible file errors for symlink/submodule entries under the prompt root. Never check them out or follow them.
- **R8. Lenient authoring errors become whole-library rejection.** Apply the decided importer behavior inside a successful fetched revision. Bad metadata and excess depth retain visible errors. IO failure is a failed refresh, not an authored-file error.
- **R9. Cache deletion or unreadable disk is presented as a populated library.** Distinguish missing cache, corrupt/unreadable cache and saved cache. First use without a cache needs successful import. Do not claim encrypted local storage or access revocation of already-downloaded plaintext.

### 5. Questions the fork does not ask

**Q2a. Does the library contain large assets or thousands of prompts?** That could change transport and blob-collection costs. No arbitrary cap is proposed without a measured corpus. **Q2b. Should an empty newly created repo be selectable?** Recommend yes, with an explicit “No prompts yet” state. A repo with no commits cannot be cloned as a normal prompt revision, so empty-repo detection needs a separate visible setup state rather than a network-error label.

## Q3. Refresh timing and overlay states

### 1. Pick, reason and cost

**D3. Load the saved library locally, refresh in the background on summon when last checked more than five minutes ago, and provide manual Refresh.** First selection imports immediately. Do not add a recurring hidden timer. Five minutes is a proposed freshness tradeoff, not a measured optimum. Manual Refresh bypasses freshness but joins existing work and respects rate-limit holds. A failed attempt also starts a cooldown, preventing repeated shortcut presses from hammering an unavailable service.

Keep search, copy and the current edit available during refresh. Show “Refreshing” beside the source. After failure, show “Refresh failed. Using saved prompts from <time>” with Retry and a concrete reason. Label offline only when a network failure supports that label. With no cache, show connecting, an empty successful library, or a failed initial import as distinct states. An active draft retains its source text and revision through refresh and hide/reopen. Cost: remote changes can remain unseen while the overlay is unused, and cached access is not a guarantee of current remote authorization.

### 2. Rejected options

- **O9. Block each summon on a fetch.** Conflicts with instant access and offline use.
- **O10. Fetch on every summon without a gate.** Shortcut use becomes unnecessary network load.
- **O11. Continuous timer.** Consumes network while unused without an intake requirement for continuous freshness.
- **O12. Manual only.** Leaves routine remote edits invisible until the operator remembers to refresh.

### 3. Evidence: tier, source and date

Operator tier: `INTAKE.md:14`, `:32`, `:35`. Better-than-training, read 2026-10-12: [Process 0.3.2](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/Process/) takes argv arrays and runs asynchronously. Do not block FileView reads/writes on the UI thread. Live `/usr/share/omarchy/shell/plugins/menu/Menu.qml:1109`, `:1140` specifically identifies command changes during a running process and the need to inspect both exit code and exit status before replacing completed results. `/usr/share/omarchy/shell/plugins/panels/dropbox/Service.qml:59`, `:160`, `:220` provides external Process, timer and completed-output examples, not a mandate to poll.

[GitHub REST rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api) gives the usual authenticated user budget of 5,000/hour, shared with that user's other API usage. [REST best practices](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api) recommends efficient requests and respecting retry/reset headers. A real `gh api rate_limit` probe returned core and GraphQL limit 5,000 and remaining 5,000. This is a point-in-time API result, not a Git-transfer rate-limit guarantee.

### 4. Pitfalls and removal steps

- **R10. Old work completes after a repo/account switch.** Capture source identity and a selection generation per operation. Discard stale completion and stop tracked work where possible. Hide does not cancel the service.
- **R11. Refresh destroys an edited prompt.** Keep the draft separate from the library model. Apply new source data to subsequent selection only.
- **R12. Hung work leaves “Refreshing” forever.** Bound network operations with a timeout and transition on process failure, crash or timeout. Retry transient external failures a bounded number of times with visible status, then retain the last contextual error. Do not retry authentication/permission failures blindly.
- **R13. Retry ignores API throttling.** Respect Retry-After or reset time. Secondary limits without either require at least a minute before retry. The chosen cooldown does not override those instructions.

### 5. Questions the fork does not ask

**Q3a. What freshness delay is acceptable?** Recommend five minutes plus manual Refresh. **Q3b. Does hide/reopen persistence extend across a shell restart?** The intake requires in-session interruption. Durable draft storage is not implied, and is not added by this sync choice.

## Q4. Repository picker and number of sources

### 1. Pick, reason and cost

**D4. One selected github.com repo, chosen from accessible public/private repos or typed as `owner/repo`.** List `/user/repos` with `affiliation=owner,collaborator,organization_member`, `visibility=all`, up to 100 per page. Follow pagination links, show loaded results promptly, and provide Load more plus local filtering. Include owner and private status. A typed repo gets direct metadata and source-access validation, so an accessible public repo need not appear in the account's list. Track the default branch, including a later default-branch change.

Changing the source uses a pending selection until its first successful import or explicit empty-repo setup result. A failed change retains the previous selected source with its correct label. Authoring warnings remain valid imports under the locked lenient policy. Cost: a large account needs pagination, and the default-branch choice requires merging prompt edits to that branch before use.

### 2. Rejected options

- **O13. Own repos only.** Omits collaborator and organization repos the current account can read.
- **O14. Separate organization browser.** Adds navigation and calls when the accessible-repo endpoint already covers membership access. Typed lookup handles a known target.
- **O15. Typed only.** Satisfies access but underserves the requested settings choice.
- **O16. Several simultaneous repos.** Requires source naming, duplicate handling and independent refresh states without an intake requirement.
- **O17. Branch picker and arbitrary Git URL.** Adds source configuration beyond the requested GitHub repo choice. Neither is needed for the new standard repo.

### 3. Evidence: tier, source and date

Operator tier: `INTAKE.md:34`. Practitioner tier: Payne's design explanation in F2 supports one source, though varhop's temporary edits differ from chezmoi target files. Better-than-training, read 2026-10-12: [gh repo list](https://cli.github.com/manual/gh_repo_list) lists ownership under the specified owner and defaults to 30, not all repositories the user can access. [List repositories for the authenticated user](https://docs.github.com/en/rest/repos/repos#list-repositories-for-the-authenticated-user) documents accessible repositories, affiliation filters and pagination. [gh api](https://cli.github.com/manual/gh_api) documents pagination and that adding fields changes its default HTTP method to POST, so the picker must explicitly use GET.

Measured 2026-10-12: `gh repo list --limit 5 --json nameWithOwner,isPrivate,defaultBranchRef` returned owned repositories with both private/public visibility and main/master branches. `gh api --method GET user/repos -f per_page=5 -f affiliation=owner,collaborator,organization_member -f sort=updated` returned both owned and accessible organization/collaborator repositories, including private ones. These five-result samples establish the ownership difference, not exhaustive pagination. The private Git probe in Q1 demonstrates content transport access for one listed private repo.

### 4. Pitfalls and removal steps

- **R14. First page is mistaken for all repos.** Make pagination visible and always allow typed lookup. Follow Link headers rather than assuming a fixed page count.
- **R15. Metadata access is mistaken for content access.** Confirm the actual clone/fetch path before publishing a source choice. A private 404 can mean unavailable or unauthorized. Show that distinction honestly and identify SSO authorization when the service reports it.
- **R16. Fork selection resolves to its parent.** Fetch the explicitly selected canonical repo URL and ID. Do not use implicit upstream defaults.
- **R17. Rename changes cache ownership or paths.** Use account/repo IDs for storage and refresh names from metadata. Build argv arrays from validated repo metadata, never concatenate user text into a shell command.

### 5. Questions the fork does not ask

**Q4a. Must an unpublished non-default branch be usable?** Default no. **Q4b. Is selecting a repo expected to create its standard files?** Default no. The operator creates and adapts the repo, as already decided. **Q4c. Should switching sources keep an existing draft?** Recommend retain its source label until copied or deliberately replaced, so source refresh cannot silently change its contents.

## Remaining operation proof

**A1. Proven here:** stored-account API read, accessible repository discovery, current API budget, and private Git HEAD read with the installed helper. The public API commit SHA and public Git HEAD also matched for one repo.

**A2. Pending implementation proof:** initial bare clone, later fetch including force-push/default-branch change, exact blob-to-QML text preservation, actual private access from the shell process, atomic-save failure, source-switch cancellation, settings persistence, and offline reopen after a previously successful import. No clone, fetch, archive extraction, fixture creation, credentials mutation or cache write was run under this read-only brief.

**A3. Operator prerequisite:** create the new prompt repository and supply a real standard-format sample. Existing accessible repositories were used only for read-access probes and do not prove the new prompt layout. The operator's answers, not these notes, settle D1-D4.
