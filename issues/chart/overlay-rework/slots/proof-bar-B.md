# Proof bar: blind Slot B notes

2026-10-13. Read Question and Carries only from the proof-bar fork. No other slot's proof-bar notes were read. Only this return file was written. No input was injected, software installed, or desktop state changed.

Paths: `H` = `issues/chart/overlay-rework/archive/overlay-plugin` under the varhop repository; `W` = `/home/ivan/.akrogon/worktrees/varhop/overlay-plugin`; `S` = `/usr/share/omarchy`.

## Q1. Which live outcomes must pass before merge, and who proves them?

### Pick, reason and cost

**Recommend retaining OA2 and OA3 as pre-merge outcomes, with one attended operator acceptance pass on the final redesigned editor.** Retain actual mouse activation checks where pointer interaction is promised. Q3 can remove the physical-click dependency from reset-isolation proof, but cannot prove that mouse clicks work.

These checks cover the central edit/resume/paste workflow. The redesign invalidates the old editor evidence, and the report records real live paste attempts producing no insertion. Deferring all of this would allow the replacement to land without evidence that its ordinary input workflow works. Cost: the operator must participate in a final acceptance session. Establish ownership and availability during charting, not after another repair loop. Do not mark the actual acceptance complete until the final-build checks run.

Correct the question's premise: **the evidence establishes failed attempts using particular injection methods, not that no agent can ever perform these checks or that layer surfaces universally ignore synthetic clicks.** Today, read-only `hyprctl devices -j` lists a `logitech-mx-master-3s` mouse and `mx-keys-s` keyboard. The archived claim that the machine has no physical pointer is stale. This establishes device presence only, not successful physical or automated interaction.

### Rejected options and reasons

- **Move all OA2–OA4 checks after merge:** not the recommended default for basic editing and clipboard behavior. The earlier deferral covered middle-click, dead keys and IME preedit, not ordinary paste or exact resume. If the operator chooses post-merge acceptance, name each unproved outcome and its owner explicitly. Preserve component coverage and the checklist. Record physical failure as a defect, not an accepted environment exception.
- **Make new automation machinery a mandatory prerequisite now:** plausible, but unnecessary if an attended acceptance pass is acceptable. The installed Omarchy helper can install/configure ydotool, but it has not demonstrated these outcomes here. This adds system setup and proof work, not a guaranteed solution.
- **Accept component tests as complete live evidence:** component tests can establish state and widget behavior, but cannot settle the known difference between the test window and the running overlay. Keep them as regression coverage, not a substitute for the disputed integration outcomes.

### Evidence: tier, source and date

