# Phase 03 — Orchestrator Ergonomics (Rough Sketch)

> Input for `/soa plan` grill-me pass. Not a final plan.
> Derived from: improvement-waves-execution-plan.md + son-of-anton-orchestrator-findings.md
> Depends on: Phase 02 landed (command names in error messages use new names)

## Goal

Make the orchestrator robust against model variance and operator mistakes. These are
safety rails — the system runs without them, it just fails confusingly. None of these
items are architectural; they're UX and guard changes on top of a stable Phase 02 core.

## What changes

### 1. Worktree guard

When any delivery command runs from a directory that is not the active ticket's worktree,
refuse immediately with the exact recovery command:

```
Error: You are in <current-dir>, not the active worktree for <ticket-id>.
Run: cd <worktree-path> && bun run deliver --plan <plan> <command>
```

### 2. `status` prints one next command

`status` always outputs:

```
Active ticket: <id> — <title>
Status: <state>
Next command: bun run deliver --plan <path> <next-command>
```

One command. Not a menu. The model always knows what to run next without guessing.

### 3. Doc-only early failure

When a doc-only ticket has no commits between branch and base, fail at `post-verify`
(not at `open-pr`) with:

```
Error: No commits on branch for doc-only ticket <id>.
Add or update documentation files before continuing.
```

### 4. Wrong-state error UX

When a state-specific command is run from the wrong state, the error includes current
state and the valid next command:

```
Error: `open-pr` requires status `subagent_review_complete`. Current status: `verified`.
Next command: bun run deliver --plan <path> subagent-code-review
```

### 5. Cook mode "phase complete" signal

When `advance` marks the final ticket done and there are no more pending tickets:

```
Phase complete. All tickets delivered.
To merge: bun run closeout-stack --plan <plan>
```

## Open questions for grill-me

- Worktree guard: which commands should be exempt (e.g. `status`, `sync`, `repair-state` are safe from any directory)?
- For the `status` next-command: what does it print when the phase is complete (no active ticket)?
- Ticket decomposition: one ticket or one per item? Items 1–5 are all small and independent.
- Any of these interact with Phase 02 state field renames that need to be accounted for in the ticket ordering?
