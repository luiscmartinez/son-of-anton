# P1.21 7-day validation runbook + execution

Size: 2 points
Type: docs
Scope: ops

## Outcome

- `docs/runbooks/phase-01-validation.md` documents the exact procedure for verifying each of the eight phase exit conditions, including:
  - Day-by-day checklist (Day 1–7) listing what to confirm and how (Convex query for two-profile isolation, log inspection for no-crash, dashboard screenshots for stage advancement, etc.).
  - The Convex direct-query snippets used to verify each profile's state independently.
  - The expected behavior on a weekend day (HP unchanged), including how to manually verify the weekend-no-decay condition.
  - How to seed XP if real activity proves insufficient for the stage-advancement condition, and how to mark seeded events in `loot_events` / debug log.
  - What to do if a stop condition fires (escalation path back to the plan author).
- The validation is *executed* during this ticket — runbook + 7 days of live operation on both machines. Findings captured in a companion file `docs/runbooks/phase-01-validation-log.md` with daily entries.
- At end of seven days, each of the eight exit conditions has a check (or annotated miss + remediation note) in the log.
- P1.22 (retrospective + doc drift) starts only after this ticket's log confirms 7 days complete or the developer explicitly accepts a shortfall.

## Red

- Skip Red — docs-and-ops ticket. The runbook is reviewed; the log is the artifact of execution.

## Green

- Draft the runbook. Walk both users through it on Day 0.
- Run for seven days. Log daily.
- Capture screenshots / Convex query outputs where useful (especially for exit conditions 2, 3, 5, 6, 8).

## Refactor

- None.

## Review Focus

- Each of the eight exit conditions has a corresponding section in the runbook with a concrete verification procedure (not vague "check Convex").
- The log file's daily entries show real activity, not boilerplate. Missed days are noted, not hidden.
- Seeded XP (if used) is clearly flagged in both the loot events table and the log.
- The "what to do if a stop condition fires" section is real, not "open a ticket and figure it out."
- Two-profile-no-bleed verification uses an actual Convex direct query, output captured, both UUIDs visible with independent totals.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
