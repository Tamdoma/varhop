# Picker fork notes, slot C (blind), 2026-10-13

The fork's one question splits into four the operator must answer. Ground
facts used throughout: the field today only fires on Return with the exact
trimmed text (worktree qml/SettingsBody.qml:209-212) and the list is an
unfiltered Repeater over `root.repos` (SettingsBody.qml:219-235). This
machine's `/user/repos` returns 161 repositories across many owners
(`gh api '/user/repos?per_page=100' --paginate`, counted 2026-10-13), so
the unfiltered list is not a toy. Choosing a repo is not a harmless
selection: `chooseRepo` starts a sync and save, and with a draft it routes
through the discard warning (worktree Varhop.qml:328-338).

## S1. Match rule and ordering

### Pick
Case-insensitive substring on the full `owner/repo` string, one term (the
trimmed field text), over a list sorted alphabetically by fullName once
when it arrives. Filtering never reorders. An exact full-string match
(case-insensitive) outranks position only through Enter resolution in S2,
not by moving rows.

Repo names are exact identifiers the user already knows, drawn from a
161-item list where typing an owner prefix or a few name letters narrows
to a handful. Substring is also what Omarchy's own summoned picker does
(EmojiSearch.js filterEmojis is a lowercased indexOf) and what the prompt
search does *not* do, deliberately: prompts are discovered by relevance,
repos are recalled by name. Alphabetical stability means rows never jump
while typing, so the highlighted row the user is reading stays the row
Enter will take. Cost: typo'd or abbreviated queries like "vprompts" find
nothing where a subsequence scorer would. Accepted, because the typed
path in S2 still accepts any exact owner/repo, listed or not.

### Rejected options
- Subsequence scoring (fzf-style, or reuse lib/search.mjs rank). fzf and
  VS Code quick pick rank by match quality, which earns its keep over
  thousands of files with unknown names. Here it makes row order a
  function of the query, so the top row changes identity mid-typing, the
  riskiest property a list whose Enter triggers a repo switch can have.
  rank() also scores prompt-shaped records with usage, wrong inputs for
  repos.
- Prefix-only match. Fails the common recall "prompts" or "prompts-b"
  where the owner is forgotten, and forces typing "Tamdoma/" first.
- Keep GitHub's API order. `/user/repos` without sort returns
  created-descending (GitHub REST docs, sort default created), an order
  no human can predict or scan. varhop-sync passes no sort today
  (bin/varhop-sync repos), so client-side alphabetical sorting is a view
  change only, no sync contract change.

### Evidence
- practitioner · Omarchy maintainers' EmojiSearch.js (filterEmojis:
  normalizedQuery plus indexOf, order preserved), read 2026-10-13 · the
  first-party summoned-picker filter is plain substring.
- practitioner · fzf manual (local fzf 0.74.5 man page, fuzzy matching
  v2 default, --exact option) and VS Code quick pick UX guidelines
  (code.visualstudio.com/api/ux-guidelines/quick-picks), read
  2026-10-13 · ranked fuzzy is the file-picker convention, with exact
  mode as the escape. Bounds what is being declined and why.
- better-than-training · GitHub REST docs, list repositories for the
  authenticated user, read 2026-10-13 · the endpoint lists repos the user
  has explicit permission to access: owned, collaborator, and through
  organization membership; sort defaults to created.
- better-than-training · `gh api` count above and worktree
  bin/varhop-sync:86-89 · 161 accessible repos today, `per_page=100
  --paginate`, jq keeps fullName, id, private only. No pushed-at field
  exists for recency sorting even if wanted.

### Pitfalls and what removes each
- Owner/name asymmetry: "varhop" matches three Tamdoma repos and the top
  alphabetical row is `Tamdoma/varhop`, not the prompts repos. Removed by
  S2's rules, never by silent ranking: the highlight is visible before
  Enter, and exact typed text wins at Enter.
- Filtering on every keystroke over a model rebuilt in root could rerun
  root work. Removed by filtering inside SettingsBody from the `repos`
  prop and the field text only; `root.repos` changes only on refresh.
- A query with a trailing slash or spaces ("Tamdoma / x") matches
  nothing and reads as "repo missing". Removed by trimming, and by S2's
  zero-match text naming the typed path instead of a bare "no results".

### Questions the fork does not ask
- Case: GitHub fullNames are case-insensitive but case-preserving. Does
  Enter on typed text send the typed casing or the API's canonical
  fullName from the lookup result? (repoTyped already returns the API's
  fullName, so canonical wins today; state it.)
