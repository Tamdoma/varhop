# Recorded leaf proof: repo-sync live calls, 2026-10-13

Head: 0fa6081 on repo-sync. Identity: gh keyring login `ivanjuras` (account 6634086). Target: private `Tamdoma/varhop-prompts` (id 1416196860), read-only per readiness.yaml grant. All calls through `bin/varhop-sync`/`bin/varhop-fetch`, which wrap every gh/git call in `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST -u GH_REPO`, `GIT_TERMINAL_PROMPT=0`, `GH_PROMPT_DISABLED=1`, `timeout`, command-scoped `-c credential.helper= -c 'credential.helper=!gh auth git-credential'`.

## Criterion 1 — status / repos / repo

`bin/varhop-sync status` → exit 0
```json
{"authenticated":true,"login":"ivanjuras","accountId":6634086,"scopes":["gist","read:org","repo","workflow"]}
```

`bin/varhop-sync repos` → exit 0; output contains
```json
{"fullName":"Tamdoma/varhop-prompts","id":1416196860,"private":true}
```

`bin/varhop-sync repo Tamdoma/varhop-prompts` → exit 0
```json
{"fullName":"Tamdoma/varhop-prompts","id":1416196860,"private":true}
```

Also verified: `status` under an empty `GH_CONFIG_DIR` → `{"authenticated":false,"fix":"gh auth login"}` exit 0.

## Criterion 2 — sync + accept byte-exact, identity-mismatch

`bin/varhop-sync sync Tamdoma/varhop-prompts <tmp> --generation 1 --expect-account 6634086 --expect-repo 1416196860` → exit 0
```json
{"status":"ok","login":"ivanjuras","accountId":6634086,"repo":"Tamdoma/varhop-prompts","repoId":1416196860,"commit":"030140c219b1b4ff84b7486287ae5c8684ba20f1","fetchedAt":1791849538413,"generation":1,"staged":"<tmp>/staged-1.json"}
```

`bin/varhop-sync accept <tmp> 1` → `{"accepted":1}` exit 0. `<tmp>` now holds `library.json` + `slot-b`.

Remote HEAD check: `git ls-remote https://github.com/Tamdoma/varhop-prompts.git HEAD` = `030140c219b1b4ff84b7486287ae5c8684ba20f1` — equals `library.json` `.commit`.

Byte check: a separate `clone --depth 1` of the remote (same env/helper), `git cat-file -p HEAD:<path>` per file vs `jq -rj .text` from the bundle, `cmp`:

```
IDENTICAL prompts/coding/review/code-review.md
IDENTICAL prompts/email/cold-email.md
IDENTICAL prompts/writing/rewrite-clearly.md
IDENTICAL prompts/writing/summarize.md
```
`errors: []`. `status ok`, `slot b`, `repoId 1416196860`, `accountId 6634086`, `login ivanjuras`, `generation 1`.

Identity-mismatch: `bin/varhop-sync sync Tamdoma/varhop-prompts <tmp2> --generation 1 --expect-account 6634086 --expect-repo 1` → exit 5
```json
{"error":"identity-mismatch","message":"account or repo id differs from the stored selection","fix":null,"stderr":"","actual":{"accountId":6634086,"repoId":1416196860}}
```
`<tmp2>` empty after the run — refusal happened before any fetch.
