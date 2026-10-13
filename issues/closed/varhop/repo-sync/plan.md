# Plan: repo-sync

Direct synthesis (`debate: no`). Locked design is authoritative.

## Decisions

- D1: Two executable bash scripts at `bin/varhop-sync` and `bin/varhop-fetch`, stock Omarchy tools only (bash, git, gh, jq, coreutils, iconv, timeout). No bun/node at runtime. `chmod +x` both.
- D2: Every gh/git call runs wrapped: `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO` plus exported `GIT_TERMINAL_PROMPT=0` and `GH_PROMPT_DISABLED=1`, `timeout 15` per gh call and `timeout 60` per git clone/fetch/ls-remote, git credential helper command-scoped `-c credential.helper= -c 'credential.helper=!gh auth git-credential'`. rc 124 -> `timeout` (exit 7).
- D3: `varhop-fetch <git-url> <cache-dir> <repo-id> <account-id> <login> <generation>` is the single fetch boundary. `sync` calls it on `https://github.com/<owner>/<repo>.git` after the identity check; no URL override exists in varhop-sync. Fixture tests call varhop-fetch with `file://` URLs — the same code path.
- D4: Two slots `slot-a`/`slot-b`. Active slot = `"slot"` field of `library.json` (absent library -> `slot-a` is active for naming only). Fetch uses the other slot; if that slot's `git config varhop.repoid` differs from the passed repo id (or the slot is missing/broken) it is deleted and recloned. Refresh order: `ls-remote <url> HEAD` first — empty output means `empty-repo` (commit null, still staged, exit 0); else clone `--depth 1 --no-checkout` or fetch `-q --depth 1 origin HEAD`; write `$GIT_DIR/info/attributes` = `prompts/** -text -filter -ident -working-tree-encoding` before any checkout; `reset -q --hard FETCH_HEAD`; `git config varhop.repoid <id>`; commit = `rev-parse HEAD`. Probe-verified: info/attributes before checkout yields working-tree bytes identical to blobs under `eol=crlf ident` fixtures.
- D5: File walk after checkout: `prompts/` dir absent -> `no-prompts` (commit = HEAD, still staged, exit 0). Present but collecting zero `.md` files yields `no-prompts` only when `errors[]` is also empty (a dir of only non-`.md` files or no files); an errors-only collection stays `ok` so the errors surface. Only regular files matching `prompts/<cat>/[<sub>/]<name>.md` (1-2 intermediate dirs) become `files[]`; deeper files and files directly under `prompts/` become `errors[]` entries (invalid layout); symlinks, gitlinks (submodules), non-`.md`, and everything outside `prompts/` are skipped silently. Each collected file: `iconv -f UTF-8 -t UTF-8` check — invalid bytes -> `errors[]` entry, others still load (status stays `ok` with errors present).
- D6: Bundle written via `jq --rawfile` per file (probe-verified: preserves exact bytes incl. missing trailing newline; `-R`/slurp mangles it) assembled to `{"version":1,"generation",repo,repoId,accountId,login,commit,fetchedAt,status,slot,files:[{path,text}],errors:[{path,message}]}` into fixed temp name `<cache-dir>/staged-tmp-<generation>.json` then `mv` onto `staged-<n>.json`. `repo` = owner/repo parsed from the URL (empty string for unparseable fixture URLs). Failure of the write/rename leaves no `staged-<n>.json`.
- D7: `accept <cache-dir> <n>`: missing staged file -> `{"error":"not-staged",...}` exit 9, changes nothing. Success: `mv staged-<n>.json library.json`, then delete other `staged-*.json`, print `{"accepted":n}` exit 0. That rename is the only publication point; nothing else writes `library.json`.
- D8: `varhop-sync` subcommands: `status` (`gh auth status --json hosts` + `gh api user` when authed; empty hosts -> `{"authenticated":false,"fix":"gh auth login"}` exit 0); `repos` (`gh api /user/repos?per_page=100 --paginate` -> `{repos:[{fullName,id,private}]}`); `repo <o/r>` (`gh api repos/<o>/<r>` -> `{fullName,id,private}`); `accept` delegates to the same rename logic; `sync <o/r> <cache-dir> --generation <n> [--expect-account <a> --expect-repo <r>]`.
- D9: Validation before any subprocess (exit 2, `{"error":"usage"}`): owner/repo must match `^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}$` and neither component may be `.` or `..`; `--generation` required, digits only; `--expect-account`/`--expect-repo` both-or-neither, digits only. `varhop-fetch` validates arg count and numeric ids/generation.
- D10: Identity check in `sync`: after validation, `gh api user` (login + id) and `gh api repos/<o>/<r>` (id) under the wrapped env. Expected ids present and differing -> `{"error":"identity-mismatch","actual":{accountId,repoId}}` exit 5 before any fetch. Then `varhop-fetch` with the live ids.
- D11: Error JSON `{"error":class,"message","fix":null|string,"stderr"}`: usage 2, auth 3 (gh exit 4 or stderr naming `gh auth login`; fix `gh auth login`), not-found 4 (gh 404 / `gh api` 4 with Not Found, git `Repository not found`), identity-mismatch 5, network 6 (any other gh/git nonzero incl. `does not appear to be a git repository`), timeout 7 (rc 124), cache-io 8 (mkdir/mv/read failures), not-staged 9 (accept only).
- D12: Serial-solo run: one unit owns `bin/` + `test/`; tests committed red first.

