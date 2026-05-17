# P1.13 CLI `codogotchi sync`

Size: 2 points
Type: feat
Scope: cli

## Outcome

- `codogotchi sync` orchestrates a single sync cycle:
  - Reads `~/.codogotchi/config.json` for credentials, URL, health config.
  - Calls each of the four sources in parallel, each wrapped in its own try/catch. A failed source emits `null` for its signal-set and pushes an error to a collected `errors[]`.
  - Determines `since` per source from prior `last_signal_at_by_source` (read from local cache `profile.json`, defaulting to a "first sync" sentinel that triggers the GitHub rate-limit cap).
  - POSTs the payload `{ profile_id, handle, signals: {...}, config, now, errors }` to `${convex_http_url}/sync`.
  - Writes the response (updated profile + new loot events) to `~/.codogotchi/profile.json` and appends loot events to a local loot log (cache copy).
  - Appends a one-line summary to `~/.codogotchi/sync.log` (rotated at 10MB): timestamp, per-source pass/fail, new XP delta, new loot count.
  - Exit code 0 if at least one source succeeded OR the Convex POST itself succeeded (a "no signals, just heartbeat" sync is still success). Exit code 1 only if **all four sources failed AND the POST failed**.
- Tests cover: all sources succeed, one source fails (per-source isolation), all sources fail but POST succeeds (exit 0), all-fail scenario (exit 1), log rotation at threshold.

## Red

- Write failing tests with mocked source clients (per-source success/fail toggles) and mocked HTTP.
- Commit: `test(P1.13): codogotchi sync per-source isolation [red]`.

## Green

- Implement orchestration. Use `Promise.allSettled` to run sources concurrently while preserving per-source outcomes.
- Implement log rotation (simplest: rename to `sync.log.1` when size > 10MB, truncate original; keep only the most recent rotation).

## Refactor

- Extract per-source runner if duplication emerges.
- Only refactor what this ticket touches.

## Review Focus

- Per-source isolation: confirm one failing source does not poison another. Reviewer reads the `Promise.allSettled` handling.
- `since` derivation per source from `profile.json` cache is correct; first-sync triggers cap behavior in `sources/github.ts` (P1.10).
- Exit code logic exactly matches the locked spec: 0 if any source OR the POST succeeded, 1 only if all sources failed AND POST failed.
- Log rotation works (write 11MB worth, confirm rotation happened, old file is `sync.log.1`).
- `now` is sent server-side rather than computed there (so server cannot drift from CLI's notion of time during the run).
- No partial writes to `profile.json` (write to temp, rename atomically — avoids corrupting cache mid-write).

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
