# P1.05 Engine: Loot (`loot.ts`) — drops + PR quality scoring

Size: 2 points
Type: feat
Scope: engine

## Outcome

- `packages/engine/src/loot.ts` exports:
  - `rollLootDrop(rng: RngFn, context: LootContext): LootEvent | null` — generic loot roll on any signal-tick.
  - `rollPRLootDropWithQuality(rng: RngFn, pr: ScoredPR): LootEvent | null` — PR-merge-specific roll using quality score.
  - `scorePR(pr: PRMerge): ScoredPR` — quality scoring (review comment count, revert detection, size) producing a numeric score + an explanation string for the debug log.
- `rng` is always a parameter (seedable function) — never `Math.random()` directly. Lets tests be deterministic.
- Loot tier table (Common / Uncommon / Rare / Epic / Legendary) and probabilities live as named constants at the top of the file.
- Module is pure isomorphic. Imports only `packages/contracts/`.
- `bun test packages/engine/src/loot.test.ts` covers: deterministic drops under a seeded RNG, no-drop when probability roll fails, PR scoring across cases (clean merge / many review comments / reverted / large diff), tier distribution against a seeded sweep.

## Red

- Write failing tests with seeded RNG asserting specific drop outcomes, `scorePR` cases including a revert and a heavy-review case.
- Run `bun test`; confirm failure.
- Commit: `test(P1.05): loot rolls and scorePR quality scoring [red]`.

## Green

- Implement `rollLootDrop`, `rollPRLootDropWithQuality`, `scorePR`. Smallest implementation that passes fixtures.
- `scorePR` returns both a score and an explanation string; explanation is consumed later by P1.20's debug log.

## Refactor

- Extract tier-table lookup if it duplicates.
- Only refactor what this ticket touches.

## Review Focus

- RNG injection: no `Math.random()` anywhere in `loot.ts`. Reviewer greps to confirm.
- `scorePR` explanation string is human-readable and includes the inputs that drove the score (e.g. `"5 review comments, 1 revert detected, +120/-30 LOC"`).
- Probability constants are named exports, reviewable at the top of the file.
- Tier distribution under seeded sweep matches scaffold-v2 if values were ported.
- Revert detection criteria documented in code comment (only here — this is a non-obvious heuristic worth a brief WHY note).

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
