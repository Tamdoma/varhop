# Search: blind notes, slot B

Read 2026-10-12. These are recommendations, not operator decisions. Read the supplied Question/Carries, intake and all five Taken sections. Other slots' search notes were not read. Existing parser, draft, clipboard, Escape and manual-sync decisions stay locked.

## Evidence

- **E1. Operator.** `issues/chart/varhop/INTAKE.md:14-21,26-33` asks for quick lookup, suggestions below the focused search box and arrow selection. `forks/repo-format.md` Taken makes title/description/tags optional and preserves arbitrary Markdown bodies. `forks/search.md` Carries fixes path identity. `forks/copy-and-close.md:25-26` fixes search Escape, native selection copy and retained drafts. Read 2026-10-12.
- **E2. Better-than-training, installed source.** `/usr/share/omarchy/shell/plugins/emojis/EmojiSearch.js:10-35` lowercases and searches one contiguous substring, preserving source order and stopping at a limit. `plugins/clipboard/ClipboardHistory.js:160-202` searches only an 8192-character preview with a substring and returns at most 50 entries. `plugins/menu/MenuModel.js:290-362` requires every whitespace-separated term, ranks exact labels before prefixes, substrings and descriptions, and uses menu depth/order. These are distinct policies, not one reusable general fuzzy engine. Inspected 2026-10-12.
- **E3. Better-than-training, installed source and measurement.** `services/AppSearch.js:26-94` uses substrings plus short acronyms, not arbitrary subsequences. Its word splitter is ASCII-only; `:112-118` uses name sorting after score. No general fuzzy helper was found in Commons/Ui; `Ui/SearchableDropdown.qml:74-84` uses label/description substrings. In a headless Qt 6.12.0 QJSEngine, the installed AppSearch gave `Code Review` scores `cr=4995`, `cdr=-1`, `code rev=9989`. Installed fzf 0.74.5 with `--filter=cdr --no-sort` accepted both `Code Review` and `Calendar`, illustrating subsequence matching and why gap ranking matters. Synthetic inputs only, inspected/measured 2026-10-12.
- **E4. Better-than-training, installed interaction source.** `plugins/clipboard/Clipboard.qml:160-185,366-388` wraps arrow navigation, resets selection on query changes, scrolls to selection and handles Enter. Its inactive cursor can make the first Enter only select. `plugins/menu/Menu.qml:170-207,714-746` constrains height and reveals selected rows. `:1441-1471,1506-1523` renders plain-text label/detail and supports pointer selection/click. `Ui/PointerMoveGate.qml:3-7,18-52` removes selection changes caused by delegates moving beneath a stationary pointer. `Ui/SearchableDropdown.qml:206-235` supplies a native TextField and direct first-result Enter. Inspected 2026-10-12.
- **E5. Practitioner and primary code.** Junegunn Choi's [fzf algorithm source](https://raw.githubusercontent.com/junegunn/fzf/master/src/algo/algo.go), lines 7-70, explains linear forward/backward V1 matching versus optimal O(nm) V2, with boundary/consecutive bonuses and gap penalties. Neither allows missing or mismatched query characters. Jon Skinner's [Sublime Goto Anything announcement](https://www.sublimetext.com/blog/articles/sublime-text-2-public-alpha), dated 2011-01-28, describes typed filename fragments and a selectable preview list. This is historical product evidence, not a QML performance result. Read 2026-10-12.
- **E6. Better-than-training, primary sources.** [VS Code quick navigation](https://code.visualstudio.com/docs/editing/editingevolved#_quick-file-navigation) documents filename Quick Open. Its [fuzzy scorer](https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/base/common/fuzzyScorer.ts), lines 468-476,596-649, prioritizes label prefixes and label matches over label-plus-description, then compactness. [Quick Open implementation](https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/contrib/search/browser/anythingQuickAccess.ts), lines 347-376, includes editor history separately. Read 2026-10-12.
- **E7. Better-than-training, primary product documentation.** [Raycast Search Bar](https://manual.raycast.com/search-bar#how-ranking-works) describes title relevance before subtitle/keywords and then frequency/recency, with learned ranking reset. [Alfred ordering](https://www.alfredapp.com/help/kb/understanding-result-ordering/) describes a four-week usage window and query-specific learning. [Alfred default results](https://www.alfredapp.com/help/features/default-results/) explicitly warns that extra metadata keywords can make matches noisy. Read 2026-10-12.
- **E8. Better-than-training, primary Fuse source.** The documentation pages at fusejs.io could not be retrieved. Inspected the maintained source instead: [defaults](https://raw.githubusercontent.com/krisk/Fuse/main/src/core/config.ts), lines 8-34, set diacritic folding off, location 0, distance 100 and threshold 0.6; [Bitap matcher](https://raw.githubusercontent.com/krisk/Fuse/main/src/search/bitap/search.ts), lines 31-38,72-112, scores errors and position; [field aggregation](https://raw.githubusercontent.com/krisk/Fuse/main/src/core/computeScore.ts) combines match score, key weight and field-length normalization. Fuse's error-tolerant matching is different from fzf subsequences. Read 2026-10-12.
- **E9. Better-than-training, specification and runtime measurement.** [ECMAScript normalize](https://tc39.es/ecma262/multipage/text-processing.html#sec-string.prototype.normalize) defines canonical NFD decomposition; [Qt's JS environment](https://doc.qt.io/qt-6/qtqml-javascript-hostenvironment.html) implements ECMAScript built-ins. A read-only PySide6 QJSEngine probe using the installed Qt 6.12.0 evaluated NFD, removal of U+0300-U+036F marks, lowercase and explicit `đ` to `d`. `Č Ć Ž Š Đ č ć ž š đ é é` became `c c z s d c c z s d e e`. NFD alone left `đ` unchanged. No file or desktop state was changed. Measured 2026-10-12.
- **E10. Better-than-training, primary Qt documentation.** [ListView](https://doc.qt.io/qt-6/qml-qtquick-listview.html) supports scrolling and creates delegates as needed. [TextInput](https://doc.qt.io/qt-6/qml-qtquick-textinput.html) supplies native selection, copy/paste and input-method state. Source inspection establishes available machinery, not a working varhop interface. Read 2026-10-12.

Practitioner synthesis: Choi separates fast subsequence lookup from expensive optimal scoring, while Skinner demonstrates the usefulness of a selectable list. VS Code keeps labels prominent. Raycast and Alfred show that learned ranking can shorten repeat searches but introduces stored history and changing order. For a new, authored prompt library, I recommend metadata relevance first, deterministic order and no usage store in v1. This deliberately gives up their learned shortcuts. Reconsider that choice if repeated ambiguous queries become the actual bottleneck.

## Q1. Search fields and weight

### Pick, reason and cost

**D1. Search title, filename without `.md`, tags, category, subcategory and description. Do not search body text in v1.** When title is omitted, the importer supplies the locked filename default. Require every whitespace-separated query term to match at least one field; terms can match different fields. Do not allow one term to span unrelated fields or tags by concatenating them into a synthetic word.

Use ordered priorities rather than an unbounded sum of occurrences: exact full title, then full-title prefix, then other matches. For the remaining matches, prefer exact word/prefix matches, then contiguous substrings, then subsequences. At equal match quality, field priority is title, filename, tags, category/subcategory equally, then description. Each term contributes its best match once. Compare weakest term quality, total term quality, field priority, then compactness/earlier position; finish with folded title and original path id for deterministic ties. Numeric implementation constants must preserve those priorities.

Reason: names and metadata describe what the prompt does. Arbitrary long bodies invite weak scattered-letter hits and per-keystroke work unrelated to prompt count. Cost: a phrase appearing only in the body is not discoverable. The operator can place its lookup words in the optional description/tags without changing body fidelity. This search restriction is a proposed choice, not an importer restriction.

### Rejected options

- **O1. Title only.** Misses filename lookup when a title differs, and wastes useful existing categories/tags.
- **O2. All fields including body with equal weight.** Repeated boilerplate and long content compete with useful names. Full-body fuzzy matching particularly rewards accidental subsequences.
- **O3. Raw match counts or one concatenated metadata string.** Rewards duplicated tags and can invent matches across field boundaries.

### Evidence

E1 operator; E2/E6-E8 inspected primary sources, read 2026-10-12. The field priorities are my proposed contract, not a claim that another product uses these exact weights.

### Pitfalls and removal

**R1. Optional metadata makes a prompt disappear.** Build the search record from importer output, retaining filename/category even when metadata is absent or has a reported parse error. Test omitted title, duplicate titles, duplicate tags and an explicit title different from filename. **R2. Normalization changes exported content.** Store folded search keys separately from original source and displayed metadata. Never write them back to the prompt or values.

### Question not asked

**Q5. Must a remembered phrase from the body find its prompt?** Recommend no for v1. If that is a real required workflow, settle full-body search explicitly, including its match rule and large-body performance proof, rather than quietly scanning only a prefix.

## Q2. Matching and suggestions

### Pick, reason and cost

**D2. Case-insensitive ordered subsequence matching on metadata, with stronger contiguous/word-start matches ranked first. No typo substitution or transposition. Show a ranked list below the unchanged native input, with its first result selected. No inline completion.** `cdr` can find `Code Review`; `reveiw` need not find `review`. Whitespace separates AND terms; no regex, quotes, exclusion operators or special query language. Punctuation in each term is literal.

Precompute folded field strings at import. Apply the same NFD/Latin combining-mark removal/lowercase/explicit `đ→d` folding to queries, including uppercase Đ after lowercase. This covers the requested Croatian letters and composed/decomposed accents. `dj` is not an extra alias for `đ`. Preserve other scripts and punctuation. Record boundaries from original text before lowercase, including camel-case transitions and separators, if used for ranking.

Use a small pure QML-JS matcher with linear forward scan and backward compaction, inspired by fzf V1. Prefer boundaries, consecutive characters and shorter gaps. Do not spawn fzf per keystroke. Reason: supports abbreviations while keeping work tied to short metadata. Cost: greedy matching need not choose the optimal occurrence, and typing mistakes require correction. Its scoring is not claimed to reproduce fzf exactly.

### Rejected options

- **O4. Prefix/substring only or unchanged AppSearch reuse.** Misses arbitrary ordered abbreviations. The installed helper is desktop-entry-specific, ASCII-oriented and failed the `cdr` probe.
- **O5. Port full fzf V2 or VS Code scoring.** Their optimal matrices and supporting machinery add work beyond the needed small matcher. V1's known ranking limitation is acceptable only with representative examples checked.
- **O6. Fuse.js by default.** Adds an imported library, approximate-error policy, tuning and QML compatibility work. Default location weighting and disabled accent folding also need deliberate changes. It is viable if typo tolerance becomes a requirement, not equivalent to the proposed subsequence behavior.
- **O7. Inline replacement/completion.** Changes or obscures the query and adds an acceptance gesture. The intake asks for suggestions below the box, which a list supplies.

### Evidence

E1 operator; E3/E9 installed measurements; E5-E6/E8 primary algorithms, read 2026-10-12. The probes establish matching and folding behavior only.

### Pitfalls and removal

**R3. QML blocks while searching.** Cache normalized metadata once, score once per committed query change, and sort scores without rescanning strings in the comparator. Use ListView instead of instantiating every row. Leaf proof must measure query-to-list update in real Quickshell with 500, 2000 and 5000 records, short broad queries, multi-term queries and long metadata. Proposed target: p95 at most 50 ms at 5000 representative records, not a measured result. Body size must not affect search time. A miss requires fixing the chosen matcher/model, not hiding it with a debounce or dropping results.

**R4. Folding breaks highlights or input methods.** Keep original strings and use a native text input. Score committed text while composition is active; let the input method consume its confirmation keys before opening a result. Avoid normalized-index highlighting in v1, since decomposition changes offsets. Test accents, Đ/đ, decomposed marks, Cyrillic, emoji and literal `C++`.

### Question not asked

**Q6. Is typo correction required, or are skipped-letter abbreviations enough?** Recommend abbreviations only, making the cost explicit. Those are separate matching guarantees.

## Q3. Usage, categories and empty query

### Pick, reason and cost

**D3. No frequency, recency, query-learning or usage store in v1.** Non-empty results rank by D1/D2 globally, without category sections overriding relevance. Empty or whitespace-only query shows the complete library ordered by folded category, subcategory, title, then original path id. Rows display their category path; no extra category navigation is required. With no prompts, show the library's actual empty/import state instead of an empty suggestion panel.

Reason: stable ordering and no new state file, write events or identity migration. Empty-query browsing remains possible before typing. Cost: repeated ambiguous searches do not learn which prompt the user usually wants, and a daily prompt can require typing its name each time.

### Rejected options

- **O8. Learned recency/frequency ranking.** Useful in Raycast/Alfred, but changes ordering and requires a definition of use, storage scope and retention. Opening a prompt to inspect it and successfully copying it are different events.
- **O9. Recent-only empty query or no results until typing.** Conceals unused prompts and gives a new library little to browse.
- **O10. Category grouping ahead of relevance for typed queries.** Buries a stronger match under unrelated rows in an earlier category. Show the path without imposing that hierarchy on search.

### Evidence

E1 local-clone/operator scope; E2-E3 installed alphabetical/source-order precedents; E7 learned-ranking comparison, read 2026-10-12. My recommendation deliberately declines the product benefits documented by Raycast/Alfred.

### Pitfalls and removal

**R5. Order changes between identical queries.** Use a total comparator with original path id as the final tie-break, independent of filesystem enumeration and locale. Do not use category grouping for non-empty queries. **R6. A later usage choice writes to shell.json.** If the operator chooses usage, its fork must define the event, repository identity, deletion/rename behavior and a state-dir file before implementation. Do not smuggle that store into this no-usage recommendation.

### Question not asked

**Q7. If usage is chosen, what counts as use?** Recommend successful whole-prompt copy, not selection/open/resume. Store only prompt identity and count/time, no query or substituted body. This is an alternative contract requiring a decision, not additional work under D3.

## Q4. Rows, keyboard and refresh selection

### Pick, reason and cost

**D4. A compact scrollable list, with up to six complete rows visible and more reachable by scrolling/keys.** Fit fewer rows on a small monitor rather than clipping the search field. Keep all matches navigable, not just six total. Each row shows title, category/subcategory plus filename to disambiguate duplicate titles, optional one-line description, and a small Draft indicator for the retained draft. Metadata is plain text, elided rather than interpreted as Markdown/HTML. No body preview or tag-chip wall.

Keep keyboard focus in the native search field. A fresh/query-edited result list selects its first row immediately. Up/Down moves one row and wraps, following clipboard precedent. Enter opens the highlighted row on the first press. Mouse movement can change the highlight after passing the existing pointer gate; clicking opens the clicked prompt. Ordinary caret movement, paste and selected-query copy remain native. Locked search Escape clears a non-empty query, then hides on empty. Do not carry the first-party overlays' hand-built `event.text` filter into this native input.

On successful manual pull, rerank the same query and retain the selected prompt by original path id if still present in those results, then reveal it. If removed or no longer matching, select the first result, or no selection when empty. Query edits reset to the best result instead of retaining an unrelated low-ranked selection. The old list remains usable while the new import is pending or fails. No automatic pull is introduced.

A Draft marker is presentation of the existing retained draft. Activating its row resumes that draft's original source/values/cursor, even after library refresh. An independent Resume action remains available if that path has disappeared or is filtered out. Choosing another prompt performs the already settled replacement. Search does not recreate a retained draft from the newest import.

Reason: fast keyboard activation, visible duplicate identity and no stale-index activation after refresh. Cost: descriptions and path information consume row height, scrolling is needed beyond six, and preserving a selection after pull can leave a lower-ranked row highlighted.

### Rejected options

- **O11. Title-only rows or category headings among selectable rows.** Duplicate titles become ambiguous; headings complicate navigation. The path supplies context directly.
- **O12. Render/cap the entire result list to six or fifty.** A visual height limit is not a search-result limit. Weak queries must still reach all matches.
- **O13. Preserve numeric index on refresh.** New ordering can make Enter open another prompt. Identity preservation avoids that class of mistake.
- **O14. Mouse hover always owns selection or first Enter merely selects.** A stationary pointer can undo keyboard movement, and a hidden extra Enter slows the primary workflow. Gate actual movement and preselect the first result.

### Evidence

E1 operator and locked carries; E4 installed row/navigation code; E10 Qt machinery, read 2026-10-12. Six visible rows is a proposed layout choice, not an installed constant or an operator decision.

### Pitfalls and removal

**R7. Refresh and activation target different prompts.** Publish the imported search index as one generation and resolve selection by id, not prior array position. Test reordering, deletion, changed metadata, zero matches, failed pull and Enter immediately after publication. **R8. Returning through search resets gathered values.** Keep retained draft ownership outside rows/delegates. Test same-id resume after changed source, deleted source, query filtering and selecting a different prompt. **R9. Keyboard selection is stolen by pointer churn.** Reuse PointerMoveGate, reset it on query/list/keyboard mutations, and prove Enter still activates the keyboard-selected id with the mouse stationary over another row.

### Question not asked

**Q8. How does a retained draft remain reachable when its source disappears or does not match the query?** Recommend an explicit Resume action independent of the result list, without forcing its row into unrelated search results. Its shortcut belongs to settings-and-hotkey, alongside the already owed Find another prompt action.

## Limits

Only this return file was written. Research used installed source, primary documentation and synthetic in-memory/headless matcher probes. No other search notes, clipboard contents, user prompt bodies, desktop settings or history were read. No clipboard write, UI interaction, shell reload, theme change or live pull was performed. The proposed search implementation, UI behavior and latency remain pending leaf proofs.
