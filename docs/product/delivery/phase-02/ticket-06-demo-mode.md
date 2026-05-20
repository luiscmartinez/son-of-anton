# P2.06 Demo mode — sandboxed polling target + fixture cycle driver

Size: 2 points
Type: feat
Scope: menubar
Red: required

## Outcome

- The menubar app reads an environment variable `CODOGOTCHI_DEMO` (or, equivalently, a `--demo` launch argument) on startup.
- When demo mode is active:
  - The polling target is re-pointed to a sandboxed path (e.g., `$TMPDIR/codogotchi-demo/state.json`) instead of `~/.codogotchi/state.json`.
  - A `DemoCycleDriver` runs on a 3-second timer, copying fixture files from `apps/menubar/Fixtures/state-json/` (in a hardcoded order: `idle.json` → `implementing.json` → `running-tests.json` → `celebrating.json` → loop) into the sandboxed path using an atomic write (write-to-tmp + rename).
  - The renderer (P2.05) receives `update(state:visualMode:)` calls reflecting the cycle, exactly as if a real hook were producing those transitions.
- When demo mode is NOT active, the app's behavior is unchanged (P2.07 implements live polling against `~/.codogotchi/state.json`; this ticket only ensures the polling-target seam exists).
- The real `~/.codogotchi/state.json` is NEVER touched in demo mode — no read, no write, no atomic-replace.
- `apps/menubar/README.md` documents how to run demo mode (Xcode scheme env var, terminal launch from `.app`, both).
- Tests at `apps/menubar/Tests/MenubarTests/DemoModeTests.swift`:
  - `DemoCycleDriver` started with a stub renderer observes the four floor states in cycle order over multiple ticks.
  - When `CODOGOTCHI_DEMO=1` is set in the test's process environment, app startup wires the demo driver and points polling to the sandboxed path (verifiable by inspecting the configured path).
- `notes/private/phase-02-swift-notes/P2.06-demo-mode.md` lands in this PR explaining: `ProcessInfo.processInfo.environment` for env var reading, atomic-replace file writes in Swift, and dependency injection for the polling-target seam.

## Red

- Write `DemoModeTests` first. Run `bun run mac:test` and confirm failures.
- Commit `[red]`: `test(P2.06): demo mode cycles fixtures through sandboxed path [red]`.

## Green

- Add a `pollingTarget: URL` configuration parameter (computed at app launch) that defaults to `~/.codogotchi/state.json` but is overridden to the sandboxed path when `CODOGOTCHI_DEMO=1`.
- Implement `DemoCycleDriver` as a timer-driven loop that copies fixtures to the sandboxed path. Use atomic write to mirror the real hook's write pattern.
- Wire the demo driver into app startup conditional on the env var.
- Ensure tests pass without requiring a full NSApplication run loop (use the driver in isolation against a stub renderer).

## Refactor

- Confirm the sandboxed path's parent directory is created on first use.
- Confirm the demo driver stops cleanly on app shutdown (no orphaned timers, no dangling tmp files beyond what's expected — the sandboxed path can persist between runs; that's fine).
- Confirm the polling-target seam is the same one P2.07 will use — they should not implement two parallel paths.

## Review Focus

- Sandboxed-path location: `$TMPDIR/codogotchi-demo/state.json` vs. a fixed `~/.codogotchi/demo-state.json`. Either acceptable; `$TMPDIR` is more honestly "sandbox" because macOS cleans `$TMPDIR` periodically; document the choice.
- Atomic write pattern matches Phase 01 hook's pattern — write to tmp, rename — so demo exercises the same race-free read semantics live polling depends on.
- Test seam: does `DemoCycleDriver` accept an injectable clock or use a real timer? Real timer with short intervals is OK for a 2-point ticket; injectable is cleaner. Pick one explicitly.
- Demo mode UX: pressing Cmd+Q (Quit menu, landing in P2.09) terminates demo cleanly.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: tests assert the four-state cycle order before any driver code exists.
Why this path: re-pointed polling target (not direct injection into the renderer) means demo mode exercises the *same* read path live mode will use in P2.07. Demo and live diverge only in where the bytes come from — parser, error handling, render pipeline are all shared.
Alternative considered: write demo fixtures to `~/.codogotchi/state.json` with a backup/restore step. Rejected because it races with a real hook if the owner runs demo while the hook is also writing.
Deferred: a runtime toggle (menu item or hotkey) for entering/exiting demo mode without restart. Out of scope; env var at launch is enough.
Contract note: none.
