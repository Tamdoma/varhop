# Repo-format blind notes, slot B

These are proposals for Q1-Q4, not operator decisions. The shell-plugin lock remains closed. I read only Question/Carries in `forks/repo-format.md` and Taken in `forks/form-factor.md`, plus the intake and relevant external/local sources. I did not read another slot's notes for this fork.

Evidence tiers: O = operator material, P = named practitioner, S = primary documentation/source or inspected files, M = my inference. Every source below was read on 2026-10-12.

## Evidence used

- **E1, O:** `/home/ivan/Work/omarchy-customizations/varhop/issues/chart/varhop/INTAKE.md:17-20,31-34`: lightweight prompt retrieval, inline `{{VARIABLE}}` editing, standardized category/subcategory architecture. No serialization format, fixed depth or mandatory metadata was selected.
- **E2, O/S:** `/home/ivan/Work/omarchy-customizations/varhop/issues/chart/varhop/forks/form-factor.md:17-20` records the operator's shell-plugin choice. `slots/repo-format-brief-B.md:7` fixes parsing to QML/JS, without Node or Python.
- **E3, P with limited relevance:** Daniel Miessler, creator of Fabric, describes the workflow origins in [Why I Created Fabric](https://danielmiessler.com/blog/fabric-origin-story). His post does not recommend a serialization grammar or category depth. I did not treat the linked, unwatched interview as evidence.
- **E4, S:** [Fabric's custom-pattern instructions](https://github.com/danielmiessler/Fabric#custom-patterns) use `<pattern>/system.md`. The inspected [summarize/system.md](https://github.com/danielmiessler/Fabric/blob/main/data/patterns/summarize/system.md) is direct Markdown prompt text. This supports simple files as an authoring practice, not Fabric compatibility for varhop.
- **E5, S:** [VS Code prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files) use a dedicated `.github/prompts` location, `.prompt.md`, optional YAML metadata, and separate body instructions. Its documented input syntax is `${input:variableName}` with optional placeholder, not the operator's braces. Its model/tool fields belong to an execution environment.
- **E6, S:** [Espanso matches](https://espanso.org/docs/matches/basics/) distinguish literal and folded multiline YAML and use named `{{mytime}}` substitutions. [Espanso forms](https://espanso.org/docs/matches/forms/) keep field defaults/multiline configuration separate from the replacement text. These are precedents, not a request for its executable extensions or form UI.
- **E7, S:** [Hugo front matter](https://gohugo.io/content-management/front-matter/) accepts JSON, TOML and YAML. Front matter is not synonymous with YAML, and supporting several formats requires serialization/boundary handling.
- **E8, S:** [Qt QML JavaScript functions](https://doc.qt.io/qt-6/qtqml-javascript-functionlist.html#the-json-object) include JSON.parse/stringify. `/usr/share/omarchy/shell/services/PluginRegistry.qml:43-69,584-597` already parses JSON, validates its version/shape, and reports errors. `/usr/share/omarchy/shell/plugins/emojis/EmojiSearch.js:1-7` demonstrates JSON parsing too, but silently returns an empty array on failure. That error behavior should not be copied.

Practitioner-first research found no direct practitioner recommendation for this exact QML-only format. Searches included `site.github.com/danielmiessler/Fabric patterns system.md custom patterns directory`, `site.code.visualstudio.com docs copilot customization prompt-files frontmatter input variables`, `site.espanso.org docs matches basics multiline variables yaml`, and `site.gohugo.io content management front matter JSON YAML TOML`, followed by the primary pages/source above. The proposed contract below is M, grounded by those sources. None of them establishes a universal prompt-repository standard.

## Q1. Folder layout

**Pick, reason and cost:** One reserved `prompts/` tree. A prompt is `prompts/<category>/[<subcategory>/...]<slug>.md`, with at least one category and any further nesting. Each directory segment supplies grouping. Names remain the author's choice. Every regular `.md` file in this tree is a prompt, so put README and supporting documentation outside it. Root-relative path is identity within a revision. This keeps the requested architecture consistent without forcing filler subcategories or duplicating category fields. Cost: recursive discovery and displaying full category paths. Deep trees still impose a human navigation cost.

**Rejected options:** Exactly category/subcategory depth forces artificial buckets for simple prompts and blocks natural third-level grouping. All repository Markdown as prompts imports README/license/docs accidentally. A completely flat namespace loses requested grouping. Metadata-owned categories duplicate physical paths or require an explicit precedence rule. Fabric's directory-per-prompt adds another directory level and an irrelevant system/user role split for this copy-one-prompt job.

**Evidence:** O E1, S E4-E5, all read 2026-10-12. Dedicated discovery roots are an observed practice. Arbitrary depth is my choice, not a practitioner rule.

**Pitfalls and removal:** R1, mistaken documentation imports: use the reserved root and exact candidate extension. R2, same slug in different categories: identify by complete relative path and expose the category in search results. R3, symlinks/path escape or unbounded enumeration: accept regular files under the selected root, reject symlink candidates, and enforce separately agreed import size/count bounds. R4, directory rename plus metadata orphan: move a prompt and its companion file in the same repository change and validate pairing.

**Question the fork does not ask:** X1, can the operator show a representative current repo/export tree before this structure is locked? Existing authored content may make the migration cost larger than the loader cost. Import conversion is not automatically part of this task.

## Q2. Metadata and front matter

**Pick, reason and cost:** Keep the Markdown file entirely prompt body. Put optional metadata in the same-directory sibling `<slug>.meta.json`. Use one native JSON parser, then explicit schema validation. This replaces my opening map's YAML front-matter preference after accounting for the locked runtime. Supported optional fields are `title` (nonblank string), `description` (string), `tags` (array of nonblank strings), and `variables` (array of records described in Q3). Missing title has the documented default of the filename stem with hyphen/underscore separators replaced by spaces. Categories come only from paths. No required id, model, tool, author or timestamp fields are justified by the present copy/search job. Cost: two files when metadata is needed, JSON punctuation and escaped newlines in defaults, and paired renames. For an operator/team, ordinary Git diffs and editor JSON validation help, while optional metadata keeps a basic prompt to one readable file.

**Rejected options:** Full YAML front matter offers familiar authoring and good multiline defaults, but adds a parser dependency and its QML compatibility/maintenance proof. Node-oriented package availability alone is not that proof. A handwritten YAML subset is worse: ordinary YAML-looking files invite unsupported quoting, lists, block scalars and aliases. JSON/TOML front matter retains metadata boundary parsing and reserves otherwise legitimate body openings. A central metadata catalog creates shared merge conflicts and duplicate file listings. Pure text with no metadata cannot provide the requested optional defaults/hints or useful search descriptions. Putting the entire prompt in JSON makes every body edit pay string escaping.

**Evidence:** O E1, S E4-E8, read 2026-10-12. Native JSON support is inspected/documented. The sidecar arrangement and maintenance comparison are M, not a claim that these tools use this exact layout.

**Pitfalls and removal:** R5, unsupported/typo metadata silently disappearing: validate types and allowed field names, report path plus field/error, and do not coerce values. R6, YAML header being mistaken for varhop metadata: v1 has no front-matter interpretation. A `---` block in `.md` remains body text and is copied as such. Existing front-matter libraries require deliberate conversion. R7, orphan sidecar: reject `<slug>.meta.json` without its matching prompt. R8, misleading stability: a filename move changes path identity. An open draft keeps its captured body, and persistent cross-rename identity should be added only if another settled requirement actually needs it.

**Question the fork does not ask:** X2, will authors edit plain Markdown and occasional JSON in GitHub/editor, or do they already depend on YAML-aware prompt tooling? That authoring constraint could justify choosing YAML and paying for a proven parser instead.

## Q3. Variables, literals, defaults and hints

**Pick, reason and cost:** A variable token is exactly `{{NAME}}`, where NAME matches `[A-Za-z_][A-Za-z0-9_]*`. Names are case-sensitive. Uppercase is a suggested convention, not an extra requirement inferred from the operator's example. No spaces, defaults, expressions, nesting or filters inside tokens. Parse the original body once into literal spans and named slots. Repeated names share a value provisionally, and occurrences retain original body order. How the editor selects/updates linked ranges stays with the variable-editing fork.

Escape a literal opener as `\{{`. Define runs of backslashes immediately before `{{`: each pair emits one backslash, and an odd remaining backslash makes that opener literal. Thus `\{{NAME}}` emits literal `{{NAME}}`, while `\\{{NAME}}` emits one backslash followed by the slot's value. Backslashes elsewhere are unchanged. An unescaped `{{` must form a valid token or produce a source-position error. This makes typos visible and gives authors one exact escape rule, at the cost of escaping template examples even in code fences. Markdown syntax does not disable variable recognition.

Each metadata variable record has required `name` and optional string `default` and `description`. Names in this array must be unique and correspond to real body slots. Body slots need no metadata record. A missing default is unresolved, while explicit `""` is a provided empty default. Defaults and pasted values may contain newlines, braces and arbitrary Unicode. They are inserted once as literal strings, never interpreted as further variables. Hints are shown in the UI and never copied into output.

**Rejected options:** Inline `{{NAME:default}}` or pipe hints collide with prompt prose and require more escaping/grammar. Whitespace/name coercion hides spelling errors. A full Mustache/Jinja/Liquid or Espanso-like evaluator adds includes, control flow or execution to a text-copy app. Treating malformed openers as ordinary text conceals broken placeholders. Separate values for repeated identical names make one name ambiguous. Demanding metadata declarations for every token duplicates body information and adds author work.

**Evidence:** O E1, S E5-E6, read 2026-10-12. These establish operator syntax and real precedents for separating values/configuration. Identifier grammar, escape parity and nonrecursive substitution are M proposals. The searches above found no source establishing them as an existing shared standard.

**Pitfalls and removal:** R9, brace-containing replacement becoming executable/new input: render parsed original spans once, without reparsing inserted values. R10, stale or duplicate variable metadata: validate record uniqueness and its relationship to parsed slots. R11, accidental output changes: keep body whitespace/newlines intact except declared escape/substitution operations. R12, secret defaults entering Git: defaults are committed reusable text, never a store for fetched private values. R13, implicit empty/unresolved conflation: represent those as different permitted states, leaving copy policy to its own fork.

**Question the fork does not ask:** X3, does the library contain prompts that teach another `{{...}}` template language, and does repeating one name always mean one shared value? Test the proposed escaping and linked-name choice against those actual prompts before locking them.

## Q4. Version marker and strictness

**Pick, reason and cost:** Require root `varhop.json` containing exactly `{"schemaVersion":1}`. Fixed v1 conventions determine the prompt root, metadata pairing and variable grammar. This is a small format marker, not an enumerated catalog or configurable loader. Reject missing/unsupported markers explicitly rather than guessing a version. Cost: one additional file for authors. Benefit: the parser knows which interpretation was requested and an older client cannot silently reinterpret a newer grammar.

Use strict syntax/schema validation on candidates discovered by the stated rules. Missing optional metadata and documented defaults are valid states, not recovery from malformed data. Gather actionable errors for invalid body/metadata/pairing and reject publication of an invalid candidate revision as a whole. Cost: one teammate's bad edit holds the update, while a lenient loader may offer part of it sooner. That trade is preferable to hidden omissions or mixed interpretations. Availability/status of a previously imported library belongs to the sync contract. Do not build a second permissive parser, auto-repair files or add Fabric/Copilot import adapters here.

**Rejected options:** No marker makes later incompatible changes indistinguishable from mistakes. Optional marker plus guessed v1 creates two acceptance paths without an established compatibility need. Per-file versions allow a mixed-format repository and repeated author work. A manifest listing every prompt duplicates the discovery tree and becomes a team merge hotspot. Ignoring unknown fields or loading only valid files hides typos/omissions unless a separate partial-library product contract is designed. Strict validation of unrelated README/license files mistakes the prompt discovery boundary for a whole-repository ban.

**Evidence:** O E1-E2, S E8, read 2026-10-12. Omarchy's plugin manifest demonstrates explicit version/shape validation, but does not dictate varhop's format or whole-revision publication. Those choices are M. This marker describes prompt data and is separate from the plugin's own manifest/version.

**Pitfalls and removal:** R14, new metadata accepted differently by old clients: reject unsupported schema versions and unknown v1 fields. R15, author mistakes causing opaque failures: report each relevant path/field and source position where available. R16, overclaiming strict JSON: JSON.parse validates syntax, not duplicate object-property spelling. Do not claim duplicate-key rejection without a proven additional mechanism. Use unique variable-name records in the array for the semantic duplicates that matter here. The JSON object parser's duplicate-property behavior must be stated in the finalized format contract rather than left to implementer guesswork.

**Question the fork does not ask:** X4, should one invalid prompt hold the entire imported update, as proposed, or should authors accept an explicitly incomplete library with listed exclusions? This is a real availability choice for a team. X5, what actual library size bounds must import accept without blocking the shell? Both belong in the final loader contract before implementation.

## Concrete proposed repository

```text
varhop.json                         {"schemaVersion":1}
README.md                           author documentation, outside prompt discovery
prompts/
  writing/
    review.md                       prompt body only
    review.meta.json                optional metadata
  engineering/
    reviews/
      security.md
```

Example `review.md`:

```text
Review this text in a {{TONE}} tone:
{{TEXT}}
Keep the same {{TONE}} tone throughout.
For this example, write the literal token \{{EXAMPLE}}.
```

Example `review.meta.json`:

```json
{
  "title": "Review a draft",
  "description": "Review pasted text with a chosen tone",
  "tags": ["editing"],
  "variables": [
    {"name": "TONE", "default": "Direct", "description": "Desired tone"},
    {"name": "TEXT", "description": "Paste the text to review"}
  ]
}
```

The main recommendation is a narrow, explicit v1 contract: plain Markdown bodies, optional JSON metadata, one version marker, and literal slot substitution. It trades familiar YAML authoring for less parser machinery in the locked runtime.
