# Picker rebuttal, slot C, 2026-10-13

Disagreements only:

1. Empty-field Enter picking the first row (A, B). The repo field grabs
   focus when settings opens, so this arms a repo switch behind a
   keystroke the user never aimed at a repo. Activation cost is the
   difference: an emoji or file pick is cheap and reversible, a repo
   pick starts a clone, a selection save, and possibly the
   draft-discard warning (Varhop.qml:328-338). With alphabetical order
   the armed repo on this machine is `apphutdev/aiva`, someone else's
   project. No highlight should exist until the user types or moves;
   Enter on an empty field does nothing.

2. Moving an exact match to first, or ranking prefix matches above
   substring matches (A, B). Any reordering makes row identity a
   function of the query, so the row under the user's eye moves while
   typing. It buys nothing here: the exact case is already resolved at
   Enter without touching order, and prefix tiers only matter when the
   list is too long to scan, which a substring on `owner/repo` over
   161 rows is not. Stable alphabetical order is the guarantee that
   the visible highlight is what Enter takes.

3. A selectable "Look up owner/repo" row, first (B) or last (A). A
   synthetic row inside the navigable list can be landed on by arrows
   or wrap, and partial text like `Tamdoma/var` already passes the
   strict regex, so the row would offer a network lookup for a repo
   that is really an unfinished filter. Discoverability does not need
   a row: the zero-match line can say a full `owner/repo` can still be
   entered, and Enter then runs the lookup. Pseudo-rows also pollute
   the row count every test and screenshot has to reason about.

4. Rows as individual Tab stops (B). The merged notes themselves record
   that hidden rows never sit in the Tab chain, which makes Tab reach
   depend on scroll position: a row is a control only while visible.
   That is less compliant with "every control works by Tab+Enter" than
   the composite reading, where the picker is one control, Tab reaches
   the field, and every row is reachable by typing and arrows. It also
   moves focus off the field, after which typing no longer filters
   unless keys are rerouted back, a pattern none of the first-party
   pickers need because they own keys centrally.

5. The "agreed" list includes locking the input while a lookup or
   switch is pending (B). I raised that as an open question, not
   agreement. Locking the whole input during a switch can trap the
   user in settings for a full clone with no stated Esc behavior. The
   narrower fix is staleness: a lookup result applies only if the
   field still holds the submitted text, and Enter during a running
   sync is already refused by startSync. Lock scope needs its own
   answer, not a merged-note default.

6. Clamp instead of wrap on Up and Down (B). This plugin's search view
   wraps (SearchBody move), and so do Emojis and Clipboard. Two list
   behaviors one screen apart is a needless inconsistency for zero
   gain at 161 rows, where wrap is how a user reaches the end quickly.