## Read-first

- `issues/open/varhop/repo-sync/brief.md`, `design.md` — pinned JSON shapes, exit codes, staging contract.
- `issues/chart/varhop/proofs-sync.md` — verified commands/env for S1-S9 (clone recipe, attributes line, gh shapes).
- `docs/reference-index.md` -> `issues/chart/varhop/CHART.md` — leaf boundaries (no QML, no shell.json, no front-matter parsing).

## Interfaces

- stdout: exactly one JSON object per line; success shapes and `staged-<n>.json`/`library.json` bundle schema as pinned in design.
- `varhop-fetch` args: `<git-url> <cache-dir> <repo-id> <account-id> <login> <generation>`.
- `varhop-sync` commands: `status | repos | repo <o/r> | accept <cache-dir> <n> | sync <o/r> <cache-dir> --generation <n> [--expect-account <a> --expect-repo <r>]`.
- Consumed later by overlay-plugin: `library.json`, `accept`, `status`, `repos`, `repo`, `sync`.

## Waves

Serial-solo (one unit):

- U1 `bin/varhop-fetch`, `bin/varhop-sync`, `test/sync.test.ts` — owns `bin/`, `test/`; no shared resources; no prerequisites.

## Checklist

- `bin/varhop-fetch` — D2,D3,D4,D5,D6,D9,D11
- `bin/varhop-sync` — D2,D3,D7,D8,D9,D10,D11
- `test/sync.test.ts` — bun:test, spawns the real executables against `file://` fixture repos in temp dirs; no GitHub access.
- Agent docs: none affected. Human docs: none affected.

## Done-criteria -> proof map

| # | Criterion | Proof | Size | Rerun trigger |
|---|---|---|---|---|
| 1 | status/repos/repo against real gh login | Recorded leaf proof (not a committed test): run `bin/varhop-sync status`, `repos`, `repo Tamdoma/varhop-prompts` under the grant env; record outputs (ivanjuras, 6634086, id 1416196860, scopes) in a leaf proof file | seconds | any change to `varhop-sync` auth/api code |
| 2 | real sync + accept + identity-mismatch | Recorded leaf proof: `sync Tamdoma/varhop-prompts <tmp> --generation 1 --expect-account 6634086 --expect-repo 1416196860`, `accept <tmp> 1`, compare commit to remote HEAD and each `files[].text` to `git show` blobs; then `--expect-repo 1` must exit 5 writing nothing | minutes | any change to fetch/accept/identity code |
| 3 | bun tests vs `file://` fixtures | `bun test test/sync.test.ts` — publish/keep-alive, not-staged + sweep, failed fetch preserves state, A/B unaccepted isolation, unwritable-temp staged injection, eol=crlf ident neutralization, slot alternation | seconds | any change under `bin/` |
| 4 | empty-repo, no-prompts, symlink/submodule/non-md skip, invalid UTF-8 | Same test file: empty remote, missing `prompts/`, `prompts/` with only non-`.md`, symlink + gitlink + `.txt` fixtures, `iconv` boundary | seconds | walker/bundle changes |
| 5 | malformed owner/repo | Same test file: `../x`, `a/b/c`, `-x/y`, space and `;` names -> exit 2 `usage` | seconds | validation changes |
| 6 | no gh login | Same test file: empty `GH_CONFIG_DIR` -> `status` `authenticated:false` + fix; `sync` exits 3 `auth`, no prompt | seconds | auth code changes |

Checks command `test` (`bun install && akrogon guard own-modules && bun test --pass-with-no-tests`) covers 3-6; criteria 1-2 are recorded proofs run during implement against the retained read-only grant (readiness.yaml grants).

## Red tests recorded at plan.synthesis

New file `test/sync.test.ts` (19 tests) shown red: every spawn of `bin/varhop-fetch`/`bin/varhop-sync` fails `ENOENT: no such file or directory` — `0 pass, 19 fail`. Verified via both `bun test test/sync.test.ts` and the leaf `test` check (`akrogon run-check --name 'test' ...`); no other failure. Committed on `repo-sync` before product code.

## Implementation notes

2026-10-13 (implement, A):
- `gh auth status --json hosts` returns host entries as `.hosts["<host>"]` array, first element holds `login`/`scopes`; `status` reads `.hosts["github.com"][0]`.
- `repo` field: `owner/repo` parsed from the URL with `.git` stripped; for non-GitHub URLs (file:// fixtures) it falls back to the URL's last two path components — a stable identity label, never a key.
- The env-scrub/error-classify helpers are duplicated between the two executables instead of a shared sourced file: each script must run self-contained under stock bash; the duplicates are ~40 lines.
- `sync` resolves `varhop-fetch` via `readlink -f $0` so it works through symlinked PATH entries.

## Open limitations

- gh exit-code classification is pattern-based (rc 4 / `gh auth login` text / `Not Found`); unclassified gh/git failures land in `network` with stderr preserved.
- `empty-repo` detection uses `ls-remote <url> HEAD` emptiness, not stderr parsing.
- Expired-token gh state never observed (proof limit S8); treated as auth-class via same stderr signal.
