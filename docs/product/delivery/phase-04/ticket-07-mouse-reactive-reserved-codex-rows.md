# P4.07 Mouse-reactive reserved Codex rows

Size: 2 points
Type: feat
Scope: floating-animation
Red: required

## Outcome

- The floating scene can use Codex `running-right` frames for rightward drag/movement feedback.
- The floating scene can use Codex `running-left` frames for leftward drag/movement feedback.
- The floating scene can use Codex `jumping` frames for hover, resize, or attention feedback where that row exists and looks appropriate.
- Missing reserved rows gracefully fall back to the current activity-state animation.
- Reserved-row feedback is scoped to the floating surface; the menu bar renderer does not consume these rows.
- Ordinary live/demo activity state resumes after the mouse-reactive interaction ends.

## Red

- Write tests that the Codex loader can expose reserved interaction rows independently of `ActivityState`.
- Write tests that rightward and leftward drag select the expected interaction animation.
- Write tests that missing reserved-row frames fall back to current activity frames.
- Write tests that ending interaction restores the live/demo activity state.
- Run `bun run mac:test` and confirm the new tests fail.
- Commit with suffix `[red]`: `test(P4.07): reserved codex rows drive floating interactions [red]`.
- Do not write implementation until this commit exists on the branch.

## Green

- Add a narrow representation for floating-only interaction animations; do not widen the `ActivityState` contract.
- Expose reserved Codex rows from the loader without making them normal activity states.
- Wire drag direction and hover/resize affordance events into the floating SpriteKit scene.
- Restore ordinary state-driven animation when interaction ends.

## Refactor

- Keep `running-right`, `running-left`, and `jumping` out of `state.json` and `ActivityState`.
- Do not add physics, autonomous movement, or smoothing beyond direct interaction feedback.
- Avoid changing the menu bar renderer's row map.
- If this ticket moves tracked files to a new location: bump `SOA_TARGET_VERSION` in `scripts/soa-sync.sh` and add a `run_migration_N()` function that moves the files idempotently using `git mv`.

## Review Focus

- Reserved rows remain floating-only behavior.
- Fallback path is graceful for pets that do not provide useful reserved rows.
- Live state resumes after temporary mouse interaction.
- No schema bump or contract change is introduced.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first:
Why this path:
Alternative considered:
Deferred:
Contract note:
