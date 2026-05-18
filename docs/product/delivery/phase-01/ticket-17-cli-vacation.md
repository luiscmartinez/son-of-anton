# P1.17 CLI `codogotchi vacation`

Size: 2 points
Type: feat
Scope: cli

## Outcome

- `codogotchi vacation on [--until YYYY-MM-DD]` sets `health.vacation_until` in config. Default `--until` is 30 days from today if omitted.
- `codogotchi vacation off` clears `health.vacation_until` (sets to `null`).
- `codogotchi vacation status` prints current vacation state: "off", or "on until YYYY-MM-DD (N days remaining)".
- Sugar over `codogotchi config set health.vacation_until <iso>` — internally calls the same write path as P1.16.
- Tests cover: on without flag (default 30d), on with explicit date, off, status (both states), invalid date format refusal.

## Red

- Write failing tests for each branch.
- Commit: `test(P1.17): codogotchi vacation on/off/status [red]`.

## Green

- Implement subcommands as a thin wrapper over the config writer. Validate date input.

## Refactor

- Confirm the wrapper does not duplicate validation that lives in the config schema.
- Only refactor what this ticket touches.

## Review Focus

- "on" without `--until` defaults to 30 days, not "forever" — this mitigates the "forgot to turn it off" failure mode that motivated the date-based design.
- "status" output is human-readable and includes days remaining.
- Invalid date format (`2026-13-45`) refused with a clear message.
- No new persistence layer — writes go through the same code path P1.16 uses.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