- Multi-term queries ("tamdoma prompts" with a space) — split on spaces
  and slash, or one literal term? One term can never match across the
  slash with a space in it.

## S2. What Enter does: zero, one, many matches, typed but unlisted

### Pick
Enter resolves in this order, first hit wins, and always through the
existing signals (`repoChosen` for a listed row, `repoTyped` for the
lookup path):
1. Trimmed text exactly equals a listed fullName, ignoring case: choose
   that repo.
2. Else, if a row is highlighted (S3): choose the highlighted row.
3. Else, if the text matches the strict owner/repo regex the root
   already enforces (Varhop.qml:308): run the typed lookup
   (`varhop-sync repo`), which chooses on success and shows
   "repo lookup failed" on error, as today (Varhop.qml repoProc).
4. Else: nothing is chosen. The zero-match line under the field says why
   in words: no listed repo matches, and a full `owner/repo` can still be
   entered. Empty field: Enter does nothing at all.

One match is just rule 2 with the only row highlighted; it does not
auto-choose while typing. Many matches never guess beyond the visible
highlight. Empty Enter doing nothing is deliberate: the field grabs focus
when settings opens (SettingsBody.qml repoField forceActiveFocus), and a
stray Enter must not sync whichever repo sorts first, which on this
machine would be someone else's `apphutdev/aiva`.

Cost: one extra Enter in the single-match case compared to auto-pick on
unique match. That keystroke is the confirmation that a repo switch,
with its import and possible draft discard, deserves.

### Rejected options
- Enter always takes the top filtered row, highlight or not. Same result
  as this pick when a highlight exists, but with an empty or untouched
  field it imports the alphabetically first of 161 repos. Emoji and file
  pickers can afford Enter-picks-top because their activation is cheap
  and reversible; a repo choice starts a clone and a selection save.
- Enter always runs the typed lookup (today's behavior, kept pure).
  Then a user who filtered to one row and pressed Enter gets "invalid
  owner/repo" unless they typed the full string, which makes the filter
  decorative and is F1 unchanged.
- Auto-choose when the filter reaches exactly one match. Fastest, and the
  most dangerous: a debounce-free keystroke that momentarily leaves one
  match commits a switch mid-typing, and the draft-discard warning
  becomes the only brake.
- Zero matches show "no results" and swallow Enter. Hides the typed path
  that reaches public or otherwise unlisted repos `/user/repos` cannot
  return (S4), recreating a first-run dead end.

### Evidence
- better-than-training · worktree Varhop.qml:308 (repoRe), :906-907 and
  repoProc block, `chooseRepo` :328-338, read 2026-10-13 · both
  destination paths already exist with validation, lookup error text
  and the draft warning. This pick only adds resolution order in front
  of them.
- better-than-training · INTAKE.md F1 and Expected behavior · "Picker
  narrows as the operator types" plus the recorded workaround (full
  owner/repo plus Enter). Both behaviors must survive in one Enter.
- practitioner · first-party Emojis and Menu key handling
  (Emojis.qml:220-221, Menu.qml:1265-1266) · Return activates the
  selected index, guarded by an active cursor. Supports
  highlight-then-Enter, with varhop's empty-field exception driven by
  activation cost, not by picker habit.

### Pitfalls and what removes each
- Rule 1 and the highlight disagreeing (exact text typed, arrow moved to
  another row): exact text wins, which can override a deliberate arrow
  choice. Removed by ordering: if the user moved the highlight after the
  last text change, the highlight is the intent; state that as an
  implementation line (selectionMoved flag reset on text change) and a
  component case.
- Typed lookup succeeds for a repo also in the list but filtered out by a
  typo'd query: fine, chooseRepo gets API ids either way; no special
  case needed.
- Enter during a running sync: startSync already refuses with "a sync is
  already running" (Varhop.qml:311-312). Keep; the picker must not queue
  a second choice behind it.
- Choosing the repo that is already selected restarts a full sync via
  repoChange. Not removed by this pick; flagged as its own question
  below.

### Questions the fork does not ask
- Enter or click on the currently selected repo: treat as Sync now
  (re-pull same repo), refuse as already-current, or keep today's full
  switch-to-self sync? The row is one click away in settings.
