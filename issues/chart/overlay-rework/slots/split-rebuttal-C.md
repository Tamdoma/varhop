# Split rebuttal, slot C, 2026-10-13

Disagreements only:

1. B's objection that landing the base first "lands a version the
   operator called clunky" confuses main with the desktop. Landing
   installs nothing: the desktop copy stays at the same 0df6f48 it runs
   today under disposal 3a in both trees, and under B's tree it stays
   clunky for the whole single-leaf implementation. What landing
   changes is only where later work branches from. On disposal 4a and
   the seed: 4a's text settles slug and branch adoption only. Which
   leaf lists Tamdoma/varhop#1 is this fork's to settle, and source
   closure runs at owner completion, so the seed closes when the epic
   finishes either way.

2. A dedicated `overlay-proof-tools` leaf is not what the machinery
   rule requires. The rule is ordering: machinery must be on main
   before a criterion relies on it. A base leaf that commits the helper
   and merges before the rework leaf satisfies that order identically.
   B's leaf instead lands a sender script on a main that has no plugin,
   no QML test harness and nothing that consumes it, then still needs
   the adopted-base work inside the big successor. One lifecycle is
   spent proving a file in a tree that cannot use it yet (its
   known-good run must target the separately installed desktop copy,
   available under either tree).

3. T2 as framed is not a difference. The repo root is the plugin root,
   so a helper committed by a proof-tools leaf ships in the installed
   clone exactly as one committed by the base leaf does. If shipping a
   uinput sender troubles anyone, the fix is its path or an install
   exclusion, available under both trees, not a separate leaf.
