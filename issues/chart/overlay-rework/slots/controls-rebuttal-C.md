# Controls rebuttal, slot C, 2026-10-13

Disagreements only:

1. The agreed line "Esc meaning unchanged everywhere" omits the chrome
   exception in my pick and tags it to me. In both D1 designs Esc inside
   the header context must return focus to the content, or there is no
   cancel for the focus excursion; only content-context Esc keeps its
   locked meaning (hide in the editor, clear-then-hide in search). As
   merged, the line reads as a promise the D1 options themselves break.

2. D6, normal Tab also reaching the header in search and settings (B).
   That gives two entry rules whose availability depends on the view: the
   focus key everywhere, Tab only where the view tolerates it. In search
   the field is a TextArea whose whole job is absorbing keys; Tab leaving
   it mid-filter is the surprise, and in settings the header joins a Tab
   chain whose length changes with the view's field count. One entry key
   in every view is the only version statable in one hint. Search and
   settings fields keep their own natural Tab order among themselves.

3. D2, no Settings button inside settings (B). The agreed header is a
   fixed row; removing its right button in one view makes the fixed
   target appear and vanish, and the header loses its "you are here"
   marker exactly where a first-run user landed without choosing to.
   The kit already has the right rendering for this: the active state
   (Ui/Button.qml state precedence). An inert active button is
   information, not clutter. It stays out of that view's focus cycle.

4. D3, relabelling the button "Close" when settings has nowhere to go
   back (B). The label would change on invisible state (cameFrom,
   selection) for the same slot in the same row, so the control's name
   stops being learnable. One label, Back, with the existing
   backRequested wiring deciding the destination (Varhop.qml:923-932),
   keeps position and name as the identity; the header title states
   where the user landed afterward.