- After a successful first pick, the old brief routes to search. After a
  switch from settings with a library already loaded, does Enter's choice
  stay in settings until the import lands? Routing lives in the root, but
  the picker fork should say what the user sees during the sync.

## S3. Moving and activating without a mouse

### Pick
The field keeps focus and owns the list, mirroring this plugin's own
search view. Typing or backspace refilters and highlights the first match
(SearchBody.qml resolveSelection resets to top on query change;
SettingsBody copies that rule). Up and Down move the highlight with wrap,
handled in the field before the item sees them (SearchBody.qml:70-71
pattern). Enter activates per S2. A click activates the clicked row
through the same `repoChosen` signal; hover moves the highlight to the
hovered row so mouse and keyboard never point at different rows. The
highlight is painted with menu.selectedBackground and menu.selectedText
per look Taken. For the Tab+Enter carry from proof-bar: the picker is
one control — Tab in the settings chain reaches the field, Enter
activates from it, and every row is reachable by typing plus arrows
without becoming 161 separate Tab stops. Esc with a non-empty field
clears the filter first, second Esc follows settings' existing
backRequested rule. Ctrl+R stays inert inside the field (locked,
fieldKeys already passes inertCtrlR).

Reasons: one focus owner removes the whole class of focus fights a
separate list-focus design invites in a view whose fields grab focus on
sight, and it is how Emojis, Menu and Clipboard all run their lists (a
filter string, selectedIndex reset to 0 on filter change, Return
activates selectedIndex). Proof is also already shaped: the uinput probe
proved arrows and selection reach this overlay (proof-bar probe 2a), so
Up and Down are agent-provable live, not only by component keyClick.

Cost: Tab does not walk rows one by one, so a strict reading of "every
control Tab+Enter" has to accept the composite-control reading: the
picker is one keyboard control, rows are values inside it. I state that
reading openly because the alternative, 161 Tab stops, is unusable and no
first-party picker does it.

### Rejected options
- Rows as individual focusable controls in the Tab chain. Literal
  compliance, practical nonsense at 161 stops, and Tab would need to
  leave the field on first press, breaking type-to-filter flow.
- Tab moves focus field to list, arrows act only in the list. Two focus
  owners, a visible focus question (which one has it now), and typing
  while the list holds focus must route back to the field, the custom
  key-catcher pattern first-party pickers use only because they have no
  real text field. Varhop has one; simpler to keep keys in it.
- Mouse-only rows with Enter as the sole keyboard path. Leaves arrow
  users and the proof-bar reset-isolation class of problem alive in a new
  place, and diverges from the search view one screen away.

### Evidence
- practitioner · Emojis.qml:76-102, :137-138, :208-221 and
  Menu.qml:751-752, :1251-1266, Clipboard.qml:181-182, :366-386, read
  2026-10-13 · filter resets selectedIndex to 0, arrows move with wrap,
  Return activates the selection, all without focusable rows.
- better-than-training · worktree qml/SearchBody.qml:40-47, :70-76 ·
  this plugin's search already implements reset-to-top, wrap and
  Enter-opens-selected inside one focused field. Same mental model, one
  screen apart.
- better-than-training · proof-bar Taken and probe 2a result · Tab+Enter
  owed on every control; arrows, shift-selection and paste proven to
  reach the overlay by uinput keyboard.
- operator · look Taken · menu.selected* are the selection colors, so the
  highlight needs no new token.

### Pitfalls and what removes each
- TextArea consumes Up and Down as caret movement before handlers see
  them. Removed by Keys.BeforeItem on the field, the priority the field
  already declares, plus a component case: type, Down, Enter chooses the
  second match.
- Highlight resting on a row the next keystroke filters away. Removed by
  the reset-to-top rule on every text change; the highlight is never
  carried across a filter change.
- The settings page is one tall Flickable column; a highlighted row can
  sit below the fold. Removed in S4's bounded list with
  positionViewAtIndex on highlight change, the first-party pattern
  (Emojis.qml:90).
- Mouse hover and keyboard highlight fighting on PointerMove storms.
  Bounded by hover moving highlight only (no activation), and no
  PointerMoveGate equivalent exists in the plain views; accepted, a
  click still activates the row under the pointer by its own MouseArea.

### Questions the fork does not ask
- PageUp, PageDown, Home, End in a 161-row list: first-party grids
  support page moves (Emojis.qml:129-133). Worth it, or is typing the
  only long-distance travel?
