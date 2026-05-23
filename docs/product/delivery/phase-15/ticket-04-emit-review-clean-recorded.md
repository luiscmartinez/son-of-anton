# P15.04 Emit review_clean_recorded across record/poll/triage paths

Size: 2 points
Type: feat
Scope: delivery
Red: required

## Outcome

- Running `deliver record-review` with `outcome === 'clean'` (or the resolved triage outcome is `clean`) appends a `review_clean_recorded` line to `.soa/events.ndjson`.
- Running `deliver poll-review` where the resolved review outcome is `clean` appends the same line.
- Running `deliver triage-ticket` (the `reconcile-late-review` path) where the reconciled outcome is `clean` appends the same line.
- All three paths use `plan_key` from `state.planKey` and `ticket_id` from the reviewed ticket.
- Non-clean outcomes (`needs_patch`, `operator_input_needed`, `skipped`, `deferred`) do NOT emit `review_clean_recorded`.
- Setting `codogotchi.enabled: false` suppresses the event across all three paths.

## Red

- Add a Red test in `tools/delivery/test/p15-04.test.ts` that:
  - Sets up a fake delivery state with a ticket ready for review.
  - Invokes `record-review` with outcome `clean` and asserts a `review_clean_recorded` line is appended.
  - Resets the events file (or starts a new tmp dir) and invokes `record-review` with outcome `needs_patch`. Asserts no `review_clean_recorded` line.
  - Invokes the `poll-review` path with a state where `eventsForPollReviewCommand` resolves to a `clean` outcome. Asserts the line is appended.
  - Invokes the `triage-ticket` (`reconcile-late-review`) path where the reconciled outcome is `clean`. Asserts the line is appended.
  - With `codogotchi.enabled: false`, repeats the clean cases and asserts no events file is created.
- Commit message: `test(P15.04): emit review_clean_recorded on record/poll/triage paths [red]`.

## Green

- For each of the three call sites in `cli-runner.ts` (`record-review`, `poll-review`, `triage-ticket`), after the event list is computed (via the existing `eventsForRecordReviewCommand` / `eventsForPollReviewCommand` / `eventsForReconcileLateReviewCommand` calls), inspect the resolved outcome on any `review_recorded` event in the list. When `outcome === 'clean'`, call `appendSoaEvent(process.cwd(), buildSoaEventLine('review_clean_recorded', { plan_key, ticket_id }))`.
- Source `plan_key` from `state.planKey` and `ticket_id` from the ticket in the resolved event.
- Consider extracting a tiny helper `maybeEmitReviewCleanRecorded(events, state, config)` that scans the event list for a clean `review_recorded` and emits — used by all three call sites. The duplication is real (three near-identical inspections), so this extraction earns its keep.

## Refactor

- Extract `maybeEmitReviewCleanRecorded(events, state, config, projectRoot)` to `tools/delivery/soa-event-feed.ts` if extraction reads cleaner than inline scans in three places. Otherwise leave inline.

## Review Focus

- Only `outcome === 'clean'` emits. Verify the test matrix covers at least one non-clean outcome to prove the negative.
- All three call sites (record / poll / triage) are wired — no path is forgotten.
- The triage-ticket path correctly sources `state.planKey` and the ticket id from the reconciled ticket (`eventsForReconcileLateReviewCommand`'s output), not from CLI args.
- A single review path produces at most one `review_clean_recorded` line per invocation.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: [what test failed first]
Why this path: [why this implementation was the smallest acceptable]
Alternative considered: [one rejected alternative and why]
Deferred: [what was intentionally left out of this ticket]
Contract note: record any deviation from the ticket metadata contract here, including missing/incorrect `Type:` or non-compliant `Scope:` fields, and why it happened.
