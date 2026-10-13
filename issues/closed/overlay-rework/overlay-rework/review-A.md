# Review A: overlay-rework (check.review)

Base b210f39. Reviewed head fa71cf0. Verdict: **fix**.

## Verification evidence

- `test` check on fa71cf0: run 1 red (1 case, a lost key click), retry green 84/84. Record `implementation/compare-test.yaml` (inconsistent, accepted by the phase move). No code change since, so I did not rerun it.
- Live W4 steps 3-9 on fa71cf0 (`scratch/live.md`): Ctrl+Tab, OA2, OA3 over terminal and browser, OA1, reset isolation and restore all pass.
- Reproduction for the QV4 crash: e0081df red (SIGSEGV) on 323d3f2, green on fa71cf0.
- Diff scan: no `console.*`, TODO or debugger lines added. Trailers: e0081df names its real source (live coredumps). 61e137a cites plan.md criteria for the two test runners it extends.
- Docs: README's key table matches the header keys, Ctrl+Tab and the picker's Esc order. No AREA.md is in the diff. `docs/reference-index.md` is unaffected, as the plan states.

## Fixes

F1. **Settings does not scroll to the focused control, so Tab and Enter act on controls the user cannot see.**
- Source: a real user action on the operator's own account. In live W4 step 8 (scratch/live.md), the picker shows its full 8 rows for an account with dozens of repos. Tab goes field → Sync now → Hotkey → Reset usage, and Hotkey and Reset sit below the 480 px card edge. The screenshots at that step show focus nowhere on the card. Enter then reset usage for the repository with no visible focus.
- Cause: `qml/SettingsBody.qml:149` wraps the content in a `Flickable` with `contentHeight: col.implicitHeight` and nothing moves `contentY` when focus changes. This diff adds the 8-row list (D5) and makes Hotkey and Reset Tab stops (D6, Q4 4a), so it creates this keyboard path.
- Consequence today: a keyboard user presses Enter on a control they cannot see, and the hidden one is the data-changing "Reset usage for this repository".
- Hits: criterion 5 (keyboard equivalents, Q4 4a "every mouse action is also reachable by Tab and activated by Enter"). A control focused off-screen is not usable by keyboard.
- Smallest fix: when the window's active focus item is inside the Flickable, adjust `contentY` so that item is fully visible.

## Nits

N1. **Back after a confirmed repo switch can reopen the previous repo's prompt.** Open a prompt, then Ctrl+,, switch repos and confirm, then press Back. `finishSync` clears `card.draft` but leaves `cameFrom === "editor"` and `currentPrompt` from the old library, so `leaveSettings()` shows the old prompt. A copy would then record its id in the new repo's usage file.
- Deferred: base b210f39 has the same `cameFrom` routing (Varhop.qml:924-925 at base), so this diff does not introduce it. I did not observe it live, because the overlay hid before Back was pressed in step 7.
- Promote to a Fix with a live run of that sequence showing the old prompt after the switch.

N2. **`test_theme_roles_bind_live` uses real `keyClick` into a Wayland window**, and lost one key once while the operator was active (compare-test.yaml).
- Deferred: the retry was green, and the plan names this suite as the proof runner.
- Promote it if it goes red again on an idle session.