- While a sync runs after a choice, is the field disabled, or can the
  user keep typing and queue confusion the running-sync refusal then
  reports as an error?

## S4. List source, size and states

### Pick
Source stays `varhop-sync repos` unchanged. The list becomes a bounded
ListView (about eight rows tall) over the alphabetically sorted,
filtered model, inside the settings column, with the selected row kept
visible. Each row shows fullName plus a private marker, and the current
selection's row is marked "current" in words. Three empty states get
three different lines of text where the list would be: loading ("loading
repositories"), list failed or empty from the API ("could not list
repositories" plus the typed path still available), and filtered to zero
(the S2 wording). The typed path is never blocked by any list state.

Reasons: `/user/repos` covers owned, collaborator and organization-member
repos (GitHub docs), which is the right universe for a prompts repo, and
anything outside it (a public repo the user has no explicit access to)
remains reachable by typing, which is why S2 keeps that path. The current
loading behavior cannot distinguish those states: reposProc sets
`root.repos = []` on parse failure and on non-zero exit, and a retry timer
reruns it every 1.5 s while the list is empty (Varhop.qml:583-601), so a
gh failure currently presents as an eternally empty picker. A Repeater
over the full 161 also builds every delegate inside the settings
Flickable, the cost SearchBody already paid to escape when it moved to a
ListView (its comment at the ListView: a Repeater blows the frame
budget). Rows are text-only and the frame budget is a search criterion,
not a settings one, but bounded height is needed anyway for the highlight
to be scrollable into view per S3.

Cost: a ListView nested in the settings Flickable means wheel over the
list scrolls the list, wheel elsewhere scrolls the page. That is normal
for pickers and bounded to eight rows. Sorting client-side means the
order changes from what the current build shows; nobody can be attached
to created-descending order they never chose.

### Rejected options
- Keep the Repeater, just filter its model. Smallest diff, keeps the
  161-delegate build on empty query, and gives no scroll-to-highlight, so
  S3's arrow navigation walks off-screen inside a page-length column.
- Cap the rendered rows (first 20 plus "type to filter"). Hides repos
  from browsing, and the cap boundary interacts with the highlight: the
  21st alphabetical repo is unreachable by arrows until typed for. A
  ListView solves the same cost honestly.
- Fetch sorted from the API (add sort=full_name in varhop-sync). Changes
  a merged leaf's contract and its tests for something the view can do in
  one sort; ordering is presentation, not sync data.
- Enrich rows via a new sync field (pushed-at, description). More sync
  contract and fixture churn for a picker used on first run and rare
  switches; fullName plus private already identifies a repo.

### Evidence
- better-than-training · GitHub REST docs for /user/repos and worktree
  bin/varhop-sync:86-89, read 2026-10-13 · coverage and current field
  set (fullName, id, private), paginated at 100.
- better-than-training · worktree Varhop.qml:583-601 (retry timer,
  reposProc failure handling) and SettingsBody.qml:103-108, :219-235
  (page Flickable, Repeater), read 2026-10-13 · the three empty states
  are currently one indistinguishable blank.
- better-than-training · worktree qml/SearchBody.qml ListView section ·
  the delegate-count lesson is already paid for and documented in this
  codebase.

### Pitfalls and what removes each
- Retry timer plus a "could not list" line could flicker states every
  1.5 s. Removed by deriving the state line from reposProc's last exit
  and running flag passed as props (loading while running, failed after a
  non-zero exit until the next start), not from list length alone. That
  is a root-to-view prop addition, named here so it is not discovered in
  implementation.
- ListView reuse recycling row highlight onto the wrong delegate.
  Removed by the standard discipline SearchBody uses: delegate color
  bound to index equals selectedIndex, no per-delegate state.
- Alphabetical sort with mixed-case owners sorting uppercase first.
  Removed by sorting on the lowercased fullName, stable for equal keys.
- The current-selection marker pointing at a repo the filter hid: the
  marker is per-row, so it simply is not shown; the selection line above
  the field (SettingsBody.qml:181-187) already states the current repo
  regardless of filter.

### Questions the fork does not ask
- Should the picker list refresh on every settings open (today
  refreshRepos runs on open when no selection, and on the retry timer),
  or only once per shell session and on demand? A repo created
  mid-session, like varhop-prompts-b was, is the test case.
- Private marker: word "(private)" as today, or dropped now that rows use
  look tokens and a lock glyph exists in the menu font (depends on the
  look fork's unanswered icon question)?
