# P7.04 Run-policy observability in status and workflow output

Size: 2 points
Type: feat
Scope: delivery-output

## Outcome

- Status and workflow output show the active persisted `runPolicy` clearly enough for an operator to understand the governing rules.
- Resume mismatch refusal output renders persisted run policy, current repo policy, and mixed-policy guidance clearly.
- Operator-facing output stays aligned with the shipped Phase 07 flag names and baseline semantics.

## Red

- Write failing format/output tests for status rendering of persisted `runPolicy`.
- Write failing tests for resume refusal output showing both policies and exact recovery guidance.
- Run the targeted test suite and confirm the new tests fail.
- Commit with suffix `[red]`: `test(P7.04): cover run-policy workflow output [red]`
- Do not write any implementation until this commit exists on the branch.

## Green

- Update status and resume-facing formatters to render persisted run policy explicitly.
- Add or update refusal output so operators can see both policy sources and the required recovery command shapes.

## Refactor

- Consolidate run-policy rendering into shared formatter helpers if the same output appears in multiple workflow surfaces.
- Keep behavioral logic out of formatters except for display-only branching.

## Review Focus

- Whether output uses the persisted active run policy rather than accidentally echoing only current repo defaults.
- Whether the recovery guidance is precise enough to run without interpretation.
- Whether operator-facing phrasing stays concise and consistent across status, refusal, and resume surfaces.
- Deferred: long-form docs and retrospective writing stay out of this ticket.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: [what test failed first]
Why this path: [why this implementation was the smallest acceptable]
Alternative considered: [one rejected alternative and why]
Deferred: [what was intentionally left out of this ticket]
Contract note: record any deviation from the ticket metadata contract here, including missing/incorrect `Type:` or non-compliant `Scope:` fields, and why it happened.
