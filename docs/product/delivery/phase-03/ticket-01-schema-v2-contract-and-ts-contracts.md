# P3.01 Schema v2 — contract doc + TS contracts package

Size: 2 points
Type: feat
Scope: contracts
Red: required

## Outcome

- `docs/contracts/animation-state-vocabulary.md` includes a `state.json` v2 example with `schema_version: 2` and at least one v2 state demonstrated (e.g., `requesting_input` or `errored`).
- The revision policy section of the contract doc records that Phase 03 is the formal v2 bump per the policy's "After P1.18 lands, further changes require a new ticket and a separate schema-version bump" clause.
- `packages/contracts/src/animation-state.ts` has `requesting_input` and `errored` appended to `ACTIVITY_STATES` (closed enum preserved; no string escape hatch).
- `packages/contracts/src/state-json.ts` exports `STATE_JSON_SCHEMA_VERSION = 2`.
- The zod schema for `state.json` parses a v2 payload (with one of the new states) successfully.
- All prior v1 payloads still parse — backward compatibility preserved by the forward-compat policy (`got ≤ expected`).
- A payload with `schema_version: 3` (one ahead of the new `EXPECTED_VERSION`) is rejected at the parser layer.

## Red

- Write a test that asserts `STATE_JSON_SCHEMA_VERSION === 2` after the change.
- Write a test that a v2 payload with `activity_state: "requesting_input"` parses successfully.
- Write a test that a v2 payload with `activity_state: "errored"` parses successfully.
- Write a test that a previously-valid v1 payload still parses.
- Write a test that a `schema_version: 3` payload is rejected.
- Run `bun run test` against the contracts package and confirm the new tests fail.
- Commit with suffix `[red]`: `test(P3.01): schema v2 enum + version + parser [red]`.
- Do not write any implementation until this commit exists on the branch.

## Green

- Bump `STATE_JSON_SCHEMA_VERSION` from `1` to `2` in `packages/contracts/src/state-json.ts`.
- Add `"requesting_input"` and `"errored"` to the `ACTIVITY_STATES` literal tuple in `packages/contracts/src/animation-state.ts`.
- Update the v1 example block in `docs/contracts/animation-state-vocabulary.md` to a v2 example (`schema_version: 2`, one of the new states as `activity_state`). The v1 example can be removed or kept as a "historical / still-valid v1" reference; pick the cleaner option in implementation.
- Update the revision policy section to record the v2 bump as planned by Phase 03 (one line; do not rewrite the policy).
- Smallest change that makes the failing tests pass — no opportunistic refactoring of the contracts package.

## Refactor

- Keep the contracts package change tight. The v2 additions are appended to existing tuples — do not reorder existing entries.
- Confirm the zod schema still surfaces useful error messages for the v3-rejection path; if the error message degrades, restore it.
- If this ticket moves tracked files to a new location: bump `SOA_TARGET_VERSION` in `scripts/soa-sync.sh` and add a `run_migration_N()` function that moves the files idempotently using `git mv`. (Not expected for this ticket — no file moves.)

## Review Focus

- Closed-enum discipline is preserved (no `string` escape hatch in the zod schema or TS type).
- The forward-compat policy is honored exactly as documented in the contract (`got ≤ expected` accepted, `got > expected` refused).
- The state.json v2 example in the doc matches the actual zod-validated shape — no drift between contract and code.
- The revision-policy update is a one-line record, not a policy rewrite.
- Tests cover the four meaningful cases: v2-with-new-state OK, v1 OK, v3 refused, enum exhaustiveness.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: [what test failed first]
Why this path: [why this implementation was the smallest acceptable]
Alternative considered: [one rejected alternative and why]
Deferred: [what was intentionally left out of this ticket]
Contract note: record any deviation from the ticket metadata contract here, including missing/incorrect `Type:` or non-compliant `Scope:` fields, and why it happened.
