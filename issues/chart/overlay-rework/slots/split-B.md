# Split fork: blind notes, Slot B

2026-10-13. Read split Question and Carries, settled forks, owner index, skill Drain/Handoff and shapes audit. Inspected the retained branch and main read-only. No other split notes read.

## Q1. How many product leaves, and who owns them?

### Pick, reason and cost

Keep one product successor, `issues/open/varhop/overlay-plugin`, under the existing `issues/open/varhop/ISSUE.md`. Add the proof-machinery prerequisite described in Q3, making two proposed leaves total. The product leaf owns the carried plugin plus editor, look, picker, controls and final integrated behavior. Preserve the chosen slug, branch adoption, sources and owner-level seat configuration.

Reason: the retained branch delivers the entire plugin, not a small patch to a plugin already on main. The selected successor can accept that base together with the requested rework without first landing an intermediate version that the operator found clunky. Cost: larger product review and less lifecycle-level feature parallelism. This does not prohibit independent implementation units within that leaf.

### Rejected options

- Four feature leaves dispatched independently from main: none has the plugin entry point, views or manifest to modify. Shared files are not the reason to reject this layout. Missing product code is.
- A separate base-plugin leaf followed by parallel editor/picker/look/control leaves: technically valid once the base is independently accepted and merged. It adds an intermediate product landing and changes what the chosen `overlay-plugin` successor delivers. Do not silently reinterpret the disposal decision that way.
- A new issue or epic: same destination and existing owner, with no independently operated product requiring another container.

### Evidence, tier, source and date

- **Operator**, disposal Taken Q1/Q4 and CHART Handoff choices, read 2026-10-13: successor continues existing code, reuses `overlay-plugin`, lives under `issues/open/varhop/`, and inherits seats from that ISSUE.md.
- **Better-than-training**, git inspection 2026-10-13: retained worktree is clean at `0df6f48`. `git diff --stat main...0df6f48` shows 19 files, 3,297 insertions and 33 deletions, including the new manifest, root, all views, tests and library performance changes. Main has prompt-core and repo-sync but no plugin root/views.
- **Better-than-training**, chart skill Drain and shapes owner rules, read 2026-10-13: independently checkable outcomes may be parallel leaves. File overlap never establishes dependency.

### Pitfalls and removal

Do not infer “one leaf is mandatory” merely from the unmerged branch. Independent changes could be developed against that common base, but a split must explicitly own acceptance and landing of the base. Under the proposed bundle, a criterion-to-evidence table assigns all carried behavior and new outcomes to the successor, preventing old regression fixes from disappearing behind the visual changes.

### Missing question

Is an independently accepted intermediate base landing wanted to unlock separate feature leaves? Recommend no. If yes, redraw ownership explicitly rather than treating branch ancestry as an incidental merge detail.

## Q2. What order and blocked-by entries are real?

### Pick, reason and cost

Proposed order: `overlay-proof-tools` merges first, then `overlay-plugin` consumes its reusable live-input/evidence machinery. Only `overlay-plugin` lists `blocked-by: [overlay-proof-tools]`. The prerequisite has no product dependency. Both remain children of the existing varhop issue. Already merged prompt-core and repo-sync need no new sequencing leaf.

Within the product leaf, picker filtering and editor logic can be developed independently against the retained base. Final theme/highlight/focus integration and live proof must use the combined implementation. Cost: product dispatch waits for tools, but its final checks have a defined implementation instead of another improvised proof attempt.

### Rejected options

- A serial editor → look → picker → controls chain: neither shared QML files nor preferred presentation order makes those dependencies real.
- Tools blocked by the product whose acceptance needs those tools: circular. Prove tools against a small controlled fixture without requiring the new editor.
- Parallel live runs on this desktop: the shared shell, input focus and clipboard force serial sessions. That resource restriction does not force serial code development.

### Evidence, tier, source and date

- **Better-than-training**, `issues/open/varhop/{prompt-core,repo-sync}/state.yaml`, read 2026-10-13: both are merged.
- **Operator**, proof-bar and controls Taken, read 2026-10-13: final input delivery, exact resume, copy bindings and Ctrl+Tab reach need installed-build evidence.
- **Better-than-training**, shapes audit, read 2026-10-13: a dependency names the consumed output, resolves to a real leaf and has no cycle.

### Pitfalls and removal

Record the retained clean `0df6f48` baseline before integrating prerequisite changes. Reconcile the reused branch with the prerequisite's merged output through the lifecycle's supported branch update path, retaining its plugin commits and installed origin. Acceptance must run on the resulting combined revision, not the original hash. No leaf owns edits under `issues/`; index, seat block and lifecycle records remain door work on main.

### Missing question

None beyond approval of the concrete two-leaf tree. Exact prerequisite slug remains subject to the door's collision checks.

## Q3. Should proof machinery or proof close-out be separate?

### Pick, reason and cost

Propose `overlay-proof-tools` as a narrow prerequisite delivering the missing reusable live proof support: controlled keyboard delivery and observable outcomes, with the state/clipboard cleanup needed by its consumers. Reuse existing helpers where appropriate. It must demonstrate a known-good case passing and a deliberate broken case failing, with cleanup on either outcome. Do not build a general desktop automation framework or encode the final editor's expected behavior into the machinery leaf.

Keep final product checks and repairs in `overlay-plugin`; do not add a proof-only close-out leaf. Cost: an extra small contract and merge. It removes the unowned step between “uinput can type” and repeatable evidence on the installed final plugin.

### Rejected options

- Treat the scratch probe or deleted prototype as delivered machinery: neither is a reusable checked-in runner on main.
- Hide missing shared tooling inside the product's acceptance work: the skill explicitly requires an independently provable missing machinery prerequisite, or an operator-approved narrower criterion.
- Separate final proof from product ownership: lets incomplete behavior land while another leaf discovers and repairs it. Component and live product outcomes should remain obligations of the implementation owner.

### Evidence, tier, source and date

- **Operator**, proof-bar probe and editor prototype results, read 2026-10-13: input delivery was demonstrated, but final-build resume/copy behavior was not. Prototype scratch was deleted.
- **Better-than-training**, main tree and retained branch test inventory, inspected 2026-10-13: main contains core/sync tests. The retained branch adds QML component and clipboard helpers, but no reusable uinput live runner appears in its tracked files. Installed evdev availability is an input capability, not that runner.
- **Better-than-training**, chart skill Handoff and shapes audit, read 2026-10-13: machinery absent from the default branch must be supplied by a prerequisite with positive and negative proof, or the criterion narrowed with the operator.

### Pitfalls and removal

The door must map each final live criterion to an exact existing tool or prerequisite output before handoff. If that mapping demonstrates that existing installed tools alone already satisfy every criterion without new machinery, remove this prerequisite rather than manufacture infrastructure. Current records establish capability, not that complete mapping. Limit fixtures and cleanup to declared grants, never treat user cache/state as disposable, and keep the physical mouse/paste spot-check as the already selected post-merge operator step.

### Missing question

Does the door have an existing reusable live proof route not shown in the permitted records? If yes, name it and its passing/failing evidence. Otherwise approve the prerequisite without reopening the final-build proof bar.
