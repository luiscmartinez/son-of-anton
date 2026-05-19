# Ticket Handoff

Phase plan: docs/product/delivery/phase-01/implementation-plan.md
Ticket: P1.09 Source: shared JSONL parser (Claude Code + Codex)
Branch: agents/p1-09-source-shared-jsonl-parser-claude-code-codex
Base branch: agents/p1-08-convex-production-deploy-two-profile-smoke
Worktree: /Users/cesar/code/codogotchi_p1_09

## Required Reads

- `docs/template/overview/start-here.md`
- `docs/product/delivery/phase-01/implementation-plan.md`
- `docs/product/delivery/phase-01/ticket-09-source-jsonl-parser.md`
- `docs/template/delivery/delivery-orchestrator.md`

## Context Reset Contract

- Re-read the required docs before implementing.
- Start from the current repository state and this handoff artifact, not from prior chat assumptions.
- Carry forward only explicit review notes, review artifacts, and committed branch state.
- Do not read ahead during the AI review wait window. The wait is free (LLM idle during subprocess sleep). Be sabaai sabaai.

## Carry Forward From Previous Ticket

- Previous ticket: `P1.08 Convex production deploy + two-profile smoke`
- Previous branch: `agents/p1-08-convex-production-deploy-two-profile-smoke`
- Previous PR: https://github.com/cesarnml/codogotchi/pull/9
- Review outcome: `clean`
- Review fetch artifact: `docs/product/delivery/phase-01/reviews/P1.08-ai-review.fetch.json`
- Review triage artifact: `docs/product/delivery/phase-01/reviews/P1.08-ai-review.triage.json`

## Stop Conditions

- Stop if the current ticket cannot be completed safely or prerequisite state is missing.
- Stop if review triage is ambiguous enough to require user input.
- Stop if the work requires a broader redesign beyond the ticket scope.

## RESUME COMMAND

`bun run deliver --plan docs/product/delivery/phase-01/implementation-plan.md subagent-review`
