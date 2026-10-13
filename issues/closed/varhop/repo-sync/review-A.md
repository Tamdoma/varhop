# Review A: repo-sync — check.review

Base a467aa6, reviewed head 0fa6081. Diff: `test/sync.test.ts` (+1 expectation fix), `bin/varhop-fetch`, `bin/varhop-sync`. Blind initial review (B's review not read).

## Verification evidence

- `bun test test/sync.test.ts` on head: 19 pass, 0 fail (rerun during review).
- `test` check green per `implementation/check-test.log`.
- `implementation/proof-live.md` verified against own reruns: `status` → `{"authenticated":true,"login":"ivanjuras","accountId":6634086,"scopes":[...]}`; `repo Tamdoma/varhop-prompts` → id 1416196860; sync+accept byte-compare vs `git cat-file` blobs: 4/4 identical, commit = `ls-remote` HEAD; `--expect-repo 1` → exit 5 `identity-mismatch`, empty cache.
- `gh api` 404 observed: rc1 + "Not Found (HTTP 404)" → classify maps to `not-found` correctly (rc4=auth only when unauthenticated, verified at implement).
- `git ls-files -s bin/` → 100755 both executables.
- AREA/docs touched: none; `docs/reference-index.md` paths all exist; no documented behavior changed.

## Findings

### Fixes

- **F1 — plan.md D5 `no-prompts` clause contradicts code and design.** Source: implement notes; plan D5 states "present but collecting zero `.md` files also `no-prompts`". `bin/varhop-fetch` only emits `no-prompts` when the `prompts/` directory is absent; an existing-but-empty `prompts/` yields `status:"ok","files":[]`. The locked design names only the missing-directory state, so the plan's extra clause is a plan error, not a code bug. Consequence: a repair seat implementing the clause would report `no-prompts` for a repo whose every prompt is an error entry (e.g. only invalid-UTF-8 files), hiding real errors behind a benign state; overlay-plugin would consume a status the design never declared. Hits: contract correctness (done-criterion 4 names `no-prompts` only for missing `prompts/`). Route: A plan correction — correct plan.md D5 to match the design and the implemented behavior; add the plan rule's executable check per check.fix.

### Nits

- **N1 — multi-account `status` reads `.hosts["github.com"][0]`** rather than the `active:true` entry. Deferred: single stored login today (S8); promotion evidence: a second gh login on the operator machine making `[0]` inactive.
- **N2 — stale `staged-tmp-*.json` residue** survives `accept`'s sweep (`staged-*.json` glob excludes `staged-tmp-*`), and a `staged-tmp-<n>.json` directory left by a crash permanently fails that generation's write. Deferred: requires an interrupted run at a specific line; promotion evidence: observed crash residue.
- **N3 — refresh-path `git config varhop.repoid` failure classifies as `network`.** Deferred: config writes to the local clone only fail on filesystem corruption; promotion evidence: a real failure classified misleadingly in a report.
- **N4 — `find` matches only lowercase `*.md`.** Deferred: design pins `prompts/<...>/<name>.md`; a `.MD` file is out of format.
- **N5 — corrupt `library.json` is treated as active slot `a`** (`// "a"`) instead of a cache-io error; a subsequent `accept` silently heals it. Deferred: the file is leaf-written only; promotion evidence: a real corruption path.
- **N6 — `err` called before `files_tmp`/`errors_tmp` exist** leaves the EXIT trap running `rm -f ""` (cosmetic stderr only). Deferred: no behavioral consequence.
- **N7 — tests never assert `sync`'s happy path** (only fetch + accept + validation + auth), because `sync` has no URL override and always hits github.com. Deferred by design: the real `sync` path is criterion 2's recorded live proof, which passed.

## Verdict

`fix` — F1 is a plan/code contradiction routed to A as a plan correction; code and live proofs otherwise satisfy all six done-criteria.
