# Controls fork: blind notes, Slot B

2026-10-13. Read controls Question and Carries and permitted context. No other slots' controls notes read. No desktop changes made. Recommendations below need the operator's choice.

## Q1. Where should Back and Settings appear, and what should they look like?

### Pick, reason and cost

Use one persistent header above the scrolling body, with ordinary text buttons and consistent positions. Search has Settings on the right and no Back button. Editor has `Back to prompts` on the left and `Settings` on the right. Settings has `Back` on the left when entered from another view, with a Settings title instead of a redundant Settings button. In first-run settings with no return destination, label the action `Close`, not Back.

Show the existing shortcut beside the relevant label where space allows: `Back to prompts  Ctrl+P` and `Settings  Ctrl+,`. A short persistent editor hint explains the focus key proposed in Q2. Apply the chosen menu font, focus and selection roles rather than inventing a second visual style.

Reason: both requested actions become visible without scrolling or knowing an icon. Cost: a header consumes some vertical space, and explicit text is wider than a cog. Reserve its height outside the content area so it never covers the prompt or focused field.

### Rejected options

- An icon-only cog and arrow: smaller, but weaker for the reported discoverability problem. Tooltips should not be the only labels.
- Put controls at the end of each scrolling body: they disappear on long prompts and settings pages.
- Add an action menu containing just these two actions: introduces another activation step without solving a missing direct control.
- Add Back on root search or Settings inside Settings: produces an action with no useful destination.

### Evidence, tier, source and date

