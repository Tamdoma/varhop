# sync-and-auth: rebuttal C (disagreements only, 2026-10-12)

Probes below ran in a scratch dir against ivanjuras/kybern (private, 61 tree entries) with `GIT_TERMINAL_PROMPT=0` and the inline gh helper; scratch deleted.

RC1. D-a: hold the working clone, add B's enumeration. B's three reasons do not hold against the design A and C actually proposed.
- "Line-ending and smudge transforms": a checkout is byte-identical to the blob on this machine (`cmp` of `git cat-file blob HEAD:<file>` against the checked-out file: identical; `core.autocrlf` unset at every config origin; no `.gitattributes` in the probed repo). Transforms need the repo author to add attributes, and the operator authors the repo (repo-format Taken). Nothing to remove.
- "Merge conflicts": A and C use `fetch` then `reset --hard FETCH_HEAD`, never `pull`. A reset cannot conflict.
- "Symlinks never followed": that comes from enumerating with `git ls-tree -r` and accepting mode 100644 only, which works the same in a working clone. Take that step from B; it does not need a bare repo.
- Cost B does not state: reading blobs from a bare repo from QML means one `git cat-file blob` Process per prompt, or a `cat-file --batch` session driven through `Process.write` (quickshell-io.qmltypes:131,188) with a JS parser for the `<sha> blob <size>\n<bytes>` protocol. A working clone reads each file with `FileView.text()` and no parser. Clone time is equal (bare 1.07 s, working 0.99 s); disk difference is 2.3 MB on a 3 MB repo.

RC2. D-b: concede ~/.cache on one condition. Omarchy itself wipes nothing under ~/.cache broadly (the only hit is migrations/1790528634.sh:28, one named directory), and first-party regeneratable data lives in `~/.cache/omarchy/<feature>` (plugins/image-picker/list.sh:4, plugins/lock/poster.sh:7). Condition: a missing cache is the "cloning <repo>" state, not an error, so a wiped cache self-heals on the next online open.

RC3. D-c: concede 5 minutes and the failed-attempt cooldown. Manual refresh still bypasses the cooldown; it should not be gated by a prior failure.

RC4. D-d: partial. Store the gh login name next to the repo selection and reconfirm the repo when `gh api user --jq .login` returns a different name. Keying the cache path by account id and repo id is unnecessary when there is one source directory that is deleted on any selection change (A and C both delete and re-clone). The id key solves a multi-source problem v1 does not have.

RC5. Agreed Q2, "overlay reads one prebuilt index, written temp+rename (A,B)": not agreed by C and not needed. The plugin is keepLoaded; building the index in memory from the checkout at load and after each successful refresh is one pass over hundreds of files [MK, unmeasured above ~2000 files, my Q9]. A JSON index on disk is a second copy that can disagree with the checkout. If A keeps it, the index must record the commit sha it was built from and be rebuilt when `rev-parse HEAD` differs.
