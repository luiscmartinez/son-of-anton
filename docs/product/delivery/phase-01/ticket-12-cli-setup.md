# P1.12 CLI scaffold + `codogotchi setup`

Size: 2 points
Type: feat
Scope: cli

## Outcome

- `packages/cli/bin/codogotchi.ts` is the CLI entrypoint, registered as `bin.codogotchi` in `packages/cli/package.json`. Subcommand dispatch via a lightweight router (no heavy `commander`/`yargs` dependency unless it earns its keep — Bun's args API + a small switch suffices).
- `codogotchi setup` interactive flow:
  - Prompts for handle (alphanumeric + dash, validates).
  - Generates a UUID locally via `crypto.randomUUID()`.
  - Prompts for GitHub Personal Access Token (skippable; warns about reduced functionality).
  - Prompts for Wakatime API key (skippable).
  - Prompts for Convex HTTP action URL (defaults to a baked-in production URL if owner-side; buddy provides theirs explicitly).
  - Writes `~/.codogotchi/config.json` with all of the above + default `health.*` values.
  - Installs Claude Code hook + Codex hook (writes hook config to `~/.claude/...` and `~/.codex/...` invoking `codogotchi-hook`).
  - Registers the profile by POSTing to `${convex_http_url}/sync` with a zero-signals payload.
  - On success, prints a "you're set up" message including the handle and where to find logs.
- `CODOGOTCHI_HOME` env var redirects the home dir for tests (default `~/.codogotchi/`).
- Tests use a temp `CODOGOTCHI_HOME`, mocked HTTP, mocked stdin to drive prompts. Cover: happy path, skipped optional credentials, invalid handle (retry prompt), pre-existing config (refuse to overwrite without `--force`).

## Red

- Write failing tests for `codogotchi setup` exercising each branch above with tempdir + mocked HTTP/stdin.
- Commit: `test(P1.12): codogotchi setup interactive flow [red]`.

## Green

- Implement the CLI router and `setup` subcommand. Smallest implementation that makes tests pass.
- Hook installation paths and shapes are documented in P1.18 (this ticket installs them but the hook binary itself lands in P1.18 — wire setup to call into a stub `installHooks()` that P1.18 fills out, or land both in this ticket if cleanly separable. Lock the choice in Rationale; recommendation: install only the config entries here, leave actual hook binary execution to P1.18).

## Refactor

- Extract prompt helpers if multiple subcommands grow them.
- Only refactor what this ticket touches.

## Review Focus

- `CODOGOTCHI_HOME` redirection is honored everywhere config is read or written.
- UUID generation is local (not requested from Convex) — buddy onboarding works without coordination.
- `config.json` schema matches what `tickHealth` (P1.04) expects under `health.*`.
- `--force` flag for pre-existing config is documented in `--help`.
- PAT and Wakatime key stored in plain JSON; documented as private-machine-only in the success message (no encryption in Phase 01).
- Hook installation is idempotent — re-running `setup` after Claude Code reinstall does not double-register.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