- **Operator**, INTAKE F6/F7, read 2026-10-13: explicitly cannot find back navigation or settings.
- **Practitioner**, Raycast team, makers of a keyboard-first launcher, [Action Panel manual](https://manual.raycast.com/action-panel), read 2026-10-13: displays shortcut hints alongside actions so users can learn the direct keys. This supports visible action labels and hints, not copying its entire action panel.
- **Better-than-training**, worktree `Varhop.qml:780-813` and `qml/EditorBody.qml:222-229`, read 2026-10-13: navigation exists in key handlers without equivalent visible entry points. A shell-level header can share those routes across the three loaded views.

### Pitfalls and removal

Use focusable buttons whose pointer and Enter activation call the same action. Hide unavailable controls from the focus chain. At the chosen larger font, verify labels fit and the body scroll area remains usable. First-run Close must hide without claiming that a usable prompt list exists. A fatal recovery screen must not expose a Back action into a known-invalid library merely to keep header symmetry.

### Missing question

No additional visual feature is needed. Decide text buttons versus compact icons within this question. Recommend text because these are the two specifically undiscovered actions.

## Q2. How does keyboard focus reach the header without changing variable Tab order?

### Pick, reason and cost

Use `F6` to move between the view body and header. From the editor body, F6 focuses the first available header button while preserving the active variable, caret and selection. In the header, Tab/Shift+Tab moves through the visible buttons and back into the body. F6 from the header returns directly to the saved body focus. Once the editor regains focus, Tab/Shift+Tab again traverses unique variable names with wrap, unchanged.

Display `Tab: variables · F6: controls` in the editor. Search and Settings keep ordinary Tab traversal through their body controls and header, with the repo picker treated as the already approved composite control. F6 can provide the same direct header access there. Clicking into the header must preserve editor state just as keyboard focus does. No header-focus action should unload the editor or capture a different active variable.

Reason: separates text navigation from control navigation without a persistent toggle mode. Cost: editor users must learn one extra key. **This explicitly adds a focus escape before Tab+Enter.** If the existing proof contract means Tab alone must reach every action from every starting focus, it is incompatible with a permanently wrapped variable cycle. The operator must approve this interpretation or change that cycle. Do not claim F6 was already authorized by the picker exception.

### Rejected options

- Append Back and Settings to the variable cycle: violates the carried wrap over unique variable names.
- Trap Tab forever and rely only on Ctrl+P/Ctrl+,: offers direct shortcuts but does not make the buttons reachable as focusable controls.
- Introduce a sticky “Tab moves focus” mode: valid in a full editor, but adds hidden state here when a direct focus transfer is enough.
- Use Esc to escape into the header: changes the existing hide/back behavior and makes repeated Esc harder to predict.

### Evidence, tier, source and date

- **Operator**, controls Carries, editor Taken and proof-bar Taken, read 2026-10-13: variable Tab wrap stays, controls need keyboard reach, and only list rows have received a composite-control amendment.
- **Practitioner**, Microsoft VS Code team, [Accessibility documentation](https://code.visualstudio.com/docs/configure/accessibility/accessibility), read 2026-10-13: explicitly provides an escape from editor Tab trapping through a focus mode. It establishes the need for a deliberate escape, not a requirement to use VS Code's Ctrl+M or my proposed F6.
- **Better-than-training**, worktree `qml/EditorBody.qml:199-208`, read 2026-10-13: current `stepName` wraps over variable names. No number of ordinary Tabs can leave that cycle. This is a structural conflict, not a missing Tab-order entry.

Practitioner synthesis: Raycast makes actions and their keys visible, while VS Code provides an explicit way out of editor Tab handling. For this small overlay, combine a visible focus hint with a direct focus transfer. A large editor with many focus regions could justify the persistent mode that is unnecessary here.

### Pitfalls and removal

Keyboard dispatch must respect the focused control. A header Enter must activate exactly one button, not bubble into search-result acceptance, repo lookup or copy. Body-specific arrow and Enter handlers must run only in their body context. Restore caret/selection without selecting all or resetting variable undo history. Verify F6, Tab, Shift+Tab and Enter from editor body and header, including a prompt with zero variables, where F6 still works. Verify the actual F6 event reaches the installed overlay during the already authorized keyboard proof rather than assuming no compositor interception.

### Missing question

Approve F6 as the editor's focus escape, or explicitly relax the wrapped variable cycle. This is the material unresolved question. A picker exception alone cannot settle it.

## Q3. What do Back, Settings and Esc do, and what state survives?

### Pick, reason and cost

Keep existing key meanings and expose their actions visibly:

| Context | Visible action and key | Result |
| --- | --- | --- |
| Editor | Back to prompts / Ctrl+P | Save the current draft and return to the previous query and prompt selection. |
| Search or editor | Settings / Ctrl+, | Open settings, recording the originating view and preserving any editor draft. |
| Settings entered from a view | Back / Ctrl+, | Return to that origin. Returning to the editor restores its draft state. |
| First-run settings without a usable return view | Close | Hide the overlay. |
| Search | Esc | Clear a non-empty query, otherwise hide. |
| Editor | Esc | Hide while preserving the draft. It does not mean Back to prompts. |
| Settings | Esc | Clear a non-empty repo filter first, as already chosen. Otherwise use its Back or Close action. |

Keep Ctrl+Shift+P resume and other unrelated editing shortcuts as they are. Do not make Back discard a draft. After a repository switch or recovery invalidates a saved editor destination, respect the existing valid-state routing rather than resuming a discarded draft.

Reason: adds the missing affordances without remapping established editing behavior. Cost: Esc remains contextual, and a non-empty settings filter takes an extra Esc before leaving. Labels and the existing shortcut hints explain the explicit Back route.

### Rejected options

- Change editor Esc to Back by default: plausible launcher behavior, but changes current hide/resume semantics beyond adding the missing button.
- Treat Back as “close overlay”: does not satisfy F6's request to return to the prompt list.
- Route Settings Back always to search: loses the originating editor context.
- Copy the current key-handler branches independently into click handlers: would preserve their existing differences and make future navigation drift likely.

### Evidence, tier, source and date

- **Operator**, F6 and picker Taken, read 2026-10-13: Back means editor to prompt list, and settings Esc must clear the repo filter first.
- **Better-than-training**, worktree `README.md:55-64`, `Varhop.qml:792-808,865-877,923-932`, and `qml/EditorBody.qml:185-196,222-229`, read 2026-10-13: documents Ctrl+P, Ctrl+, and draft preservation, with existing capture and return paths. Ctrl+, settings return and `backRequested` currently have different no-origin behavior, so adding buttons requires one deliberate destination rule rather than copying both branches.
- **Practitioner**, Raycast team, [Navigation API](https://developers.raycast.com/api-reference/user-interface/navigation), read 2026-10-13: Raycast uses Esc to pop the previous view. That is a credible alternative, but this task's existing editor hide behavior and chosen settings filter handling make a wholesale adoption inappropriate without an explicit remap choice.

### Pitfalls and removal

Extract or reuse one action per navigation transition so buttons and shortcuts preserve identical state. Capture the draft before a Loader destroys the editor, including active variable, selection and undo/redo state. Component checks compare button and shortcut outcomes, including restored search query/selection, editor round-trip through settings, initial setup, recovery and no usable return destination. Existing live draft-resume proof should also exercise the visible Back and Settings routes on the final build. These are acceptance requirements, not claims that the current paths already pass.

### Missing question

Does the operator want to deliberately remap editor Esc to Back? Recommend retaining hide and showing `Back to prompts  Ctrl+P`; it meets F6 without changing the established resume behavior. First-run Close is a destination-correct label for the same header position, not an additional independent control.
