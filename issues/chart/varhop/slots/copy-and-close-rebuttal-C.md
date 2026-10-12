# Copy and close: rebuttal C (disagreements only, 2026-10-12)

RC1. D-a: concede A,B. Ctrl+C in the editor always copies the whole rebuilt prompt; the operator's explicit spec (INTAKE.md) outweighs my selection-copy heuristic, and one stage-scoped rule needs no auto-selection tracking. Search/settings native selection copy stands as merged.

RC2. D-b: concede B. Esc hides from the editor; it is not a back key anywhere in this shell: nested Menu pages cancel on Esc and use Left/Backspace for back (plugins/menu/Menu.qml:1241-1249), and PanelKeyCatcher maps Esc only to closeRequested (Ui/PanelKeyCatcher.qml:56-57). B's separate "Find another prompt" action becomes a named binding debt for settings-and-hotkey; without a key assigned there, this is not settled, only relocated.

RC3. D-c: hold C. In search, first Esc clears a non-empty query, second Esc hides. That is the uniform first-party search habit, not only clipboard: Clipboard.qml:355-357, Emojis.qml:196-199, Menu.qml:1241-1243 all clear-then-close. A,B's hide-with-query-retained leaves the next summon filtered by a query the user thought they had escaped from, and the hotkey toggle already covers "hide and keep my place."

RC4. D-d: concede B. Empty rebuilt output is a valid copy: wl-copy 2.3.0 dumps stdin to a file and offers it with the explicit MIME type regardless of length (wl-copy.c, stdin and source-offer path, read 2026-10-12), so my "nothing to copy" refusal was a special case the transport does not need.

RC5. Missed by the merge: B's Q7 (Super+C) vanished, and local evidence makes it concrete. Omarchy's universal-copy binding sends Ctrl+C or Ctrl+Shift+C to the focused surface depending on whether the active window is tagged terminal, and its comment states the intent to reach focused layer-shell surfaces (/usr/share/omarchy/default/hypr/bindings/clipboard.lua:1-7,46). A varhop overlay summoned over a terminal therefore receives Ctrl+Shift+C for Super+C. Either the editor handler treats Ctrl+Shift+C as the same whole-prompt copy, or settings-and-hotkey records why universal copy differs inside varhop; leaving it unexamined means the same physical chord works over a browser and does nothing over a terminal. The same file sends Ctrl+Shift+V for Super+V (clipboard.lua:47), which the variable-editing paste proof should include.

RC6. Tag corrections in Agreed Q4.
- "Opening a different prompt replaces it without confirm; one in-memory draft" is tagged (A,B,C). A's notes say only that a draft is "kept for that prompt" (copy-and-close-A.md Q4); replacement and the one-draft cap are B Q8/D4 and C Q4. Tag (B,C).
- "Draft survives normal theme changes" is tagged (A,B,C), but A's notes price the opposite ("a theme change or shell restart mid-edit loses typed values"). B's E10 evidence (shell.qml:1764-1777 applyTheme updates Commons.Color in the running shell) is decisive for (B,C); if A now agrees, record it as a concession like hide-on-start, not a blind-note agreement.
