# Inline editor fork notes, slot C (blind), 2026-10-13

Constraint that shapes all three answers: this plugin is pure QML and JS.
Every first-party Omarchy plugin is qml, js, json or shell files, no
compiled code (file-type count of /usr/share/omarchy/shell/plugins,
checked 2026-10-13), and the plugin validator checks manifest and entry
points, with no build step. In pure QML, a `TextEdit` document gives no
access to per-range character formats or a syntax highlighter: the QML
`TextDocument` object exposes only source, modified, status and
errorString (/usr/include/qt6/QtQuick/qquicktextdocument.h, read
2026-10-13). Any candidate needing VS Code-style decorations must
simulate them with items, not document formats.

## Q1. Which mechanism keeps values inline under the locked rules?

### Pick
Read-only flowing text with one native input placed over the active
value. The canvas is a single read-only `TextEdit` (PlainText, wrap)
showing the display text: prose segments verbatim, each token shown as
its value, or `{{NAME}}` while unset. It must be a TextEdit, not a
`Text`, because only TextEdit and TextInput expose `positionAt` and
`positionToRectangle` in this Qt's QML types
(/usr/lib/qt6/qml/QtQuick/plugins.qmltypes QQuickTextEdit methods,
checked 2026-10-13), and those two methods are how clicks find a token
and how the input is placed. Tab, Shift+Tab or a click on any occurrence
opens one `TextArea` over that occurrence's rectangle, pre-filled with
the name's current value and selected. Typing in it writes through the
existing values map per keystroke, so the canvas behind re-renders and
mirrors stay live; the field re-anchors if a mirror before it changed
length. Tab again commits (inputMethod commit first) and moves to the
next unique name with wrap.

Why this one: it reuses almost everything the failed leaf already
proved. The field is the same native input the current editor uses per
name, so IME, dead keys, Ctrl+V and Ctrl+Shift+V, the right-click menu,
paste normalization and `Qt.inputMethod.commit()` before copy keep
their existing code paths (worktree qml/EditorBody.qml field handlers
and FieldKeys). Per-variable undo keeps the existing per-name history
maps (EditorBody.qml pushAction, undoTop), Delete empty-then-unset
stays a field-local rule, exact cursor and selection resume stays a
field cursor inside captureDraft, and copy is untouched because
`rebuiltText()` still rebuilds from `lib/tokens.mjs` segments plus the
values map, never from any document text. Prose cannot be edited
because the canvas is read-only and holds no values state; that lock is
removed by construction, not guarded. Practitioner shape: this is the
rename-box pattern (an input floated over the one range being edited)
rather than a snippet session, and it is the only candidate whose hard
parts are placement math instead of input interception.

