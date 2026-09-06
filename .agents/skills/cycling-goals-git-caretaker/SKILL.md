---
name: cycling-goals-git-caretaker
description: "Safely inspect, verify, and commit approved Git housekeeping after a completed development task; do not use for product implementation or unrequested pushes."
---

# Cycling Goals Git Caretaker

Handle routine Git housekeeping for this repository after another Codex task has completed substantive development work and provided a handoff.

## Workflow

1. Inspect the current branch, upstream and remote status, working tree, index, untracked files, recent commits, and relevant diffs. Treat existing modifications as user-owned until proven otherwise.
2. Read the development task's handoff (and task history when available). Reconcile its claimed files, behavior, and verification with the actual diff. If the handoff is missing, contradictory, or the diff includes unexplained work, stop before committing and report the discrepancy.
3. Confirm tests and builds reported by the handoff. Run reasonable targeted verification when reports are absent, stale, or insufficient; never infer success. Do not rewrite implementation to make the housekeeping task pass.
4. Separate approved changes from unrelated or pre-existing work. Stage only the approved paths/hunks. If clean separation is not safe, stop and ask for direction.
5. Create one concise, accurate commit for the approved work only. Never amend an existing commit.
6. Push only when the user's current request explicitly authorizes pushing. Otherwise leave the commit local and say so.
7. Perform a straightforward merge only when explicitly requested, after checking the target and source state. Do not force-push, reset destructively, delete branches, discard work, or use other history-rewriting operations.
8. Reinspect final status and report concisely: commit hash, branch, verification performed and result, whether/how it was pushed, and final repository status.

## Safety boundaries

- Do not make product decisions, redesign features, or change Garmin application source as part of housekeeping.
- Do not commit changes that do not match the handoff or whose ownership is unclear.
- Preserve unrelated and pre-existing staged, unstaged, and untracked work.
- Claim tests/builds passed only when you ran them successfully or the verified handoff clearly records the successful result.
- A request to inspect or commit does not authorize pushing. Ask before any ambiguous remote or merge operation.
- Keep user-facing responses concise and factual; clearly distinguish observed state, handoff claims, and actions performed.
