# P1.15 CLI `codogotchi loot`

Size: 2 points
Type: feat
Scope: cli

## Outcome

- `codogotchi loot` prints the full loot history from `~/.codogotchi/profile.json` (or a separate `loot.log` cache, whichever stores it — choice locked in P1.13 Rationale).
- Output: tier + name + source + timestamp + (optionally) the `score_explanation` for PR-quality drops.
- `--limit N` flag shows only the last N events (default: all).
- `--tier <tier>` flag filters to a single tier.
- Does NOT render sprite art. Text/icons only — visible loot rendering is explicitly deferred.
- Tests cover: empty loot history, populated list, `--limit` truncation, `--tier` filter, missing cache (helpful message).

## Red

- Write failing tests for output shape, flag handling, empty list.
- Commit: `test(P1.15): codogotchi loot output and flags [red]`.

## Green

- Implement reader + formatter. Reuse the formatter helper from P1.14 if extracted.

## Refactor

- Consolidate display formatter with `status` if overlap is real.
- Only refactor what this ticket touches.

## Review Focus

- No sprite rendering attempted (explicit deferral).
- Empty-state message is helpful, not a blank screen.
- `score_explanation` displayed when available — this is the human-readable trace the user uses to understand why a PR scored as it did.
- `--limit` and `--tier` work together (filter then limit, in that order).

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
