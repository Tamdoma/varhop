# Design: repo-sync

## Binding decisions, verbatim

### sync-and-auth (issues/chart/varhop/forks/sync-and-auth.md)
#### Taken

2026-10-12 operator: `1a | 2 - manual pull, no automatic | 3a | 4a`
- Q1 1a: shallow working clone under `~/.cache/varhop/`, read from disk, with C2's two amendments: `$GIT_DIR/info/attributes` neutralizes checkout transforms on `prompts/**` (proof: CRLF-attributes fixture reads byte-identical to blobs), and two clone slots, refresh the inactive one and switch only after fetch, checkout, read and index succeed (foreclosed: bare clone + cat-file).
- Q2 operator choice, not an offered option: no automatic refresh at all. The first clone runs when a repo is chosen; afterwards the library changes only on a manual pull (Ctrl+R in the overlay, "Sync now" in settings). The footer shows when the copy was last updated. Foreclosed: refresh on summon, cooldowns, timers. The cooldown-timestamp state item is moot.
- Q3 3a: the old library stays until the new repo imports; selection is saved last; a generation number tags every async completion (foreclosed: delete then clone).
- Q4 4a: the gh login name plus numeric account id and repo id are stored with the selection; a mismatch asks to reconfirm the repo through the Q3 path; processes run under `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO` (foreclosed: cache keyed per account/repo id).
- Also binding from Findings: reuse the stored `gh` login with the command-scoped helper, no stored credential, prompts disabled, per-operation timeouts; `/user/repos` picker plus a strictly validated typed `owner/repo`; selection in shell.json via `updateEntryInline` (full object), volatile state elsewhere; empty repo and missing `prompts/` are named states.

### repo-format (issues/chart/varhop/forks/repo-format.md)
#### Taken

2026-10-12 operator: `| 1a | 2a | 3a | 4a |` (Q5, what the Notion prompts look like, not answered).
Taken so far: Q1 `prompts/<category>/<subcategory>/<name>.md`, subcategory optional, deeper files shown with an error note, README outside `prompts/` ignored, no version file in v1 (foreclosed: any depth). Q2 YAML-lines front matter in the same file, optional `title` (default file name), `description`, `tags`, unknown keys ignored, broken front matter still loads with an error shown (foreclosed: JSON sidecar, no metadata). Q3 uppercase-only `{{NAME}}` (A-Z, 0-9, underscore), anything else in braces is literal, `\{{NAME}}` for literal (foreclosed: any case). Q4 no defaults or hints in v1; unknown keys ignored so they can be added later (foreclosed: `vars` now).

2026-10-12 operator, Q5: `it doesn't matter, I will adapt them to the new version. I'll create a new repo from scratch. The only requirement is that they're in markdown format, and they can contain and types of spaces and signs, paragraphs, etc.`
Taken: Q1-Q4 as recorded above. Q5: no migration or import tool; the operator builds a new repo to this format. Binding: prompt bodies are arbitrary Markdown and are copied verbatim (any whitespace, symbols, paragraphs); only `{{NAME}}` tokens and the `\{{` escape are interpreted.

### front-matter (issues/chart/varhop/forks/front-matter.md)
#### Taken (2026-10-13)
Operator answer: `1a | 2a | 3a`. The defaults presented were not objected to and are recorded as taken. Sources: slots/front-matter-{A,B,C,merged,rebuttal-B,rebuttal-C}.md.

