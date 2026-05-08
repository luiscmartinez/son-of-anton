# P5.04 Phase Exit and Retrospective Scaffolding

Size: 1 point
Type: docs
Scope: phase-exit

## Outcome

- `docs/product/delivery/phase-05/implementation-plan.md` delivery status updated to reflect shipped state
- `notes/public/phase-05-subagent-review-clarity-and-pr-scope-propagation-retrospective.md` scaffolded per `soa-write-retrospective` skill conventions
- All three prior tickets (P5.01, P5.02, P5.03) have merged PRs; exit condition from implementation plan is verifiable

## Red

- Docs-only; no failing test
- Manual check: confirm P5.01, P5.02, P5.03 PRs are all merged before this ticket starts
- Commit with suffix `[red]`: `docs(P5.04): phase exit checklist [red]`

## Green

- Read `.agents/skills/write-retrospective/SKILL.md` (or `.claude/skills/soa-write-retrospective/SKILL.md`) before writing the retrospective to get placement conventions and section structure
- Update `docs/product/delivery/phase-05/implementation-plan.md`: change delivery status line to "Delivered — all tickets merged"
- Scaffold `notes/public/phase-05-subagent-review-clarity-and-pr-scope-propagation-retrospective.md` per the write-retrospective skill
- Commit with suffix `[green]`: `docs(P5.04): phase exit and retrospective [green]`

## Refactor

- None

## Review Focus

- Confirm retrospective artifact path matches the pattern in `notes/public/` (kebab-case, no leading phase number prefix beyond the plan slug)
- Confirm implementation plan delivery status is updated before this PR is opened

## Rationale

> Append here when behavior or trade-offs change during implementation.

Red first: retrospective artifact does not exist; implementation plan still shows draft status
Why this path: phase-exit ticket is a lightweight ceremony to close the loop and trigger the retrospective
Deferred: hardening decisions — those belong in the retrospective and the planning session that follows it
