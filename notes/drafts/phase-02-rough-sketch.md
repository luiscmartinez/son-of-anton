# Phase 02 — subagentCodeReview Architecture (Rough Sketch)

> Input for `/soa plan` grill-me pass. Not a final plan.
> Derived from: improvement-waves-execution-plan.md + subagent-code-review-design.md + codexpreflight-phase-04-learnings.md

## Goal

Replace the broken `selfAudit` + `codexPreflight` duality with a single, agent-agnostic
`subagentCodeReview` step that actually works — an isolated subagent that has no
access to the implementation session context, reviews the diff against the ticket's
`## Review Focus`, patches what it finds, and commits with `[subagentReview]`.

The self-review bias problem (`selfAudit`) is eliminated structurally, not by convention.

## What changes

### Config schema (`orchestrator.config.json`)

- **Remove** `selfAudit` and `codexPreflight` from `reviewPolicy`
- Hard startup error (not warning) if either key is present in any config
- **Add** `reviewPolicy.subagentCodeReview: "required" | "skip_doc_only" | "disabled"`
- **Add** `claudeReviewSubagentType: "<subagent_type_string>"` — Claude-specific override;
  defaults to `"codex:codex-rescue"` when absent and execution agent is Claude
- **Add** `ai_review_agents: [{ name, login, resolve_threads }]` — vendor whitelist for
  external review fetcher; falls back to built-in default list when absent

### Delivery flow

Before: `implement → verify → post-verify-self-audit → codex-preflight → open-pr → poll-review → advance`

After: `implement → verify → post-verify → subagent-code-review → open-pr → external-review → advance`

### CLI command renames

| Old                      | New                    |
| ------------------------ | ---------------------- |
| `post-verify-self-audit` | `post-verify`          |
| `codex-preflight`        | `subagent-code-review` |

### subagentCodeReview step behavior (agent-agnostic)

Default resolution: execution agent spawns a subagent of its own type.

- Claude execution agent → spawns Claude subagent (via `claudeReviewSubagentType` config, defaults to `"codex:codex-rescue"`)
- Codex execution agent → spawns Codex subagent
- Other agents → use whatever native subagent spawning the platform supports

The subagent receives:

- The diff (ticket branch vs. base)
- The ticket's `## Review Focus` section verbatim
- Instruction: find correctness issues, patch what you find, commit with `[subagentReview]` suffix

The subagent receives **nothing** from the implementation session. No conversation context. No rationale.

If the platform cannot spawn isolated subagents → `subagentCodeReview` must be `"disabled"`. No silent fallback to self-review.

### `fetch_ai_pr_comments.sh` — make data-driven

Remove hardcoded author login patterns. Read `ai_review_agents` from config, build detection set from `login` fields. No vendor-specific branches in the script.

### State.json field changes

Remove: `selfAuditOutcome`, `selfAuditCompletedAt`, `selfAuditPatchCommits`, `codexPreflightOutcome`, `codexPreflightCompletedAt`, `codexPreflightNote`, `codexPreflightPatchCommits`

Add:

- `subagentReviewOutcome: "clean" | "patched" | "needs_patch"`
- `subagentReviewCompletedAt`
- `subagentReviewPatchCommits`
- `subagentReviewAgent` (resolved subagent type — audit trail)

Ticket status progression:

- Remove: `post_verify_self_audit_complete`, `codex_preflight_complete`
- Add: `verified`, `subagent_review_complete`
- New full sequence: `pending → in_progress → verified → subagent_review_complete → in_review → reviewed → done`

### Commit suffix convention

`[codexPreflight]` → `[subagentReview]`

### Documentation

- Update `delivery-orchestrator.md` with new flow, new command names, new config schema
- Add RESUME COMMAND guard to gated handoff artifact (deferred from Phase 04 — write with correct new command names)
- Add `[subagentReview]` suffix ordering note

### Consumer repo updates

Both `pirate-claw` and `coding-stats` need their `orchestrator.config.json` updated.
Any config with `selfAudit` or `codexPreflight` in `reviewPolicy` errors at startup.

## Open questions for grill-me

- Ticket decomposition: one ticket or split by concern (config schema / CLI rename / state / shell script)?
- How do we handle state migration for in-flight phases on consumer repos (currently none active, so may be a non-issue)?
- `claudeReviewSubagentType` default: hard-code `"codex:codex-rescue"` or require explicit config?
- Should `subagent-code-review` accept `--skip` for cases where no subagent is available but the operator wants to proceed?
