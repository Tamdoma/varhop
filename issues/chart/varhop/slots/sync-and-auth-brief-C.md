# Fork notes brief (slot C): sync-and-auth

Task: write your blind notes for the fork at /home/ivan/Work/omarchy-customizations/varhop/issues/chart/varhop/forks/sync-and-auth.md (Question and Carries). Intake: ../INTAKE.md. Decided locks (do not re-open): ../forks/form-factor.md and ../forks/repo-format.md, Taken sections. Your earlier map: slots/map-C.md; merged map and rebuttals are in slots/ (you may read them). Do NOT read other slots' sync-and-auth notes.

Context: the operator just upgraded to omarchy-dev r6912 / quickshell 0.3.2-4 / Qt 6.12; inspect /usr/share/omarchy as it is now.

Format: the note definition in /home/ivan/.claude/skills/chart-issues/assets/questions.md section "Blind peer exchange": per question the pick with reason and cost; each rejected option with reason; evidence with tier, source and date; pitfalls with what removes each; questions the fork does not ask.

Research before answering, highest tier first. Inspect how Omarchy shell plugins run external commands and store state (Quickshell Process, FileView, ~/.cache, ~/.config/omarchy/plugins/*/ settings), how first-party features reuse gh or git, gh CLI docs (gh auth token, gh repo list, gh api, gh repo clone), GitHub REST rate limits and tarball/contents endpoints, and how comparable tools (e.g. Raycast/Espanso package sync, VS Code settings sync, chezmoi) handle a remote source plus offline cache. Read-only probes against the operator's real gh login are fine (gh repo list --limit 5, gh api rate_limit); make no writes. Cite URLs with read date and file:line.

Return path (write exactly here): /home/ivan/Work/omarchy-customizations/varhop/issues/chart/varhop/slots/sync-and-auth-C.md