Boundary (1a, B's rule)
- A header exists when line 1 is exactly `---` (after one optional BOM, with CRLF accepted) and a later line is exactly `---`. The header ends at the first such line, which may be at EOF.
- Validity never moves the boundary. A malformed header shows errors, and the body is everything after the close.
- An empty header (`---` then `---`) is valid. It is the documented escape for a prompt that must start with `---`.
- With no close, the whole file is body and an "unclosed front matter" error is shown.
- A leading blank line or space means there is no header.

Values (2a, A/C subset)
- `title` and `description` are single-line scalars. They can be plain (trimmed, with a ` #` comment stripped, and `: ` inside a value unsupported, so quote it), single-quoted (`''` escape), or double-quoted (`\\ \" \n \r \t \uXXXX`).
- Empty values, `~` and `null` mean absent.
- `tags` accepts a flow list `[a, "b c"]` (quote-aware), block `- item` lines (indented or not), or one scalar as a single tag. Duplicate tags are dropped.
- Block scalars, flow maps, anchors and aliases, multiline quotes and nested maps on a known key are unsupported.
- Unknown keys and their lines are skipped silently.

Errors (3a)
- An unsupported or malformed known key is ignored with a file and line error. The other keys stay.
- For a duplicate known key, the first wins and the second gets an error.

Body bytes
- The body is sliced by offset after the closing line's line break. Nothing is trimmed. Line endings and the final newline are preserved.
- One leading BOM is stripped from every file (default).
- Invalid UTF-8 is a file error, validated at the raw-data boundary (FileView data vs text, proof owed). Replacement-character decoding is never called verbatim.

Fixtures: a thematic break, then prose, then a break (the prose becomes an error and the body after the second break, per 1a); a YAML example body; an unclosed `---`; a title with `: ` and `#`; `description: |`; BOM plus a CRLF header with leading blank lines and no final newline; a BOM without a header; the empty-header escape; a duplicate title; mixed-type tags; indentless block tags; an invalid UTF-8 file.

### Excluded binding decisions
- form-factor, variable-editing, copy-and-close, search and settings-and-hotkey belong to overlay-plugin and prompt-core.
- From sync-and-auth, the selection save in shell.json, the generation numbers on async completions, the footer and Ctrl+R wiring belong to overlay-plugin. This leaf owns the commands, the clone slots, the identity data and the bundle.
- From front-matter, only the raw-boundary UTF-8 validation belongs here. Parsing belongs to prompt-core.

## Standing design

/home/ivan/.claude/skills/chart-issues/assets/standing-design.md

- Auth is never mocked. The two real-call criteria use the operator's stored gh login (ivanjuras), read-only, against the retained private repo Tamdoma/varhop-prompts. They are proven in issues/chart/varhop/proofs-sync.md (S1-S9).
- The real-call criteria are recorded leaf proof commands, not bun tests in the tree. The blocking `test` check never calls GitHub. (A,C)
- file:// fixture repos created inside a test's temp dir are test setup, not machinery. Tests reach them through `varhop-fetch`, the same code `sync` runs. (A,B,C)
- No secret is stored. The token stays in gh's keyring.

## Leaf architecture

Owned paths: bin/varhop-sync, bin/varhop-fetch and their bun tests (spawning the executables against file:// fixtures in temp dirs).

Contract consumed by overlay-plugin (A,B,C). Every stdout object is one line of JSON. Times are Unix epoch milliseconds.
- `status` → exit 0, `{"authenticated": true, "login", "accountId", "scopes": [..]}` or `{"authenticated": false, "fix": "gh auth login"}`. It comes from `gh auth status --json hosts` (S8, S9) plus `gh api user` for the id.
- `repos` → `{"repos": [{"fullName", "id", "private"}]}`
- `repo <owner/repo>` → `{"fullName", "id", "private"}` from `gh api repos/<owner>/<repo>` (S2).
- `sync ...` and `varhop-fetch ...` → `{"status": "ok" | "empty-repo" | "no-prompts", "login", "accountId", "repo", "repoId", "commit", "fetchedAt", "generation", "staged": <path>}`, exit 0, after staging. (A,B)
- `accept <cache-dir> <n>` → `{"accepted": n}`, exit 0, after renaming `staged-<n>.json` onto `library.json` and deleting other `staged-*.json`. A missing staged file is `not-staged`, exit 9. (A,B)
- `<cache-dir>/staged-<n>.json` and, after accept, `<cache-dir>/library.json` = `{"version": 1, "generation", "repo", "repoId", "accountId", "login", "commit" | null, "fetchedAt", "status", "slot": "a" | "b", "files": [{"path", "text"}], "errors": [{"path", "message"}]}`.
- Failure → `{"error": class, "message", "fix" | null, "stderr"}` with the exit code per class: usage 2, auth 3, not-found 4, identity-mismatch 5 (the object adds `actual: {accountId, repoId}`), network 6, timeout 7, cache-io 8.
- Timeouts: 15 s per gh call, 60 s per clone or fetch, enforced with `timeout`.
- `--expect-account` and `--expect-repo` come as a pair. They are omitted only on the first selection of a repo.

Cache layout: `<cache-dir>/{slot-a, slot-b, staged-<n>.json, library.json}`. Each slot records its repo id in `git config varhop.repoid`. The active slot is the one named in the accepted `library.json`, and every fetch uses the other one. A bundle is written to a temp file in `<cache-dir>` and renamed onto `staged-<n>.json`. Only `accept` renames it onto `library.json`. There is no separate `active` file. (A,B,C)
The owner/repo pattern is ^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}$, and . or .. as the name is refused. (A,C)
Runtime tools: stock Omarchy only (bash, git, gh, jq, coreutils, iconv). No bun or node at the user's runtime.
Exclusions: QML, parsing prompt text, writing shell.json.
