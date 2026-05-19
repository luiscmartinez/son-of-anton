# P11.01 Structured SubagentRunnerArtifact schema with forward-compat adapter

Size: 3 points
Type: feat
Scope: delivery

## Outcome

- `tools/delivery/subagent-runner.ts` exports a `SubagentRunnerArtifact` type with fields `ticket: string` and `invocations: SubagentRunnerInvocation[]`, where each invocation carries `runnerKind`, `reviewedHeadSha`, `outcome`, `completedAt`, `terminatedReason`, `findings`, `probedSurfaces`, and `patches`.
- The legacy 4-field shape (`runnerKind`, `reviewedHeadSha`, `outcome`, `completedAt`) is no longer a valid `SubagentRunnerArtifact` at the type level — it is only reachable through a forward-compat adapter.
- A `readSubagentRunnerArtifact(path)` (or equivalent) function returns the structured shape for both legacy and new on-disk files. Legacy files materialize as a single-entry `invocations[]` with `terminatedReason: 'completed'` and empty `findings`/`probedSurfaces`/`patches`.
- Real codogotchi phase-01 4-field artifacts copied into `tests/fixtures/legacy-subagent-runner/` round-trip through the adapter without error.
- `bun run ci` is green.

## Red

- Add a unit test that constructs a legacy 4-field artifact JSON (matching the shape currently emitted by `tools/delivery/subagent-runner.ts` at HEAD), writes it to a temp path, and asserts that `readSubagentRunnerArtifact()` returns a `SubagentRunnerArtifact` with `invocations.length === 1` and the legacy values lifted into the first invocation.
- Add a second test that round-trips a structured multi-invocation artifact: write, read, assert deep-equal.
- Run the test suite and confirm both tests fail.
- Commit with suffix `[red]`: `test(P11.01): structured artifact schema and adapter [red]`

## Green

- Introduce the `SubagentRunnerInvocation` and `SubagentRunnerArtifact` types in `tools/delivery/subagent-runner.ts`.
- Implement the read adapter: detect legacy shape (top-level `runnerKind` and absence of `invocations`) and lift fields into a single-entry `invocations[]`. Default `terminatedReason` to `'completed'` and `findings`/`probedSurfaces`/`patches` to `[]`.
- Implement the write path so new artifacts are serialized in the structured shape with `invocations[]` append-only across writes for the same ticket.
- Update every call site that constructs or consumes the old 4-field shape to use the structured type. Append-only semantics for `invocations[]` are owned by the writer in this ticket; recorder-mode and idempotency keying live in P11.03.

## Refactor

- If the old 4-field type is exported from a barrel or referenced in `son-of-anton-ethos` skill text by exact field shape, remove the export and let P11.02 update prose. Do not rename `subagent-runner.ts` in this ticket.
- Only refactor the files this ticket touches.

## Review Focus

- Field ordering and JSON key names in the new structured schema — they will be persisted to disk for months and renaming later is expensive. Confirm `terminatedReason` values match the product plan: `completed | rate_limit | sandbox_denied | runner_unavailable`.
- Adapter behavior on malformed legacy files (missing `outcome`, missing `reviewedHeadSha`). The product plan does not specify; default to surfacing a clear parse error rather than silently filling defaults.
- Whether `invocations[]` append-on-write is enforced by the writer or by a separate helper. The simplest implementation has the writer read-then-append-then-write.
- Test fixture provenance: copies of real codogotchi phase-01 artifacts — confirm no consumer-private content leaked into the fixture (paths, ticket IDs OK; in-repo secrets would not be).

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: [what test failed first]
Why this path: [why this implementation was the smallest acceptable]
Alternative considered: [one rejected alternative and why]
Deferred: [what was intentionally left out of this ticket]
Contract note: record any deviation from the ticket metadata contract here, including missing/incorrect `Type:` or non-compliant `Scope:` fields, and why it happened.
