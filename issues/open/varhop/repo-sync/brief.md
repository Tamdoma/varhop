# Brief: repo-sync

## What
Two executables that use only tools on stock Omarchy (bash, git, gh, jq, coreutils, iconv) and never ask for input. Each prints one JSON object to stdout. The shapes and exit codes are pinned in the design.
- `bin/varhop-sync` is the GitHub front:
  - `status`: gh login state, login, numeric account id and scopes, or the `gh auth login` fix. (A,C)
  - `repos`: `/user/repos` (fullName, id, private), paginated.
  - `repo <owner/repo>`: looks up one typed repo's id, including a repo outside `/user/repos`. (A,C)
  - `accept <cache-dir> <n>`: publishes staged generation `n`. (A,B)
  - `sync <owner/repo> <cache-dir> --generation <n> [--expect-account <id> --expect-repo <id>]`: validates the argument, reads the live account and repo ids, and refuses with `identity-mismatch` before any fetch when they differ from the expected ids. Otherwise it runs `varhop-fetch` on `https://github.com/<owner>/<repo>.git`. (A,B,C)
- `bin/varhop-fetch <git-url> <cache-dir> <repo-id> <account-id> <login> <generation>` owns the two clone slots, the fetch, the file read and the bundle. It is the boundary the local `file://` fixtures call, the same code `sync` runs, with no URL override in `varhop-sync`. (A,B,C)

Every gh and git call runs under `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO` with `GIT_TERMINAL_PROMPT=0` and `GH_PROMPT_DISABLED=1`, the design's timeouts, and git's command-scoped helper `-c credential.helper= -c 'credential.helper=!gh auth git-credential'`.

Staging and publication: `varhop-fetch` refreshes the inactive slot, recloning it when its recorded repo id differs, and builds the bundle from that slot. After the read and every check succeed, it renames the bundle onto `<cache-dir>/staged-<n>.json` and never touches `library.json`. Only `accept <cache-dir> <n>` renames `staged-<n>.json` onto `library.json`. That rename is the single publication point and makes the bundle's slot the active one. overlay-plugin calls `accept` after its import and selection save succeed. A failure, cancellation or stale generation therefore leaves the last accepted `library.json` and active slot untouched. (A,B,C)

## Why
overlay-plugin needs a library it can load with one read and a pull that never leaves a half-updated or wrong-account library. Keeping git, gh and byte fidelity behind one CLI makes the forks' rules provable at the process boundary.

## Done-criteria
1. A recorded leaf proof (not a committed test): `varhop-sync repos` lists `Tamdoma/varhop-prompts` with id 1416196860, `repo Tamdoma/varhop-prompts` returns that id, and `status` returns `ivanjuras`, 6634086 and the scopes, using the stored gh login. (A,C)
2. A recorded leaf proof: `varhop-sync sync Tamdoma/varhop-prompts <tmp-dir> --generation 1 --expect-account 6634086 --expect-repo 1416196860`, then `accept <tmp-dir> 1`, writes a bundle whose commit equals the remote HEAD and whose every file text equals its git blob byte for byte. The same command with `--expect-repo 1` exits `identity-mismatch` and writes nothing. (A,B,C)
3. Bun tests calling `varhop-fetch` and `varhop-sync accept` against local `file://` fixture repos:
   - A fetch writes `staged-<n>.json` and leaves `library.json` byte-identical. `accept` of that generation publishes it, and a second fetch plus accept after a new commit publishes the new file. (A,B)
   - `accept` of a generation that was never staged exits non-zero and changes nothing. Accepting generation n deletes other staged files. (A,B)
   - A failed fetch exits non-zero with the error JSON and leaves the previous `library.json` and active slot byte-identical. (A,C)
   - Fetch plus accept of repo A, then a fetch of repo B that is never accepted, leaves A's `library.json` and active slot untouched. A later accept publishes B. (A,B,C)
   - A failure injected after the read and before the staged rename (an unwritable temp file) leaves no staged file and the previous bundle. (A,B)
   - Checkout transforms from a `.gitattributes` with `eol=crlf ident` do not alter bundle text.
4. A repo with no commits and a repo without `prompts/` stage statuses `empty-repo` and `no-prompts`, exit 0. Symlinks, submodules and non-`.md` files are skipped, and an invalid UTF-8 file (checked with `iconv -f UTF-8 -t UTF-8`) becomes an error entry while the other files load.
5. Malformed repo arguments (`../x`, `a/b/c`, `-x/y`, names with spaces or shell metacharacters) are refused with exit code 2 before any process runs.
6. With no usable gh login (an empty `GH_CONFIG_DIR`), `status` reports `authenticated: false` with the `gh auth login` fix, and `sync` exits `auth` within its timeout. Neither prompts.
