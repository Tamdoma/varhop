# Controls fork notes, slot C (blind), 2026-10-13

Ground facts. The card today is one Item whose Keys handler forwards
everything to the active view and handles only Ctrl+, itself, including
capturing the editor draft before the settings Loader destroys the editor
(worktree Varhop.qml:781-811). Views fill the whole card through Loaders
that are inactive, hence destroyed, off-view (Varhop.qml:814, :855, :885).
Each view already exposes the signals the buttons need: editor
findAnother and hideRequested (qml/EditorBody.qml:24-25, wired at
Varhop.qml:865-876), settings backRequested (qml/SettingsBody.qml:29,
wired at :923-932). Settings was always locked to open "with Ctrl+, or a
visible button" (settings-and-hotkey Taken), so the button is owed work,
not new scope.

## S1. Which views get which controls, and what does each one do?

### Pick
A fixed header owned by the root, present in all three views. Left: a
Back button, shown in editor and settings, hidden in search. Right: a
Settings button, shown in search and editor; in settings it renders in
its active state and does nothing. Middle: the view's name in words
("Prompts", the open prompt's title, "Settings"). Each button calls
exactly the existing action, through one root function per action:
- Editor Back = the findAnother path: capture draft, restore previous
  query and selection, show search (today's Ctrl+P, Varhop.qml:866-876).
- Settings Back = backRequested as wired today: return to the view
  settings came from, reopening the editor with its draft; with no
  earlier view and no selection, hide.
- Settings button = the Ctrl+, entry path: capture the editor draft
  first if in the editor, remember cameFrom, show settings
  (Varhop.qml:802-807).
Esc does not change anywhere outside the chrome focus context in S3:
editor Esc still hides with draft kept, search Esc still clears then
hides, settings Esc still returns. Back is never spelled Esc and never
labelled Close.

Reasons: search is home, so a Back there could only mean hide, and a
button whose meaning changes per view is how F6 happened in reverse.
One root function per action is what keeps mouse, Enter on a focused
button and the chords from drifting apart (proof-bar: same action path).
Naming the view in the header answers "where am I" for a first-run user
who lands in the picker without choosing it.

Cost: the header takes about one headerHeight (Style-derived, about
34px) plus spacing from a 480px card in every view, including search
results and editor lines. That is the price of a fixed target that never
moves.

### Rejected options
- Back in search meaning hide. Two exits (Esc, scrim click) already hide;
  a third labelled Back teaches that Back means leave, which then makes
  editor Back (keep draft, go to list) a surprise.
- Settings button only in search. The draft-capture-before-settings path
  from the editor already exists and is exactly where a user mid-edit
  looks for Sync now or the repo name; omitting it there saves one button
  and keeps a hidden-chord-only route in one view.
- Back in settings labelled with its destination computed live ("Back to
  editor"). Attractive, but the label then depends on cameFrom, draft and
  selection (Varhop.qml:924-931 has three branches), and a wrong label is
  worse than a plain one. The header title already says where you are;
  after pressing Back it says where you landed. (If the operator wants
  destination labels, that is a stated variant, not a default.)

### Evidence
- better-than-training · worktree Varhop.qml:781-811, :865-876, :923-932
  and qml/SettingsBody.qml:80-98, read 2026-10-13 · all three actions
  exist as key-driven paths with the draft rules attached; buttons are
  new triggers on old paths, not new behavior.
- operator · settings-and-hotkey and copy-and-close Taken (old chart) ·
  Ctrl+P returns with draft kept, Esc in the editor hides and is never
  back, settings Esc returns to its source view. The mapping above is
  those locks with visible faces.
- practitioner · Omarchy Menu goBack (plugins/menu/Menu.qml:774) reached
  by Backspace or Left on an empty filter (Menu.qml:1248-1249) · first-
  party precedent that back is a navigation action with its own trigger,
  separate from Esc-to-dismiss.

### Pitfalls and what removes each
- A button path that skips draft capture loses edits when the settings
  Loader destroys the editor. Removed structurally: buttons call the
  same root functions the Ctrl+, and findAnother wirings call, and a
  component case presses each button (mouseClick) and its chord,
  asserting identical resulting state (draft values, view, cameFrom).
- Settings button visible but dead inside settings reads as a bug.
  Removed by rendering it in the kit's active/selected state there, the
  same state Ui Button uses for a chosen toggle, and excluding it from
  the focus cycle in that view only.
- Library-mismatch routing force-opens settings (Varhop.qml:150, :266);
  a Back press there must not route to a search with no valid library.
  The existing backRequested wiring already keys off cameFrom and
  selection; the done-criterion for the mismatch case (settings names
  it, Sync now offered) must be re-run with the button present, not
  assumed.

### Questions the fork does not ask
- Does search get a visible control for anything else now that a header
  exists (Sync now? last-pull text?), or does the header stay navigation
  only? Adding sync duplicates Ctrl+R discoverably, and settings already
  shows last pull.
- Should the header title in the editor be the prompt title (repo text,
  PlainText, elided) or a fixed word? A title makes the draft's identity
  visible, a fixed word avoids elision rules.

## S2. Placement, shape, labels or icons?

### Pick
Top header, one row, inside the card above the loaders: Back left,
title center-left, Settings right. Buttons are qs.Ui Button at the root
(the root may import qs.Ui; the views stay plain), `focusable: true`,
icon glyph plus text label ("Back", "Settings"), with the chord as the
button's tooltip and also printed after the label in muted text inside
the button where width allows (`Back  Ctrl+P`, `Settings  Ctrl+,`).
Heights and paddings from Style tokens via the kit's defaults; the focus
state is the kit's focus fill and border (Ui/Button.qml:10, :66-69,
:79-82), which look Taken already mandates through Style focus tokens.

Reasons. One root header puts the buttons outside the Loaders, so they
survive view switches without being rebuilt per view, and it is the only
placement where qs.Ui Button is available without breaking the
Quickshell-free view rule the component tests rest on. The kit button
already implements the proof-bar contract: activeFocusOnTab when
focusable, Return, Enter and Space all emit clicked (Button.qml:66-69),
and its border reservation prevents the header relayouting when a focus
ring appears (:72-73). Icon plus word answers F7's "no cog or button"
literally while keeping the word for anyone whose font lacks the glyph:
look Taken binds menuFamily, which is the Nerd Font alias today but is an
operator-overridable env var (OMARCHY_MENU_FONT), so the word must carry
the meaning alone. Printing the chord turns the button into the
documentation F6 and F7 say does not exist outside the README.

Cost: two buttons with text and chord hints want roughly the card's full
560 width alongside a title; at larger font tokens (look stepped sizes
up) the title elides first, by rule. Icon glyphs are private-use
codepoints copied from first-party usage; if a future menu font lacks
them they render as boxes next to still-readable words.

### Rejected options
- Per-view buttons inside each view file. Three implementations of focus
  and styling, plain-QtQuick buttons reinventing the kit's focus ring,
  and the settings view is a scrolling Flickable where a button at the
  top scrolls away exactly when the page gets long.
- Footer bar instead of header. The editor's bottom edge already carries
  the unset count and error line, and search's list wants the height.
  A footer also puts Back as far as possible from where a reader's eye
  starts. Raycast-style action footers work when the footer is the
  product's main hint surface; here it would be a third competing strip.
- Icon-only buttons. Smallest, and the exact discoverability failure F7
  reports, moved from absence to decoding. Also the most fragile under a
  menu-font override.
- Hint text only, no buttons ("Ctrl+P back · Ctrl+, settings"). Cheap,
  violates the visible-button lock, gives the mouse nothing, and fails
  proof-bar's same-action-path rule by having no action to share.

### Evidence
- practitioner · /usr/share/omarchy/shell/Ui/Button.qml:6-24, :66-69,
  read 2026-10-13 · "One component for every clickable thing in the
  kit", focusable state with focus fill and border from [controls]
  tokens, Return, Enter and Space activation built in.
- practitioner · Menu and Clipboard headers (Menu.qml:1303-1322,
  Clipboard.qml:428-445) · first-party summoned surfaces open with a
  headerHeight strip at heading size; a header is the shell's shape, not
  an invention.
- better-than-training · look Taken (menu font one step up, Style focus
  tokens) and Style.qml menuFontFamily resolution · sizes and focus
  colors are already decided; this fork only spends them.
- operator · INTAKE F6, F7 · "no visible back button", "no cog or
  button". Words plus the cog answer both phrasings.

### Pitfalls and what removes each
- Header drawn inside a Loader's area or under the scrim MouseArea order
  makes clicks fall through to hide. Removed by structure: the card
  becomes a column of header plus loader area, and the scrim click-catcher
  stays behind the card as today; one screenshot and one uinput or
  mouseClick activation per button in proofs.
- Buttons stealing the card's initial focus from the query or repo
  fields, which force focus on completion today. Removed by S3's focus
  rules: buttons are focusable but nothing gives them initial focus, and
  each view's first field keeps its forceActiveFocus.
- Elided title colliding with long prompt titles (hostile or merely
  long). Title text is PlainText and elided, buttons keep implicit width;
  a component case with a 200-character title checks the buttons remain
  fully visible.

### Questions the fork does not ask
- Back label: the word "Back", or the locked action's own name "Find
  another prompt" shortened how? The chord is documented under that name
  in the README, the operator asked for "back" in F6. One name should win
  everywhere, README included.
- Does the Settings button show state worth knowing (a dot when a sync
  error or mismatch waits inside)? Useful, but it is a second signaling
  system; not asked, not assumed here.

## S3. How does keyboard focus reach the controls without breaking the editor's Tab cycle?

### Pick
Two focus contexts, switched by one explicit key. Content context is the
default everywhere: the view behaves exactly as locked today, editor Tab
and Shift+Tab walk variable names with wrap and never leave the text.
Ctrl+Tab from any view enters the chrome context: the first visible
header button (Back if shown, else Settings) takes activeFocus and shows
the kit focus ring; in chrome, Tab and Shift+Tab cycle only the visible
header buttons, Enter, Return and Space activate, and Esc returns focus
to the content exactly as it was (query field caret, editor caret and
selection, field focus in settings) without hiding. A second Ctrl+Tab in
chrome also returns to content. Clicking a button takes the same
activation path; after a view-changing activation, focus lands on the new
view's content, not back on the header. All existing chords (Ctrl+P,
Ctrl+,, Ctrl+R inert in picker fields, Ctrl+Shift+P) work from content
exactly as today; in chrome, letters type nowhere.

Reasons. The editor's Tab cycle is locked with wrap and has no spare
slot: inserting chrome into it (Tab past the last variable visits the
header) changes the cycle's length per prompt and makes Tab count
unpredictable, which B's editor note R5 already ruled out. A separate
context entered by one chord is how the variable cycle stays untouched
while proof-bar's Tab+Enter is honored inside the chrome, where Tab is
free to mean next-control. Ctrl+Tab is unclaimed in this plugin's key map
(every locked chord is accounted for in the README key table) and is not
a window-manager chord the layer would lose. Escape-from-chrome is the
standard cancel for a focus excursion and mirrors search's existing
two-step Esc (clear, then hide): chrome Esc returns, content Esc keeps
its locked meaning.

Cost: one more chord to document, and it must be discoverable without
the README, which S2 pays for by printing hints on the buttons and which
needs one more: a muted "Ctrl+Tab" hint at the header's edge or in the
search footer area, or new users find the buttons by mouse only, which
for F6 and F7 is arguably enough but should be a conscious trade. Mode
errors are possible (typing into chrome does nothing visible except
nothing), bounded by the focus ring being unmissable.

### Rejected options
- Insert the header into the natural Tab order after each view's fields.
  In the editor that either steals wrap (last variable's Tab leaves the
  text) or requires the editor to special-case Tab at the boundary,
  breaking the locked cycle and every existing Tab component case. In
  search it makes Tab from the query field stop filtering mid-thought.
- No focusable buttons: chords are the keyboard path, buttons are mouse
  only. Violates proof-bar Taken as written (Tab+Enter through the same
  action path), even though functionally the actions are keyboard
  reachable today. If the operator wants this, proof-bar must be amended
  like the picker composite was, explicitly.
- A different entry key per view (Tab in search and settings, Ctrl+Tab
  only in the editor). Two rules where one works; the day settings gains
  more fields, its natural Tab chain and the header's chain interleave
  unpredictably. One entry chord everywhere is teachable in one hint.
- F6 as the context key (the pane-cycling convention). Defensible, but
  unhintable on the buttons themselves and unknown to most users;
  Ctrl+Tab at least reads as "Tab, but for the frame".

### Evidence
- operator · proof-bar Taken Q4 and picker Taken 4a · Tab+Enter through
  the same path is owed per control, the editor Tab cycle is unchanged,
  and a composite control reading is available where per-row Tab is
  absurd. A two-context header is the same move at card level.
- better-than-training · editor Taken and prototype result · the guarded
  text box owns Tab for unique names with wrap, proven live; nothing may
  insert stops into that cycle.
- better-than-training · Ui/Button.qml:66-69 · once a button holds
  activeFocus, activation keys are free; the only new machinery is who
  grants focus, which is this pick.
- better-than-training · worktree Varhop.qml:787-811 · one root Keys
  handler already arbitrates between the view and Ctrl+,,; the chrome
  context is a third branch in the same place, ahead of view forwarding
  while active.

### Pitfalls and what removes each
- Focus restoration losing the editor's caret or selection (the OA2
  surface). Removed by capturing nothing: entering chrome must not touch
  the draft or reopen the prompt; it only moves activeFocus. Returning
  refocuses the text box, whose caret and selection were never
  disturbed. A component case asserts cursorPosition and selection
  before and after a chrome round-trip, and the uinput OA2 live criteria
  cover the composed path.
