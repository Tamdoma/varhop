# Search: rebuttal, slot B

Read 2026-10-12. Recommendations below do not settle operator choices.

- **D-a. Body search.** Keep metadata-only search unless the operator chooses remembered-body-phrase lookup. A/C's substring proposal avoids scattered-letter matches, but precomputing folded bodies does not remove per-query scanning or duplicated memory. C's “few MB at most” is unsupported because repo-format Taken permits arbitrary bodies without a size bound. Installed `ClipboardHistory.js:160-187` actually caps searched text at 8192 characters, contradicting C's full-text precedent. C's P4 also makes body-hit availability depend on how many unrelated structured matches exist. If body search is chosen, disclose that restriction and prove long-body performance.
  Concede: substring body lookup can find remembered words absent from metadata.

- **D-b. Usage.** Keep no usage store in v1. Evidence: the intake asks for fast lookup but does not require learning. A's P3 silently resets corrupt usage data, contrary to the supplied error-handling rules. If usage is chosen, C's count/recency-before-fine-score ordering is not merely a tie-break between equal text scores. [Raycast's documented order](https://manual.raycast.com/search-bar#how-ranking-works) puts title fuzzy score before frequency/recency. Finish text relevance first, then use usage, with explicit repository scope and visible storage errors.
  Concede: recent successful copies shorten repeat lookup on an empty query.

- **D-c. Secondary row text.** Show category path and optional description, adding filename when the effective title does not identify the file. The merged split misses C's Q1 P2, which already proposes filename display for duplicate front-matter titles. Evidence: repo-format permits duplicate titles in one category, so category plus title alone cannot distinguish them. A body snippet is conditional on choosing D-a's body-search option, not an agreed row requirement.
  Concede: omit a redundant filename when the displayed title already supplies it.

- **D-d. Rendering.** Prefer ListView over the complete ranked array and measure model-update cost before adding chunk-extension state. [Qt ListView](https://doc.qt.io/qt-6/qml-qtquick-listview.html) creates delegates as needed. C correctly identifies the separate cost of clearing/appending thousands of ListModel records, but B did not require that implementation. The clipboard's 50-row cap does not prove chunking is necessary for varhop.
  Concede: chunks are acceptable if real-shell measurements justify them and every match remains reachable, including across arrow wrap and refresh.

- **F1. Refresh attribution.** The merged “same id, else top” rule is supported by A/B, not C's Q4 as written. C instead clamps to the old index when the id disappears. Keep first result or no selection: an obsolete index has no connection to user intent. Cite a recorded C concession before tagging the fallback unanimous.

- **Resume.** Keep an explicit Resume action independent of results. Evidence: copy-and-close retains a draft while search is shown, and sync leaves its source unchanged. Filtering or deleting that prompt can remove its only row without ending the draft. Resume must reach the retained source/values/cursor directly, not reopen the newest imported version. This completes the existing retained-draft workflow without another draft store.
