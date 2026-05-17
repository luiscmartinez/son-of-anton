# P1.20 Ops — scheduled job + `scorePR` debug log + hook event fixtures

Size: 2 points
Type: chore
Scope: ops

## Outcome

- `scripts/install-scheduled-sync.sh` (macOS launchd flavor) generates and loads a `LaunchAgent` plist at `~/Library/LaunchAgents/com.codogotchi.sync.plist` that runs `codogotchi sync` every 15 minutes. Idempotent — re-running unloads and reloads cleanly.
- A cron variant `scripts/install-scheduled-sync-cron.sh` (for Linux or non-launchd setups) writes a crontab entry. Same cadence.
- Both owner and buddy install via the script during P1.21's validation week.
- `~/.codogotchi/scorePR.log` is written by the GitHub source (`packages/engine/src/sources/github.ts`) on every `scorePR` invocation: one JSON line per decision, including PR URL, score, breakdown of inputs, and explanation string. Append-only, rotated at 10MB like `sync.log`.
- `packages/engine/test/fixtures/hooks/{claude,codex}/` contains recorded event fixtures captured against the *current* Claude Code and Codex schemas. A script `scripts/capture-hook-fixtures.sh` documents how they were captured so they can be re-captured if upstream changes shape.
- `docs/runbooks/scheduled-sync.md` documents both install paths and how to inspect logs.

## Red

- Skip Red — this ticket is ops scripts, log wiring (one append-only-write line of code in the GitHub source), and recorded fixtures. The fixture *files* are the assertion artifact for downstream tickets; they get exercised in P1.18 / P1.19 tests when those tickets reference them.

## Green

- Author the two install scripts. Test on owner's machine; buddy tests during P1.21.
- Add the `scorePR` log writing to `sources/github.ts` (revisit P1.10's `Rationale` if it didn't already wire this).
- Capture hook fixtures via instrumented runs of Claude Code + Codex; store as JSON files in the fixtures dir.
- Write the runbook.

## Refactor

- None expected — ops scripts and fixture files.

## Review Focus

- launchd plist is correct (loads, runs on schedule, logs to a known path). Reviewer runs `launchctl list | grep codogotchi`.
- Cron variant is idempotent: re-running the script does not duplicate the crontab line.
- `scorePR` log entries are parseable (valid JSON per line) and informative (every input that drove the score is captured).
- Hook fixtures cover at least: Claude Code `PreToolUse`, `PostToolUse`, `Stop`; Codex equivalents; one PR-merge-adjacent event if reachable.
- Runbook is human-followable by the buddy without IRC support.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