- **Operator, read 2026-10-13:** the supplied intake requires a working inline prompt editor. The disposal Taken decision retains the existing installation and requires final deployed-state verification. Neither decision waives the input outcomes.
- **Better-than-training, read 2026-10-13:** `H/review-B.md:445-455` identifies exact selection and paste outcomes still missing, and expressly warns that physical paste failure is product/root-integration evidence. `H/implementation/report.md:188-198` documents unsuccessful pointer attempts. Those observations do not establish universal impossibility.
- **Better-than-training, measured 2026-10-13:** `hyprctl devices -j` now lists the physical mouse and keyboard above. `command -v ydotool wtype dotool wlrctl` found only `/usr/bin/wtype`. `/dev/uinput` exists as `crw-rw----+ root root`; the current process groups are `ivan nordvpn wheel`. The ACL marker means those mode/group observations alone do not establish whether this process has effective uinput access.
- **Practitioner/primary, read 2026-10-13:** the [ydotool maintainers' implementation documentation](https://github.com/ReimuNotMoe/ydotool#notes) explains that it emulates input through uinput and keeps a persistent virtual device because compositor recognition takes time. This makes a persistent-device probe a credible alternative to short-lived injection. It does not prove clipboard, focus or layer interaction on this installation.
- **Better-than-training, read 2026-10-13:** `S/bin/omarchy-dev-install-ydoo:15-42` may add input-group membership, install a package, write a udev rule, adjust device access and start a service. Its service-active check at `:44` is not an overlay click test. Nothing was executed from that helper.
- **Operator lock, read 2026-10-13:** `issues/chart/varhop/forks/settings-and-hotkey.md:59` previously kept the browser/terminal key-state proof agent-run and merge-blocking. Choosing an attended check changes that proof-owner lock and must be recorded explicitly. `issues/chart/varhop/forks/variable-editing.md:33` deferred only the three named special input cases.

### Pitfalls and what removes them

- **R1. Another leaf reaches the same human-only stop.** Before dispatch, settle the proof owner and acceptance procedure. For operator proof, arrange the attended final-build session. For automation, deliver and prove the missing capability first. Keep each obligation pending until its actual outcome is observed.
- **R2. Installer success is mistaken for useful automation.** If machinery is selected, demonstrate pointer motion/click, nontrivial selection, hide/resume and literal clipboard insertion on an actual layer surface. Include an observed known-good case and a deliberately broken case that the check detects. Test the real plugin afterward. A top-level window click is insufficient.
- **R3. Old editor or old loaded QML supplies the evidence.** Verify deployed files/revision, load the changed code through the recorded restart procedure, then test OA2/OA3 against the new editor. Save and restore both clipboard selections. Do not delete the pre-existing installation/cache/state as fixtures.
- **R4. Q1 conflates outcome and input route.** Record separate rows for exact resume, browser/terminal paste-copy, reset isolation and physical mouse activation. Keyboard reset can establish isolation without establishing mouse delivery.

### Missing question

Can the operator commit to one attended final-build acceptance session, or is unattended completion itself required? That requirement should determine whether automation is worth a prerequisite. The question also needs to distinguish a test that could not establish its starting state (OA2) from one that established focus/input attempts but observed no insertion (OA3).

## Q2. Which second repository proves successful switch with a draft?

### Pick, reason and cost

**Recommend keeping the real switch success path as a merge criterion and asking the operator to name and authorize one existing readable GitHub repository containing a valid prompt.** No specific second repository has been supplied, so none is selected here. Read access, numeric identity, local clone/cache handling and retention terms must be settled before handoff.

Cost: one additional target authorization and a real import/switch run. This is a missing input, not inherently a physical-only check. Use the same gh identity, verify the second repository is genuinely distinct, open a draft, confirm the switch warning, and verify successful import discards that draft. Restore the operator's selected repository afterward under the retained-install contract.

### Rejected options and reasons

- **Defer the entire switch test merely because OA1 was grouped with physical checks:** its blocker is target authorization, not input-device limitations. It is usually cheaper to resolve the input than lower the proof bar. Explicit deferral remains an operator choice if no suitable target is available.
- **Create a repository without a new decision:** the old grant expressly excludes creation. Creation is an additional option only if an existing target cannot be supplied, with its own ownership and cleanup terms.
- **Use the same repository or only injected library data as equivalent evidence:** this does not establish a successful switch between distinct remote identities through lookup, clone, import and acceptance. Component tests should still cover successful/failed switch state transitions, but they prove a narrower boundary.

### Evidence: tier, source and date

- **Operator grant, read 2026-10-13:** `H/readiness.yaml:9-18` names the gh keyring identity and only `Tamdoma/varhop-prompts` for repository lookup/clone. It prohibits repository creation/deletion.
- **Better-than-training, read 2026-10-13:** `H/review-B.md:439-443` records that no denied-access response was observed. The second lookup was not attempted because the target was outside the grant. It explicitly says an authorized existing repo is sufficient and creation is unnecessary.
- **Operator lock, read 2026-10-13:** the disposal Taken decision requires keeping the installed selection through replacement. The proof's temporary switch therefore needs explicit restoration rather than leaving the test target selected.

### Pitfalls and what removes them

- **R5. Guessing a repo from account access.** The operator names the target and permits the actual lookup/clone operations. The door verifies access and usable prompt content before the successor depends on it. Do not infer authorization from a repository appearing in a picker.
- **R6. Success is asserted while only lookup worked.** Verify distinct repo identity, successful accepted import and draft discard on the deployed build. Retain failure-path evidence that an unsuccessful switch keeps the draft and previous library.
- **R7. Test leaves user state changed.** Record the original selection and affected data before running, restore them afterward, and compare. A second local usage file for reset isolation does not itself require a second remote repository.

### Missing question

Ask for the exact `owner/repo` and read-only authorization together. If none is available, offer an explicit choice between a scoped disposable repository and deferring only the remote end-to-end switch proof. Do not bundle OA1's decision with physical input deferral.

## Q3. Must every interactive control also work from the keyboard?

### Pick, reason and cost

**Yes. Require every user action to be keyboard-reachable, with visible focus or a discoverable shortcut.** This suits the hotkey-driven product and removes mouse-only activation as a dependency for reset, navigation and repository selection. Cost: deliberate focus handling and tests across views, especially the editor's locked Tab cycle.

Keyboard-reachable does not mean making every row and button an extra Tab stop. Search rows can use Up/Down/Enter. Editor Tab/Shift+Tab must continue walking unique variable names. Back/settings can retain their documented shortcuts alongside visible controls. New controls should invoke the same action path as pointer activation.

### Rejected options and reasons

- **Leave some actions mouse-only:** preserves the reset blocker and makes a keyboard-driven workflow incomplete.
- **Add a test-only IPC or call reset logic directly:** exercises a different entry point and leaves users with the same inaccessible control. It is not evidence that keyboard activation reaches the UI action.
- **Claim OA4 automatically solved by adding a focus flag:** implementation and deployed verification are still required. Existing injection trouble means availability of a key handler is not sufficient proof that the agent can activate it here.
- **Replace mouse coverage entirely:** keyboard proof establishes the keyboard route. Pointer support still needs its own component/live coverage according to Q1.

### Evidence: tier, source and date

- **Better-than-training, read 2026-10-13:** `W/qml/SettingsBody.qml:374-386` makes reset a MouseArea-only action. `W/Varhop.qml:914-921` connects its signal to usage reset/write. A keyboard-enabled control can use that same signal rather than bypass the root wiring.
- **Better-than-training, read 2026-10-13:** installed `S/shell/Ui/Button.qml:32`, `:66-69` provides optional focus and Return/Enter/Space activation. This establishes a local pattern, not a requirement to import that component into the currently plain QtQuick view architecture.
- **Operator lock, read 2026-10-13:** `issues/chart/varhop/forks/variable-editing.md:28-29` reserves the editor Tab cycle for unique names and permits multiline entry. A generic form focus chain must not replace it.

### Pitfalls and what removes them

- **R8. New navigation steals editor Tab or resets the draft.** Test the focus/shortcut paths from an edited value, preserve the locked variable cycle, and verify round-trip cursor/selection state under Q1.
- **R9. Reset isolation is inferred from an emitted signal.** Activate the actual deployed reset control through the chosen keyboard route, verify selected-repo usage clears, and byte-compare a second repo-id usage file unchanged. Restore both fixtures/user state. No real second GitHub repository is needed for this isolated storage check.
- **R10. A focused button exists but cannot be reached.** Test entering and leaving each view using the keyboard, then reaching and activating each action. Include visible focus and disabled/busy states where present, without expanding the feature set.

### Missing question

Does Q3 replace only OA4's required activation route, or also waive physical mouse acceptance? Recommend the former. That distinction must appear in the successor's criterion-to-evidence table so “reset passed” cannot be read as “mouse clicks passed.”