Cost, stated plainly: while a value is being edited, a field covers the
text at that spot and can cover following words when the value is empty
(zero display width) or much longer than its slot. A wrap-spanning
value gets a rectangular field over a non-rectangular hole. The field's
font metrics must match the canvas exactly or text visibly jumps on
open, which ties this fork to the look fork's font choice. Long values
(the operator's DIFF-style pastes) need the field to grow and scroll
internally without pushing the canvas. None of these are removed by
design words; Q3 is where they get measured.

### Rejected options
- One flowing TextEdit with guarded value ranges. Best looking, worst
  fit for pure QML. Guards see key events, but composition text, IME
  commits, context-menu paste and middle-click do not arrive as keys,
  so prose protection needs an onTextChanged verifier that infers the
  edit delta and reverts out-of-range changes. Reverting fights the
  input method mid-composition, programmatic mirror rewrites shift
  offsets around the user's cursor, and every self-caused text change
  must be told apart from user edits. Qt's native undo records all of
  it, so locked per-variable undo means intercepting Ctrl+Z and keeping
  the native stack unreachable, which the context menu's Undo entry
  bypasses. VS Code proves the shape at scale (tabstops, "multiple
  occurrences of the same tabstop are linked and updated in sync",
  choice and placeholder selection; VS Code snippet docs, read
  2026-10-13), but it proves it with a full editor model: linked-range
  decorations, multi-cursor and snippet-scoped undo. Qt 6.12 QML offers
  none of that; `cursorSelection` exists only as a marked technology
  preview in the TextEdit docs. Building a snippet engine on
  string-delta inference inside a 400-line view is the largest risk in
  this chart.
- A Flow of prose pieces and per-name fields. Smallest change from the
  current Column (worktree qml/EditorBody.qml:255-380), and the only
  one that keeps N fields. It fails F5's actual words, "the prompt
  always looks the same": prose must be chopped into word atoms to
  wrap, so hard newlines, indentation, tables and code fences reflow,
  and every keystroke re-widths a field and rejigs every line after it.
  The prompt's shape becomes a function of the values typed so far.
- Whole-body editable. Reopens two locks at once: values-only with
  prose fixed, and copy rebuilt from parsed segments (variable-editing
  Taken Q1 and Q4). Typed prose would enter the copy, a typed
  `{{OTHER}}` would need a re-parse rule, and the grammar's verbatim
  body guarantee dies. F5 asks for inline variables, not prose editing.

### Evidence
- practitioner · Microsoft VS Code, "Snippets in Visual Studio Code"
  (code.visualstudio.com/docs/editing/userdefinedsnippets), read
  2026-10-13 · tabstops visited in order, same-number occurrences
  linked and updated in sync, placeholder text inserted selected. This
  is the reference shape for candidate 1 and shows which machinery it
  presupposes. Changed nothing toward picking it here; it bounds what
  "good" looks like and what pure QML lacks.
- practitioner · Espanso forms documentation (espanso.org/docs/
  matches/forms) and Raycast snippet documentation (manual.raycast.com/
  snippets, dynamic placeholders as arguments), read 2026-10-13 · both
  ship per-variable form fields filled before expansion: the exact
  stacked shape the operator rejected in F5. Their values are short
  and the expansion target is another app, so the precedent does not
  transfer; it does confirm no mainstream tool ships a Flow of fields
  inside document text.
- better-than-training · Qt 6.12 TextEdit QML docs (doc.qt.io) and
  local /usr/lib/qt6/qml/QtQuick/plugins.qmltypes, read 2026-10-13 ·
  TextEdit has positionAt, positionToRectangle, preeditText, getText,
  insert, remove; plain `Text` has neither position method; QML
  TextDocument (qquicktextdocument.h) exposes no formats or
  highlighter. Decided the canvas type and ruled out document-level
  styling in pure QML.
- better-than-training · worktree qml/EditorBody.qml, lib/tokens.mjs,
  lib/rebuild.mjs, read 2026-10-13 · values map, per-name undo, draft
  capture with cursor and selection, and rebuild-from-segments are
  mechanism-independent and already proven; only rendering and field
  placement are new under this pick.

### Pitfalls and what removes each
- Mirror before the active occurrence changes length and the floating
  field's anchor shifts under the user's hands. Removed by anchoring
  the field to the active occurrence's start offset and re-deriving its
  rectangle from positionToRectangle after every canvas re-render,
  never by caching x and y; covered by the Q3 prototype matrix below.
- Wrap-spanning and multiline values make the rectangular field cover
  prose below it. Not removable by construction; bounded by clamping
  the field to at most the canvas width and a capped height with
  internal scroll, and by scrolling the canvas so the active range
  sits in the upper half before the field opens. The prototype must
  show this is usable, or Q1 reopens with that evidence.
- Click in prose does nothing, which reads as a dead editor even
  though prose was never editable. Removed only cosmetically: clicks
  resolve through positionAt to the nearest token occurrence, or do
  nothing by stated rule. This is a fork question (below), not a
  default.
- Tab pressed mid-IME-composition drops preedit. Removed by the same
  rule copy already has: `Qt.inputMethod.commit()` before any
  transition out of the field (Tab, Esc, copy).
- Empty-set value has no visible slot, so Tab appears to land nowhere.
  Removed in Q2 (a minimum-width marker), and the field opening there
  is itself the visible answer.
- Draft format drift: captureDraft today records a per-field cursor.
  Under this pick it records activeName plus the floating field's
  cursor and selection, same shape, so resume criteria carry over; the
  criterion-to-evidence table (disposal carry) must say the old resume
  proofs are invalidated and re-earned, which proof-bar already does
  (OA2 is an agent criterion again via the uinput probe).

### Questions the fork does not ask
- Is mirroring per keystroke actually locked, or is commit-on-Tab
  acceptable? Brief language says a typed value "mirrors to every
  occurrence" and the old component test reads a mirror before Tab.
  This pick keeps per-keystroke write-through, so it does not need the
  answer, but candidate 1 and any commit-style variant do.
- Should clicking a later occurrence edit that occurrence in place
  (this pick), or jump to the first occurrence the way the stacked
  editor's stop worked? In-place is better and now possible, but it
  redefines "stop" from first-occurrence to any-occurrence while Tab
  order stays by unique name.
- Does exact resume include the canvas scroll position on long prompts?
  The old draft never recorded contentY, so current behavior already
  says no, but a flowing canvas makes the omission visible.

## Q2. How does a value look: unset, filled, empty, active?

### Pick
One PlainText canvas in one text color, with highlight rectangles
painted behind each token occurrence's line runs, computed from
positionToRectangle per character and grouped per line. Unset shows the
literal `{{NAME}}` over a muted highlight. Filled shows the value over
a quieter accent-tinted highlight. Set-but-empty shows a
minimum-width highlight gap (about one character) so the slot is
visible and clickable. Active is the floating field itself, with the
themed border the look fork chooses; its occurrence's highlight is the
strongest. The unset count stays in the footer, as today.

Why: criterion 9 is absolute (hostile titles, bodies and errors render
as literal text, no requests), and Qt's own Text docs say untrusted
content should be explicitly PlainText or stripped (doc.qt.io Text,
read 2026-10-13). Highlight rectangles keep every character coming from
the prompt or the values in one PlainText string, so there is nothing
to escape and nothing to inject, while still giving the four states
distinct looks. The braces on unset names are a second, non-color cue,
and they are also what copies, so display never lies about output.

Cost: geometry must be recomputed whenever text, width, font or theme
changes, walks every token character, and multi-line values produce
one rectangle per line run. Prompt bodies are small next to the 20 KB
search corpus, but a pathological many-token prompt pays per keystroke.
Rectangles also sit behind text with padding choices that can look
ragged at line joins; only a screenshot settles taste.

### Rejected options
- RichText with escaped HTML and span colors. Escaping every segment
  and value can satisfy criterion 9 in principle, but it makes safety
  depend on an escape function staying correct against Qt's rich-text
  subset forever, and Qt rich text collapses whitespace and reflows
  lines unless forced into pre-style rendering, which then fights wrap.
  It also makes positionAt offsets answer questions about a parsed
  document instead of the plain string the values model uses. One
  missed escape is a criterion-9 failure; one PlainText string cannot
  fail it.
- No highlighting at all: braces for unset, naked values for filled.
  Filled values become indistinguishable from prose, an empty value is
  invisible, and the operator cannot see what is a variable without
  Tabbing through. That re-creates clunkiness in the opposite
  direction.
- Per-segment Text items each with its own color. Styling gets easy
  and the shape problem returns: it is the Flow candidate from Q1,
  with reflowed prose and per-segment layout.

### Evidence
- better-than-training · Qt 6.12 Text QML docs, read 2026-10-13 · for
  user-controlled untrusted content the format should be explicitly
  PlainText or the contents stripped of tags. Supports one plain
  string plus painted geometry over markup.
- better-than-training · local qquicktextdocument.h and plugins.qmltypes,
  read 2026-10-13 · no QML character-format or highlighter surface, so
  per-range color inside one item does not exist without C++. The
  choice is rectangles, markup, or many items.
- better-than-training · worktree qml/EditorBody.qml today · mirrors
  already distinguish unset (italic muted, raw `{{NAME}}`) from filled,
  and the footer counts unset from rebuild().unset. The vocabulary
  exists; this pick moves it onto one canvas.
- practitioner · VS Code snippet placeholders, same source as Q1 ·
  placeholders are shown selected and highlighted as a class distinct
  from surrounding text, and linked occurrences share the treatment.
  Supports state tinting per occurrence, including mirrors.

### Pitfalls and what removes each
- Stale rectangles after a font or theme change (look fork) or a
  resize. Removed by recomputing on textChanged, width change and the
  same theme-binding change that recolors them; the rectangles are
  derived state with no cache across layout passes (forceLayout before
  reading geometry).
- Empty value's click target is one character wide. Removed by giving
  the hit test the same minimum width as the drawn gap, and by Tab
  always reaching it regardless of the mouse.
- Color-only distinction between set-empty and unset could confuse.
  Removed by keeping the textual difference: unset literally reads
  `{{NAME}}`, empty reads as a gap, and the footer counts only unset,
  matching copy semantics.
- Highlight of a mirror changing while typing could flicker the whole
  canvas at large token counts. Bounded by recomputing only the
  affected name's occurrences per keystroke; full recompute only on
  layout changes. Prototype includes a many-token prompt (Q3).

### Questions the fork does not ask
- Should filled values lose their highlight once set, reading as pure
  prompt text (closest to "always looks the same"), with highlight
  reserved for unset and active? That is a taste call the operator can
  only make from a screenshot, and it weakens the "which words are
  mine" scan.
- Does the canvas use the menu font or a monospace face? Line-run
  geometry and code-fence alignment both change with the answer; it
  belongs to the look fork, but the prototype must run with whichever
  font that fork will plausibly pick.

## Q3. Prototype before handoff, or let the successor's plan decide Q1?

### Pick
Run a short time-boxed prototype before handoff, scratch only, aimed
at the pick in Q1 with Q2's rectangles. One standalone QML scene
(canvas, rectangles, floating field, values model stubbed from
lib/tokens.mjs segments) run under quickshell or qmltestrunner with
screenshots, about 60 to 90 minutes. Test matrix, in order: a token
spanning a wrap point opens and types without the field detaching; a
mirror before the active occurrence grows and the field stays glued;
a multiline pasted value opens, scrolls inside its field, commits and
reflows; an empty-set value is visible, clickable and Tabbable; a
many-token prompt (around 50 tokens) types without visible lag; a code
fence body keeps its line shape next to filled values. Pass means the
screenshots and interactions hold together at the real card size.
Fail on the wrap or multiline case sends Q1 back to the operator with
that evidence instead of into a brief.

Reason: the unknowns are geometric and cannot be settled from docs.
positionToRectangle exists, but its accuracy across wrapped lines,
its values before layout settles, and field-over-canvas behavior while
the text underneath re-renders are exactly the kind of thing this
project has repeatedly had to measure on this machine
(proofs-overlay.md exists because of that pattern). The mechanism also
leaks into other forks and the brief: mirror timing, click-meaning,
draft contents and test addressing all depend on it, so a plan seat
deciding inside the leaf would be re-answering operator-visible
questions without the operator. The uinput probe precedent in
proof-bar (operator 2a) settled a fork-blocking unknown in minutes the
same way.

Cost: about an hour of door time and screenshots the operator must
glance at, because "usable while covered" is partly taste. Scratch is
discarded; nothing prototype-shaped enters the successor's tree.

### Rejected options
- Successor's plan decides. The plan phase writes tests and freezes
  them at plan.synthesis to implement; a wrong mechanism choice there
  is discovered during implement or check, priced in fix rounds, with
  frozen tests written against addressing (value<i>, mirror<j>) that
  the redesign already invalidates. This leaf's predecessor left
  "editor mechanism left to leaf design" once, and F5 is the receipt
  for deciding it without the operator seeing the shape.
- No prototype, chart decides from documents alone. Everything in Q1
  and Q2 about wrap geometry, reflow under a floating field and
  rectangle raggedness is marked unproven above; a confident brief
  written on doc reading alone repeats the original sin in a new
  shape.
- Prototype candidate 1 (guarded TextEdit) as well, for fairness.
  Doubles the box to learn what the docs already say: its blockers are
  missing API surface (formats, linked ranges), not geometry, so a
  prototype can only re-measure guard fragility. If the Q1 pick's
  prototype fails, that is the moment to spend on candidate 1, with
  evidence in hand.

### Evidence
- better-than-training · proofs-overlay.md and proof-bar Taken probe
  2a result, read 2026-10-13 · this chart's pattern is small named
  probes with recorded pass conditions (input delivery, layer level,
  restart loading), and the uinput probe flipped two criteria in one
  run. Same tool, same size.
- better-than-training · archive design.md ("editor mechanism left to
  leaf design") and seed F5 · the cost of deciding editor shape inside
  a leaf without operator-visible evidence is the rework being charted
  now.
- better-than-training · Qt docs above · the needed methods exist,
  their layout timing and wrap behavior are unspecified at the level
  the pick depends on. That gap is measurable, not arguable.

### Pitfalls and what removes each
- Prototype passes at a toy card size or toy font and fails at the
  real one. Removed by running at the current card geometry
  (worktree Varhop.qml 560x480 cap) and with the font the look fork is
  heading toward if known, stated in the result.
- Prototype quietly grows into the implementation. Removed by the
  scratch rule: separate directory outside the worktree, deleted after
  screenshots and notes are filed in this fork.
- Screenshot judgment substituted for interaction. Removed by driving
  the matrix with the uinput keyboard (proof-bar probe route) where
  the claim is "typing stays glued", not by staging stills.
- A pass over-read as settling the look. The prototype uses placeholder
  colors; it settles mechanism and geometry only. The fork records
  that limit in its result.

### Questions the fork does not ask
- Who runs the prototype: the door (needs a live-desktop screenshot
  grant, like proof-bar 2a had) or the operator watching live? The
  wrap and cover judgments are faster with the operator present, but
  that schedules the operator inside charting.
- If the prototype fails the multiline case but passes prose prompts,
  is a hybrid acceptable (floating field for short values, expanded
  editing area for long ones), or is one mechanism for all values a
  requirement? That answer changes Q1's shape and only the operator
  can give it.
