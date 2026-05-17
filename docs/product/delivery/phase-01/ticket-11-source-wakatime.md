# P1.11 Source: Wakatime

Size: 2 points
Type: feat
Scope: engine

## Outcome

- `packages/engine/src/sources/wakatime.ts` exports `readWakatimeSignals(opts: { apiKey: string; since: Date }): Promise<WakatimeSignalSet>` returning total coding hours per day in the window since `since`.
- Uses Wakatime's `/users/current/summaries` (or equivalent) endpoint, batched within Wakatime's date-range limits.
- Returns partial result with `error: ...` field on transient HTTP failures rather than throwing (consistent with the per-source isolation failure model).
- Tests use a mocked HTTP client. Fixtures cover: empty window, normal day, multi-day window, 502 partial failure.

## Red

- Write failing tests with mocked Wakatime client.
- Assert: hours-per-day aggregation, since-cutoff honored, 502 returns partial with error field set.
- Commit: `test(P1.11): Wakatime source [red]`.

## Green

- Implement using `fetch` against Wakatime API.
- Batch date ranges if `since` is far in the past (Wakatime caps per-request range).
- Error handling: catch HTTP errors, attach `error` field, return what was successfully fetched.

## Refactor

- Extract date-range batching helper if it adds value beyond a few lines inline.
- Only refactor what this ticket touches.

## Review Focus

- API key passed as parameter, not via env from inside this module.
- Date-range batching is correct: requesting 180 days does not exceed Wakatime's per-call limit.
- Hours are summed correctly (Wakatime returns `total_seconds` — confirm conversion).
- Partial-result error shape matches the per-source isolation convention (P1.13 consumes it).
- No real Wakatime calls in tests.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
