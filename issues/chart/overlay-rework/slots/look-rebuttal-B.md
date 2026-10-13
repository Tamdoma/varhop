# Look rebuttal, Slot B

Read only look-merged.md for this pass.

- **F1. The measured conclusion closes F2/F3 too broadly.** “The remaining F2 and F3 gap is font family, border and radius (A,B,C)” is not my position. One matching palette does not establish correct menu text roles or live theme updates, and token-equivalent sizes do not resolve the operator's small-text complaint. State that these are the visible differences in the measured screenshots. Keep readability, role selection and reactive updates as remaining requirements.

- **F2. “The screenshot must change” is an insufficient theme-update criterion.** The card could change while a loaded view keeps stale text colors, or two themes could resolve a tested role identically. Require each open view to adopt the new resolved roles, using a contrasting test palette that distinguishes menu text from global foreground. A screenshot can support that check, but any pixel change cannot establish it. This corrects the criterion attributed to B.

- **F3. A local background-alpha override does not necessarily double-compose with theme alpha.** Replacing the background color's alpha is different from multiplying it or applying item opacity. The merged rejection should distinguish these mechanisms. My alternative explicitly replaces background alpha and keeps foreground opacity intact. Its cost is overriding theme policy, not inevitably multiplying theme alpha. Preserve that scoped option alongside following menu alpha and an explicitly approved shared menu override, since changing every menu surface is a materially wider choice.