- Editor text box consuming Ctrl+Tab as an edit key before the root sees
  it. Removed by handling Ctrl+Tab in the field's Keys.BeforeItem path
  the same way Tab is handled today, accepting the event; component case
  sends Ctrl+Tab with the caret mid-value.
- Chrome active during a view switch (sync finishes, mismatch routing
  forces settings). Removed by rule: any root-driven view change drops
  to content context and focuses the new view's first field, so focus
  never rests on a button whose view just changed under it.
- Shift+Tab arriving as Backtab on some layouts: the existing editor
  handler already treats Key_Backtab and Tab+Shift alike; chrome uses
  the same test.

### Questions the fork does not ask
- When focus returns to content in settings, which field gets it: the
  one last focused, or always the first (the repo field, by today's
  forceActiveFocus)? Last-focused needs one remembered item per view;
  first-field is simpler and can annoy mid-chord-typing.
- Should Ctrl+Tab also work from the picker's composite control without
  disturbing its highlight? It should fall out of the root-level rule,
  but the picker's highlight is field state, so returning must not reset
  it; untested until someone writes the case.

## S4. Discoverability, hints and states

### Pick
Buttons always visible in their views (no hover-reveal, no
auto-hide), each carrying its chord as muted text and a tooltip naming
the action in the locked vocabulary ("Find another prompt (Ctrl+P)",
"Settings (Ctrl+,)"). One additional muted hint, "Ctrl+Tab for buttons",
sits at the header's right edge in the space the hidden Settings button
leaves in settings view, and as part of the Settings button's tooltip
elsewhere; no footer hint strip anywhere. States come from the kit:
idle transparent, hover and focus per [controls] tokens, Settings shown
active inside settings, Back hidden rather than disabled in search.
Nothing flashes, pulses or animates beyond the kit's own color
Behavior (Ui/Button.qml color animation).

