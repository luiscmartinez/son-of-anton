# P11.03 subagent-review recorder mode and artifact-existence-at-HEAD idempotency

Size: 3 points
Type: feat
Scope: delivery

## Outcome

- `subagent-review <ticket> [clean|patched] <sha>` writes a recorder-mode entry to the structured artifact's `invocations[]` and exits without invoking a runner subprocess. The recorded invocation carries `runnerKind: 'operator-recorder'` (or equivalent unambiguous label), the supplied outcome, the supplied SHA as `reviewedHeadSha`, and `terminatedReason: 'completed'`.
- When `subagent-review <ticket>` (no operator outcome) runs against a HEAD for which the artifact already contains a valid invocation with matching `reviewedHeadSha`, the CLI exits as a no-op recorder and does not invoke a subprocess.
- A `--force` flag overrides the idempotency check and runs the runner regardless of existing invocations at the current HEAD. This covers the "re-review after follow-up patches that did not change HEAD-from-the-artifact's-perspective" case.
- The CLI's exit code and stdout/stderr clearly distinguish "no-op recorder hit" from "fresh runner invocation."
- `bun run ci` is green.

## Red

- Add a CLI integration test that invokes `subagent-review <ticket> clean <sha>` in a fixture worktree and asserts: no subprocess invocation happens (mock or spy on the runner dispatch), and the artifact at the expected path contains a single recorder-mode invocation with the supplied SHA and outcome.
- Add a second test: pre-seed the artifact with a `reviewedHeadSha` matching the worktree's HEAD, invoke `subagent-review <ticket>` (no outcome), and assert no-op (no new invocation appended; no subprocess invoked).
- Add a third test: same setup, invoke with `--force`, assert the runner *is* invoked and a new invocation is appended.
- Run the test suite and confirm all three fail.
- Commit with suffix `[red]`: `test(P11.03): recorder mode and HEAD idempotency [red]`

## Green

- In `tools/delivery/cli-runner.ts` (or whichever file owns the `subagent-review` case — verify at implementation time), add positional-arg handling for `[clean|patched] <sha>`.
- Implement the recorder-mode branch: when an outcome is supplied, append a recorder-mode invocation and exit without invoking the runner.
- Implement the idempotency check: before invoking the runner, read the artifact via the P11.01 adapter, resolve current HEAD via `git rev-parse HEAD`, and short-circuit if any invocation already has matching `reviewedHeadSha`.
- Add `--force` flag plumbing to skip the idempotency check.

## Refactor

- If positional-arg parsing for `subagent-review` lives in a shared helper used by other CLI cases, extract carefully — out-of-scope cleanup belongs in phase-13. Only touch what this ticket requires.

## Review Focus

- Recorder-mode runnerKind label — confirm it is distinct from real runner labels so downstream artifact consumers can filter operator-recorded invocations.
- HEAD detection edge case from product plan risk #3: primary-agent commits between subagent run and artifact write. Document the chosen behavior in code comment or Rationale.
- `--force` semantics: does it skip *only* the idempotency check, or also other safety checks added by P11.04? Keep it scoped to idempotency in this ticket.
- Test fixture for the worktree — keep it minimal (a temp dir with a single commit is enough).

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: [what test failed first]
Why this path: [why this implementation was the smallest acceptable]
Alternative considered: [one rejected alternative and why]
Deferred: [what was intentionally left out of this ticket]
Contract note: record any deviation from the ticket metadata contract here, including missing/incorrect `Type:` or non-compliant `Scope:` fields, and why it happened.
