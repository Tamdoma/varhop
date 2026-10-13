# Controls rebuttal, Slot B

- **F1. D1 truncates my focus proposal.** Tab/Shift+Tab traverses the header buttons and returns to the body, not an isolated header cycle. F6 provides a direct return to saved body focus. Also, C's Esc-to-body proposal conflicts with the merged “Esc meaning unchanged everywhere”: editor Esc currently hides (`EditorBody.qml:222-224`). If that focus-dependent exception is offered, state it explicitly rather than tagging unchanged Esc as unanimous.

- **F2. D6 adds an unnecessary Tab trap.** Keep normal Tab reach from search/settings to the header. The picker Taken 4a makes its rows a composite control, not a permanently trapped query field. Only the editor's wrapped variable traversal requires a separate escape. Requiring the focus key everywhere broadens that exception and must be an explicit operator choice, not inferred from the picker decision.

- **F3. D3 should say Close when there is no return destination.** C's Back-that-hides label promises navigation that does not occur. The existing no-origin/no-selection `backRequested` branch already calls `hide()` (`Varhop.qml:923-932`). Label that action by its result. Likewise, the agreed settings Esc summary needs “back, or close when no valid return destination exists.”
