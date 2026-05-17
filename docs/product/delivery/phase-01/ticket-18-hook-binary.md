# P1.18 Hook binary — writes `~/.codogotchi/state.json` per lifecycle event

Size: 2 points
Type: feat
Scope: cli

## Outcome

- `packages/cli/bin/codogotchi-hook.ts` is registered as `bin.codogotchi-hook` in `packages/cli/package.json`.
- Invoked by Claude Code and Codex hooks per their conventions (stdin receives the event JSON; some lifecycles pass env vars).
- Parses the incoming event, classifies it into an activity state per the mapping rules from `packages/contracts/animation-state.ts`:
  - `Write` / `Edit` tool → `implementing`
  - `Bash` matching test patterns (`bun test`, `vitest`, `pytest`, etc.) → `running-tests`
  - Many sequential `Read`s → `reviewing` (heuristic; documented as best-effort)
  - `Bash` with `git push` → `pushing`
  - PR merge event (from another hook source if available) → `celebrating`
  - Default → `idle`
- Layers HP overlay from `profile.json` (if present) using `hpBucket()` from engine.
- Writes the resulting state atomically to `~/.codogotchi/state.json` (write-to-temp + rename).
- Exits in <50ms on hot path (no network, no large file reads).
- Allowed to revise the contract from P1.02 once: any state names changed, fields added, or mapping rules tightened must be reflected back in `docs/contracts/animation-state-vocabulary.md` and `packages/contracts/src/animation-state.ts`. Revisions documented in this ticket's Rationale.
- Tests feed synthetic Claude Code + Codex event JSON via stdin and assert resulting `state.json` content; cover each mapping rule + HP overlay layering + missing profile (no overlay) + default-idle case.

## Red

- Write failing tests with fixture event JSON per mapping rule.
- Commit: `test(P1.18): hook binary state classification [red]`.

## Green

- Implement event parsing, classification, overlay, atomic write.
- Speed budget: keep the hook hot path under 50ms — no synchronous network, no large file reads.

## Refactor

- Extract classification table if mapping rules grow.
- Only refactor what this ticket touches.

## Review Focus

- Hot-path speed: reviewer runs the hook against a real Claude Code event and confirms wall time <50ms.
- Atomic write: partial writes never corrupt `state.json`.
- Heuristic states (`reviewing`) are tagged as best-effort in the contract doc and the implementation does not over-claim certainty.
- If the contract was revised, Rationale section lists the revisions and the contract doc + types were updated in the same PR.
- No use of `~/.codogotchi/state.json` for anything but writes — this is producer-only.
- Hook stdin handling is robust against truncated/malformed JSON (silent skip rather than crash — a crashed hook can spam Claude Code logs).

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
> If the IPC contract was revised this ticket, document each revision and the reason here. Update `docs/contracts/animation-state-vocabulary.md` to match.
