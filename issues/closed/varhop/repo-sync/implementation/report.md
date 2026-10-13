# Implementation report: repo-sync

Serial-solo (one unit in plan.md), A implemented directly. Base a467aa6 → head 0fa6081 on `repo-sync`. No worker worktrees.

## Changed files

- `test/sync.test.ts` (fb23300, committed at plan.synthesis): 19 tests spawning the real executables against `file://` fixture repos in temp dirs.
- `test/sync.test.ts` (3db8ec6, Test-Change): `repoId` expectation string → number; the design's bundle schema carries numeric ids (`gh api .id`), real output showed `222`.
- `bin/varhop-fetch` (358823a): two-slot fetch boundary — arg validation, `ls-remote` empty-repo check, reclone-on-repo-id-mismatch, `info/attributes` neutralization before checkout, `find -type f -name '*.md'` walk with layout/UTF-8 error entries, `jq --rawfile` bundle → `staged-tmp-<n>.json` → `staged-<n>.json` rename.
- `bin/varhop-sync` (358823a): `status`/`repos`/`repo`/`accept`/`sync` subcommands, owner/repo + flag validation before any subprocess, identity-mismatch gate before fetch, error classes with exit codes per design.
- `bin/varhop-sync`, `bin/varhop-fetch` (0fa6081): `status` host lookup corrected to `.hosts["github.com"][0]` (gh nests entries in an array — first live run proved it); `repo` name strips `.git`.

## Commands run (evidence)

- `bun test test/sync.test.ts` → 19 pass, 0 fail (857ms–1.5s across runs). Log: `check-test.log`.
- `akrogon run-check --name 'test' -- sh -c 'flock ... bun install && akrogon guard own-modules && bun test --pass-with-no-tests'` → green, same 19 tests. Log: `check-test.log`.
- Criterion 1+2 live proofs: `proof-live.md` (status/repos/repo, sync+accept byte-exact vs remote HEAD, identity-mismatch refusal). Grant: readiness.yaml `grants[0]` — operations `gh auth status`, `gh api /user`, `gh api /user/repos --paginate`, `gh api repos/Tamdoma/varhop-prompts`, clone/fetch — all read-only, within bounds, no new IDs created.

## Done-criteria map

| # | Criterion | Evidence |
|---|---|---|
| 1 | status/repos/repo vs real gh login | `proof-live.md` Criterion 1 — pass |
| 2 | sync+accept byte-exact, identity-mismatch | `proof-live.md` Criterion 2 — pass |
| 3 | fetch/accept lifecycle vs file:// fixtures | `bun test` — 6 lifecycle tests pass |
| 4 | empty-repo / no-prompts / skips / invalid UTF-8 | `bun test` — 4 selection tests pass |
| 5 | malformed owner/repo exit 2 | `bun test` — 7 rejection cases + flag-pairing test pass |
| 6 | no usable gh login | `bun test` — empty `GH_CONFIG_DIR` status + sync auth; also `proof-live.md` |

## check.fix repair (2026-10-13)

Both reviews flagged the same plan/code fork on D5 (`plan.md` said zero collected `.md` files means `no-prompts`; code emitted `ok` for an existing-but-empty `prompts/`). Resolved: implement D5 with the error-visibility carve-out — `no-prompts` when zero files AND zero errors, `ok` when error entries exist. `plan.md` D5 and the criterion-4 proof row corrected to this rule; the reproduction test is the executable check for the corrected rule.

- `7f16792` Test-Change: reproduction test — `prompts/` holding only `draft.txt` staged `no-prompts`, shown red before the fix (19 pass, 1 fail).
- `d22e7c4` fix: `STATUS=no-prompts` when `files_tmp` and `errors_tmp` are both empty after the walk.
- Rerun: `bun test` 20 pass, 0 fail; `test` check green (`implementation/check-test-fix.log`). Live proofs in `proof-live.md` unchanged and still valid — no auth/network/accept code touched.
- Prior reviewed base/head: a467aa6 / 0fa6081. Repaired head: d22e7c4 (same base; rebase clean).

## Limitations

- gh/git failure classes beyond auth/not-found land in `network` with stderr preserved (classification is pattern-based by design).
- `repo` field for non-GitHub fixture URLs is the URL's last two path segments — an identity label only.
- Expired-token gh state unobserved (same limit as S8); auth-class via stderr signal.
- `merge_checks` not run — the brief names no whole-run criterion; merge runs it.
