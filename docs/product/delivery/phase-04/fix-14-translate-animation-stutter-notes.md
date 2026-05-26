# Fix 14 — Translate + animation-shift stutter (investigation)

## Symptom

Floating pet **frame translation is smooth** while the Codex interaction row is stable (e.g. sustained `runningLeft` or `runningRight`).

A **distinct stutter** appears when translation coincides with an **interaction row change**:

- `runningLeft` ↔ `runningRight`
- `jumping` → `runningLeft` / `runningRight`
- activity row → interaction row (first horizontal drag tick after hover)

## Likely causes (from code + external references)

### 1. Main-thread work on the same turn as `setFrameOrigin`

On each `mouseDragged` during translate:

1. `window.setFrameOrigin` (AppKit)
2. `emitInteraction` when step delta changes direction → `FloatingPetScene.setInteraction`
3. `paintCurrentFrame` → `SKTexture(cgImage:)` + sprite size update

When interaction is unchanged, step 2 is skipped (`emitInteraction` early-outs) → smooth.

When interaction changes, step 2–3 run **in the same run-loop turn** as the window move → visible hitch.

**References:** SpriteKit stutter often correlates with frame drops when extra work runs on the main thread during movement ([Stack Overflow — stuttering during movement](https://stackoverflow.com/questions/39819602/sprite-kit-stuttering-during-movement-with-constant-velocity)).

### 2. `restartTimer()` on row / frame-count changes

`setInteraction` calls `restartTimer()` when switching from activity → interaction, on jumping→running transitions, and when interaction frame counts differ. Invalidating and re-adding a `Timer` on `.common` during drag may phase-reset animation and add RunLoop work.

### 3. `SKView.inLiveResize` during window moves

Apple reports SpriteKit can **defer redraws** while AppKit considers a view “live resizing”. Moving an `NSPanel` with `setFrameOrigin` may set `inLiveResize` on the embedded `SKView`, starving draws during drag.

**Reference:** [SpriteKit refresh during live resize](https://developer.apple.com/forums/thread/96073) — override `inLiveResize` to return `false` on a custom `SKView` subclass so draws continue during window moves (candidate fix; validate with perf logs first).

### 4. Texture churn

Each `paintCurrentFrame` allocates a new `SKTexture` from `CGImage`. Direction flips still call `paintCurrentFrame` even when `frameIndex` is preserved (running↔running).

## Debug instrumentation

Enabled by default for local dev:

- **Xcode ⌘R** — the shared `Codogotchi` scheme sets `CODOGOTCHI_FLOATING_PERF_DEBUG=1` under Run → Environment Variables.
- **Terminal** — `bun run mac:run` (builds Debug and launches the app with the same env var).

To turn off in Xcode: edit the scheme → Run → Environment Variables → disable or remove `CODOGOTCHI_FLOATING_PERF_DEBUG`.

Filter Console.app for `FloatingPetPerf`.

Logs include:

- Per translate-drag session: `applyFrame` vs `emitInteraction` ms, interaction changes, `inLiveResize`
- `setInteraction` branch, `paint` ms, `restartTimer`
- Slow paints (> 4 ms)

## Candidate fixes (after logs confirm)

| Priority | Change | Rationale |
|----------|--------|-----------|
| A | Defer `setInteraction` to next run-loop turn during translate | Decouple window move from texture upload |
| B | `FloatingPetSKView` with `inLiveResize == false` | Keep SK drawing during origin moves |
| C | Cache `SKTexture` per interaction frame index | Avoid realloc on direction flip |
| D | Swap textures without `restartTimer` when only running direction changes | Reduce timer churn |
| E | Coalesce interaction updates (hysteresis / min horizontal delta) | Fewer swaps near zero velocity |

Do not ship A–E until perf logs show which path dominates.

## Fix 14 (implemented)

**Root cause (confirmed via logs):** `floatingFrames(forInteraction:)` re-sliced and re-rasterized the full Codex row on every `setInteraction` (~200 ms), on the same run-loop turn as `setFrameOrigin`.

**Change:** `MaliPet` pre-warms and caches floating interaction rows at pet load. Perf logs now include `framesLoad=…ms` — expect **&lt;1 ms** on direction flips after fix vs **~200 ms** before.
