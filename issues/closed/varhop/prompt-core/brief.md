# Brief: prompt-core

## What
ES modules under `lib/` (`.mjs`, no Node, Bun or browser APIs) exporting pure functions:
- **Import:** take `[{path, text}]` (repo-relative paths, text already validated as UTF-8 by repo-sync) and return prompts plus per-file errors. This applies the repo-format path rules and the front-matter rules, and precomputes each prompt's folded search fields. (A,C)
- **Tokens:** split a body into text and token segments, and list the unique token names in first-appearance order. An escaped `\{{NAME}}` becomes a text segment holding the literal `{{NAME}}`. (A,C)
- **Rebuild:** turn segments plus values into the copy string. Unset names copy as `{{NAME}}`, and the unset names are returned.
- **Search:** folding, field scoring, scored subsequence matching, ranking with the body tier, and empty-query ordering. (A,C)
- **Usage:** decayed copy-frecency update and score as pure functions over a passed `UsageState`. (A,B)

The same files load unchanged in bun tests and in Qt 6.12's QML engine (`import "lib/x.mjs" as X`).

## Why
overlay-plugin needs one tested home for every text rule the forks locked. Keeping it pure lets each rule be proven with cheap tests instead of a live shell.

## Done-criteria
1. Each front-matter fixture listed in the design yields the recorded title, description, tags, body text and errors with line numbers, as the blocking `test` check shows. The fixtures are: the thematic break; the YAML example body; unclosed `---`; a title with `: ` and `#`; `description: |`; BOM plus a CRLF header with leading blank lines and no final newline; a BOM without a header; the empty-header escape; a duplicate title; mixed-type tags; indentless block tags.
2. Path rules hold. `prompts/<category>/<name>.md` and `prompts/<category>/<subcategory>/<name>.md` import with category and subcategory. A missing `title` defaults to the file stem, the file name without `.md`, unchanged. A deeper file is left out of `prompts` and gets an error entry with `line: null`. Non-`.md` files and anything outside `prompts/` are ignored. The prompt id is the path. (A,C)
3. The token grammar holds for: `{{[A-Z0-9_]+}}`; `{{{NAME}}}` as `{` + token + `}`; a token inside a code fence counts; a backslash is removed only before a valid token, and `\{{NAME}}` yields a text segment `{{NAME}}` that is not a variable; lowercase or invalid braces stay literal. Unique names come out in first-appearance order. (A,B,C)
4. Rebuild with no values set reproduces the body exactly, except that each `\{{NAME}}` escape comes out as `{{NAME}}`. This holds for a CRLF body with no final newline and for a body containing an escape, and every name is reported as unset. With values set, every occurrence of a name gets its value. A value containing `{{OTHER}}` is inserted literally. (A,B,C)
5. Search ranks the design's fixtures as recorded:
   - Folding makes `Đorđe` match `dorde` and `č` match `c`.
   - Terms are ANDed. Field weights run title > file name > tags > category/subcategory > description.
   - Scored subsequence matching in the fzf V1 shape: `cdr` ranks "Code Review" above a title that matches only with scattered letters, and `cdoe` matches nothing (no typo tolerance). (A,C)
   - The body substring tier applies only to terms of 3+ characters, only when structured matches are fewer than the display chunk (50 rows), and is ranked below every structured match. A body-only hit returns a one-line snippet around the first matched term. (A,C)
   - Frecency reorders only within equal relevance. The empty query returns up to 10 recent copies, then all prompts by category.
6. Usage math holds on fixtures: `recordCopy` on an empty state, a repeat copy one half-life later, and `resetUsage` produce the recorded `UsageState` values. (A,B)
7. Every exported module loads in `/usr/lib/qt6/bin/qml` with `QT_QPA_PLATFORM=offscreen`, and a smoke call of each export exits 0. This runs inside the blocking `test` check.
