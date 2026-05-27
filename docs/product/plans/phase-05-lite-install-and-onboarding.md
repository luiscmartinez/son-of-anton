# Phase 05: Lite Install And Onboarding

**Delivery status:** Draft product plan (not yet decomposed).

## TL;DR

**Goal:** Make Codogotchi usable as a standalone desktop pet immediately after App Store install, with no CLI enrollment, no Convex URL, and no RPG setup required.

**Ships:**

- A first-run Lite onboarding that auto-enables the pet, installs hooks where possible, and makes “why is my pet not animating?” impossible to miss.
- Settings-first configuration: install/status of hooks per platform, pet selection, and an “Enable Alive (RPG)” unlock path.
- A single canonical local home (`~/.codogotchi/`) with bundled pet assets so Codogotchi does not depend on `~/.codex/pets/*` to render.

**Defers:**

- Cursor/VS Code/Antigravity parity, attention tray + TTL, and signal honesty improvements (Phase 06).
- XP/level HUD, health visuals/decay, loot equip, premium packs (Phase 08+).

---

Codogotchi already functions as a `state.json` visualizer: the macOS app renders local state and the hook binary writes it. The product friction is onboarding: the only “happy path” today is the Phase 01 CLI `setup` flow, which front-loads Convex enrollment and multiple credentials. Phase 05 flips the default: Lite is the product, Alive (RPG) is an opt-in upgrade.

## Phase Goal

This phase should leave the product in a state where:

- A user can install Codogotchi from the App Store, launch it, and see a working pet without touching Terminal.
- If hooks are not installed or not firing, the app clearly explains what’s missing and offers a one-click path to fix it.
- The app does not require Codex to be installed or running; Codex pets become an optional import source, not a hard dependency.

## Committed Scope

### Lite-First App Store Onboarding

- On first launch, Codogotchi shows a minimal onboarding surface (single window or Settings-first flow) that:
  - Explains that Codogotchi animations are driven by agent hooks.
  - Detects which agent platforms are present on disk (Codex, Claude Code, Cursor, VS Code, Antigravity) and which are unsupported in this phase.
  - Offers “Install hooks” actions with clear success/failure feedback per platform.
- Codogotchi remains functional in a degraded mode when hooks cannot be installed automatically:
  - The pet still renders and can run demo mode.
  - The UI presents a persistent, user-visible “Hooks not active” status until at least one hook event is observed.

### Hook Installation Policy (macOS App)

- Default posture: install hooks automatically when the platform allows it without requiring the user to hand-edit config files.
- When a platform requires user action/permission (or the install path is ambiguous), Codogotchi:
  - Explains the exact action required.
  - Provides a one-click “Open config location” affordance.
  - Does not pretend hooks are active when they are not.

This phase covers only platforms that Codogotchi can install reliably today:

- Codex hooks (`~/.codex/hooks.json` + related config).
- Claude Code hooks (`~/.claude/settings.json`).

Other platforms are explicitly deferred (Phase 06+).

### Settings-First Configuration (No CLI Required)

Add a Settings window (may be minimal in Phase 05, expanded later) with:

- **Hooks** (or Developer) section:
  - Per-platform hook status: `not installed | installed | firing recently | unknown`.
  - Install/uninstall actions for supported platforms.
  - “Last hook event seen” timestamp and detected `source_origin` when available.
- **Pet** section:
  - Select active pet from a local canonical store under `~/.codogotchi/pets/`.
  - Optional import from Codex pets when `~/.codex/pets` exists (best-effort; no multi-pet UX polish required yet).
- **Alive (RPG)** upsell/unlock entrypoint:
  - A clear “Enable Alive (RPG)” call-to-action that moves the user into enrollment (Phase 10 formalizes the full multi-tab settings surface).

CLI support (`codogotchi hooks install`, `codogotchi enroll`) is allowed as a developer convenience, but it is not the primary path in this phase.

### Bundled Pet Assets + Canonical Local Pet Store

- Ship at least one complete pet inside the app bundle and seed it into `~/.codogotchi/pets/<id>/` on first run.
- Codogotchi must be able to render without any dependency on `~/.codex/pets/*`.
- Codex pets are optional: the app can copy/import a selected Codex pet into the canonical codogotchi store, but does not live-read from the Codex folder at runtime.

### Single-User Migration (No Backward Compatibility)

- No backward compatibility guarantees are required.
- It is acceptable to migrate or replace existing local config and hook installation artifacts as needed to support the Lite-first product.
- The plan must still keep failure modes understandable: if existing config is invalid or partial, Codogotchi should offer a “Reset to Lite defaults” action.

## Explicit Deferrals

- Platform parity beyond Codex + Claude Code (Cursor / VS Code / Antigravity adapters, tool alias tables, fixtures).
- Attention bubble + tray + TTL decay.
- Signal honesty improvements (origin attribution fixes, `tool.command` persistence, `work_mode` taxonomy).
- Convex enrollment UX inside the app, XP/HP/loot UI, premium gating, and equip rendering.

## Exit Condition

Phase 05 is done when a clean machine can:

1. Install Codogotchi from the App Store and launch it.
2. See the pet render immediately using bundled assets.
3. Install Codex and/or Claude Code hooks from Settings without editing JSON by hand (for supported platforms).
4. Observe the pet react to real hook events, and see hook status reflect “firing recently”.
5. Understand the degraded path when hooks cannot be installed (clear copy + next action).

## Retrospective

`required` — this phase changes the product’s primary onboarding boundary (CLI-first → App-first) and will likely surface durable learnings about platform hook installability and UX failure modes.

