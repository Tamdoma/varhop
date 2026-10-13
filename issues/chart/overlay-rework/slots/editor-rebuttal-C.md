# Editor rebuttal, slot C, 2026-10-13

Disagreements only:

1. Prototype order and box. A's recommendation prototypes both mechanisms
   in about 60 minutes, M1 first. That box is not credible for M1: a fair
   M1 test has to build the guard, the post-change verifier, mirror
   rewrites around a live cursor and per-name undo interception before
   any of its pass criteria can even run. An M2 test builds none of that,
   it measures placement geometry on top of the field machinery that
   already exists. Testing the cheap decider first is the right order:
   M2 at the real card size, and M1 only if M2 fails. Splitting one hour
   across both most likely ends with two inconclusive halves and the
   mechanism still undecided.

2. M1's pass criteria contradict the merged Q3 line and are partly
   undecidable here. The corpus line says menu paste, menu Undo and IME
   composition must be covered "or record them unproved", while the
   recommendation says M1 passes only if IME composition keeps prose
   fixed. This host's input method is keyboard-hr only, with no preedit
   engine, so preedit composition inside a guarded document cannot be
   produced in the prototype at all. Under "or record unproved", M1 can
   pass with its single largest risk untested, and that risk then
   resurfaces only on the operator's IME if one is ever installed. A
   pass with IME unproved should not count as M1 passing.

3. "C falls back to M1 if M2 fails" misstates my position. My fail path
   returns Q1 to the operator with the prototype evidence, where M1,
   a hybrid for long values, or relaxing which prompts must render
   inline are all live options. Recording M1 as the agreed automatic
   fallback spends the operator's decision before the evidence exists,
   and it is what lets the merged recommendation run M2 "in the same
   box" as a consolation instead of as the main test.
