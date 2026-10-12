# Proofs: GitHub sync and clipboard, 2026-10-13

Grant: the operator asked to "make something up yourself, and test it out" and to put it in the Tamdoma org (2026-10-13). Identity: gh login `ivanjuras` (account id 6634086, keyring, scopes gist/read:org/repo/workflow), org role admin.
- Created and retained by agreement: the private repo `Tamdoma/varhop-prompts` (id 1416196860). Purpose: the operator's starter prompt library. Owner: the operator. No removal date. Cleanup identity: not applicable (retained). Note: the token lacks `delete_repo`.
- Writes: repo create plus two pushes of starter prompts. Everything else is a read.
- Local clones live in the session scratchpad and are deleted after the proof.

Environment for every call: `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO`, `GIT_TERMINAL_PROMPT=0`, `GH_PROMPT_DISABLED=1`, `timeout N`. Helper: `-c credential.helper= -c 'credential.helper=!gh auth git-credential'`. Versions: gh and git as installed 2026-10-13.

| # | Call | Observed | Does not prove |
|---|---|---|---|
| S1 | `gh api '/user/repos?per_page=100' --paginate` | Lists Tamdoma/varhop-prompts, private, id 1416196860 (an org repo via membership) | Picker UI, very large account lists |
| S2 | `gh api user`, `gh api repos/Tamdoma/varhop-prompts` | login ivanjuras id 6634086, repo id 1416196860 | Account-switch reconfirm flow |
| S3 | `git -c credential.helper= clone --depth 1 --no-checkout` (no helper) | Fails in 0.2 s: "terminal prompts disabled". No hang. | Fix-message wording |
| S4 | Same clone with the helper | Succeeds. `ls-tree -r -z` lists README plus prompts | Clone timeout tuning |
| S5 | Write `$GIT_DIR/info/attributes` = `prompts/** -text -filter -ident -working-tree-encoding`, then checkout | All 5 files byte-identical to their blobs | — |
| S6 | Local fixture with `.gitattributes` `*.md text eol=crlf ident` | Without info/attributes: TRANSFORMED. With it: identical. The locked setting at its locked location neutralizes the transforms. | `filter=` drivers (not installed here) |
| S7 | New commit pushed, then `fetch -q --depth 1 origin HEAD` + `reset -q --hard FETCH_HEAD` | The slot moves to 030140c and the new prompt appears | Two-slot switch logic (leaf code) |
| C1 | `wl-copy --type 'text/plain;charset=utf-8' < file` | `wl-paste` returns identical bytes for CRLF, č/ć/đ/š/ž and trailing blank lines. Offered types include text/plain;charset=utf-8 and text/plain. | Copy from inside the QML Process (leaf) |
| C2 | Empty stdin to wl-copy | exit 0, paste returns 0 bytes | — |

Clipboard: the prior text/plain content (103 bytes) was saved and restored, verified with cmp. Clipboard history may hold the two test strings (history capture was accepted in copy-and-close).

Findings
- The API reports `size: 0` for the new repo right after the push, so the "size warning from API repo size" can lag on new repos.
- Empty-repo and missing-`prompts/` states are to be tested on local file:// fixtures in the leaf, not on GitHub.

## Proof 2: gh status (C H3), 2026-10-13

| # | Command | Observed | Limits |
|---|---|---|---|
| S8 | `env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --json hosts` with the real login | exit 0, `{"state":"success","active":true,"login":"ivanjuras","scopes":"gist, read:org, repo, workflow","tokenSource":"keyring"}` under `hosts["github.com"]` | Expired-token state not observed |
| S9 | Same with an empty `GH_CONFIG_DIR` | exit 0, stdout `{"hosts":{}}`, stderr "You are not logged into any GitHub hosts. To log in, run: gh auth login" | — |
