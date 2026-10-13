# Disposal rebuttal, slot C, 2026-10-13

Disagreements only:

1. Successor slug. I hold reuse of `overlay-plugin` over A and B's new slug
   with a hand-created branch at `0df6f48`. The archive move has to happen
   under both options (it is the Q2 pick), so the duplicate-slug barrier is
   already paid for. After it, adoption (next.ts:325-333) needs no manual
   git step and leaves no second branch pointing at the same history to
   check ancestry against and later delete. A and B's route trades that for
   a door-created branch plus a cleanup of the old branch, two extra
   manual steps for the same starting code.

2. The merged line "old worktree must be removed first either way" overstates
   my evidence. The worktree path is keyed by slug, so the old worktree only
   blocks adoption on the slug-reuse route. On A and B's new-slug route it
   sits at a different path and blocks nothing. The check that matters on
   both routes is the one already listed: successor worktree HEAD is
   `0df6f48` and clean before editing.

3. Old tab wK:t7. I disagree with A closing it at retirement as a default.
   Its panes wK:pB and wK:pC match the B and C seat naming, so they may be
   hosting this chart's own peers. B's order is the safe one: verify what
   the panes host first, close only if they are the failed leaf's dead
   seats.
