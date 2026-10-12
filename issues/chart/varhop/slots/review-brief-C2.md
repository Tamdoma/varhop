# Consultant brief (slot C, pi): review the chart so far

You join a chart already in progress for "varhop", a native Omarchy prompt-library overlay. Give your independent view on everything decided and proposed so far.

Read, in this order:
1. INTAKE.md (operator's verbatim request) and CHART.md (destination, taken forks, open forks, fog, off route).
2. forks/form-factor.md and forks/repo-format.md: Taken sections are operator decisions. Challenge them only with concrete evidence that they will fail the destination; do not re-litigate taste.
3. forks/sync-and-auth.md (Question + Findings) and slots/sync-and-auth-merged.md, -rebuttal-B.md, -rebuttal-C.md. This fork is open; the operator is currently choosing:
   - Q1 copy form: 1a working shallow clone read from disk (A, old C) vs 1b bare clone read via git cat-file (B).
   - Q2 refresh cooldown on summon: 2a 10 min vs 2b 5 min; failed attempts also start the cooldown; Ctrl+R bypasses.
   - Q3 repo switch: 3a keep old library until new one imports vs 3b delete then clone.
   - Q4 gh account change: 4a remember login name, reconfirm repo vs 4b also key cache per account/repo id.
4. Remaining open forks in CHART.md (variable-editing, copy-and-close, search, settings-and-hotkey): name anything material they miss.

All paths are relative to /home/ivan/Work/omarchy-customizations/varhop/issues/chart/varhop/. Inspect the live system (/usr/share/omarchy, quickshell 0.3.2-4, Qt 6.12) where a claim depends on it. Read-only: no writes except your return file, no network writes.

Write, short and evidence-backed (file:line or URL + date read):
- Agree/disagree per sync-and-auth Q1-Q4 with your pick and why.
- Anything decided so far that you think is wrong or risky, with the failure scenario.
- Material forks, pitfalls or questions the chart misses.
- Skip restating agreement.

Return path (write exactly here): /home/ivan/Work/omarchy-customizations/varhop/issues/chart/varhop/slots/review-C2.md
