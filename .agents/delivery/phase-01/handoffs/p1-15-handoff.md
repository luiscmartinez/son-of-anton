# Ticket Handoff

Phase plan: docs/product/delivery/phase-01/implementation-plan.md
Ticket: P1.15 CLI loot command
Branch: agents/p1-15-cli-loot-command
Base branch: agents/p1-14-cli-status-command
Worktree: /Users/cesar/code/codogotchi_p1_15

## Required Reads

- `docs/template/overview/start-here.md`
- `docs/product/delivery/phase-01/implementation-plan.md`
- `docs/product/delivery/phase-01/ticket-15-cli-loot.md`
- `docs/template/delivery/delivery-orchestrator.md`

## Context Reset Contract

- Re-read the required docs before implementing.
- Start from the current repository state and this handoff artifact, not from prior chat assumptions.
- Carry forward only explicit review notes, review artifacts, and committed branch state.
- Do not read ahead during the AI review wait window. The wait is free (LLM idle during subprocess sleep). Be sabaai sabaai.

## Carry Forward From Previous Ticket

- Previous ticket: `P1.14 CLI status command`
- Previous branch: `agents/p1-14-cli-status-command`
- Previous PR: https://github.com/cesarnml/codogotchi/pull/15
- Review outcome: `patched`
- Review fetch artifact: `docs/product/delivery/phase-01/reviews/P1.14-ai-review.fetch.json`
- Review triage artifact: `docs/product/delivery/phase-01/reviews/P1.14-ai-review.triage.json`

## Stop Conditions

- Stop if the current ticket cannot be completed safely or prerequisite state is missing.
- Stop if review triage is ambiguous enough to require user input.
- Stop if the work requires a broader redesign beyond the ticket scope.

## RESUME COMMAND

`bun run deliver --plan docs/product/delivery/phase-01/implementation-plan.md subagent-review`
