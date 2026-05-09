# P7.01 Run-policy state model and migration

Size: 3 points
Type: feat
Scope: delivery-state

## Outcome

- `DeliveryState` persists a top-level `runPolicy` object containing the bounded Phase 07 policy surface.
- `runPolicy.reviewSubagent` uses an explicit tagged shape that distinguishes same-type fallback from concrete override.
- Existing persisted delivery state files without `runPolicy` still load and normalize safely.

## Red

- Write failing tests for state normalization and persistence when `runPolicy` is absent in older state files.
- Write failing tests proving the explicit `reviewSubagent` tagged shape survives save/load without collapsing to omission semantics.
- Run the targeted test suite and confirm the new tests fail.
- Commit with suffix `[red]`: `test(P7.01): cover run-policy state migration [red]`
- Do not write any implementation until this commit exists on the branch.

## Green

- Add the top-level `runPolicy` type and persistence wiring to delivery state.
- Normalize older state files by deriving `runPolicy` from current resolved orchestrator policy when the persisted state predates Phase 07.

## Refactor

- Extract shared helpers for run-policy normalization and serialization if state-loading code becomes branch-heavy.
- Only refactor the delivery-state/type loading paths touched by this ticket.

## Review Focus

- Whether migration semantics for older state files are deterministic and safe.
- Whether the tagged `reviewSubagent` model is explicit enough to avoid same-type/override ambiguity.
- Whether any existing state repair or sync paths accidentally drop or rewrite `runPolicy`.
- Deferred: command-line override parsing and resume divergence behavior stay out of this ticket.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: [what test failed first]
Why this path: [why this implementation was the smallest acceptable]
Alternative considered: [one rejected alternative and why]
Deferred: [what was intentionally left out of this ticket]
Contract note: record any deviation from the ticket metadata contract here, including missing/incorrect `Type:` or non-compliant `Scope:` fields, and why it happened.