Reasons. F6 and F7 are discoverability failures, so the fix must be
visible at rest, in a screenshot, without interaction. The chord printed
on the button is the teaching mechanism: a user who clicks Settings
twice has read Ctrl+, twice. Keeping hints on the buttons themselves
avoids a permanent hint footer competing with the editor's unset count
and error line, which are information, not chrome.

Cost: chord text widens buttons and at look's stepped-up sizes the
header gets tight in 560px; the title elides to pay for it (S2).

### Rejected options
- Footer key-hint strip across all views (Raycast-style). Consistent and
  roomy, but it spends a second strip of the 480px card, duplicates what
  the buttons now say, and in the editor it sits next to the unset count
  saying something less important more loudly.
- First-run-only hint (show hints until first successful chord use).
  State to store, a layout that changes after learning, and no help the
  second time a user forgets. Discoverability that expires is how F6
  recurs.
- Disabled-grey Back in search. A visible dead control invites the click
  that teaches nothing; hidden says "not a thing here" honestly. (The
  header keeps its layout: Back's slot is simply empty in search, the
  Settings button does not move.)

### Evidence
- operator · INTAKE F6, F7 and Urgency (keys "only documented in
  README.md") · the failure is precisely that working keys were
  undiscoverable; hints must live on the surface, not in a file.
- practitioner · Ui/Button.qml tooltip support and state precedence
  (pressed, focus, hover, selected, idle) · every state this pick needs
  exists in the kit with theme tokens behind it.
- better-than-training · worktree EditorBody footer (unset count,
  lastError, anchors at the view bottom) · the bottom edge is taken by
  live information in the one view where a hint footer would matter most.

### Pitfalls and what removes each
- Tooltip delay (400ms in the kit) making the chord invisible to a fast
  user. Removed by also printing the chord on the button face; the
  tooltip is the long form, not the only copy.
- Hint text at body token size (look: nothing essential below body)
  crowding the header at large base sizes. Removed by elision order
  (title first, then drop the Ctrl+Tab hint before any button shrinks)
  and the larger-base-size component case look Taken already requires.
- Screen-reader and accessibility naming: QML buttons here get their
  accessible name from text; with icon plus text the word is present.
  No separate work, stated so icon-only does not creep back in review.

### Questions the fork does not ask
- Does the search view's existing pinned "Resume draft" row (which prints
  its Ctrl+Shift+P chord today) set the house style for printed chords,
  and should the header match its wording?
- Middle-click or right-click on header buttons: nothing today. Right-
  click on Settings could mean Sync now in some launchers; inventing it
  here would add an undiscoverable path of exactly the kind being fixed.
