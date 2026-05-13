# Phase 10 Draft — TDD Gate Hardening

_Drafted: 2026-05-13_
_Status: Pre-planning draft — not yet through `/soa plan`_
_Source: Phase 04 deferred improvements + P6/P7 retrospective follow-up items_

---

## Thesis

The red-green-refactor cycle is SoA's primary quality gate against AI-generated code that looks complete but isn't. It works well in practice — the workflow has survived seven phases without a false green. But two gaps leave the gate softer than it should be for beta: a "red commit" has no machine-readable proof that any test actually failed, and the `post-verify` step has no signal when uncommitted implementation changes are sitting in the working tree. This phase hardens both without over-engineering either.

One additional housekeeping item — `cspell.json` review artifact path exclusion — belongs here because it's a small template fix that prevents a recurring spellcheck failure pattern first seen in P7.

---

## The Gaps

### 1. `post-red` CLI command (primary)

**Source:** Phase 04 deferred improvements (`notes/private/phase-04-deferred-improvements-to-soa.md`).

**What happens today:** The TDD workflow requires a red commit before implementation. The commit exists in git history, but the orchestrator has no record of it and no verification that any test actually failed. A red commit is just a commit with "[red]" in its subject. An agent could trivially skip the failing-test step and proceed straight to green without the orchestrator noticing.

**Proposed command:**

```bash
bun run deliver --plan <path> post-red [ticket-id]
```

What it does:
1. Reads the HEAD commit on the ticket's branch
2. Asserts the subject contains `[red]` (configurable prefix check)
3. Runs the repo's `verify` or `ci` command and asserts at least one test fails (non-zero exit from test runner, or specific failure count > 0)
4. Records the red commit SHA and assertion result in `state.json` as `redCommitSha` on the ticket
5. Advances ticket status from `in_progress` to `red_complete`

`post-verify` then requires `red_complete` as a prerequisite for code tickets (doc-only tickets skip this gate, same as the current `subagentReview` skip).

**What changes in state:**

New ticket status: `red_complete` (between `in_progress` and `verified`).

New field on `TicketState`: `redCommitSha?: string`.

The status machine becomes:
```
pending → in_progress → red_complete → verified → subagent_review_complete → in_review → reviewed → done
```

Doc-only tickets skip `red_complete` (same pattern as `subagentReview` skipping).

**Design constraint:** `post-red` should NOT run the full test suite against the green implementation. It only runs `verify`/`ci` and asserts failure. The test run here is expected to fail — that's the proof. Green verification happens at `post-verify` as it does today.

**DI pattern:** The test runner invocation should be injectable via `runProcessOverride` for unit tests, following the existing `hasLocalBranchCommits` pattern. No real CI required in unit tests.

### 2. Uncommitted changes warning in `post-verify`

**Source:** Phase 03 agent retrospective (`notes/private/phase-03-agent-retrospective.md`), "git stash confusion."

**What happens today:** If the working tree has uncommitted or staged changes when `post-verify` runs, the command succeeds silently. The agent may have implemented something and forgotten to commit it before running `post-verify`. The implementation is never included in the branch history. This is not a crash — it just means the green commit may be incomplete.

**Proposed change:** At the start of `recordPostVerify`, if `git status --porcelain` returns non-empty output, print a warning:

```
Warning: working tree has uncommitted changes.
Confirm these are intentional before recording post-verify clean.
Uncommitted files:
  M src/foo.ts
  A src/bar.ts
```

This is a warning, not a blocking error. The operator (or agent) sees it and can decide to commit first or proceed. The current behavior where silently proceeding is fine stays unchanged — only the signal is added.

The check should be injectable via a `getWorkingTreeStatus` override for unit tests.

### 3. `cspell.json` review artifact `ignorePaths` in template

**Source:** Phase 07 retrospective follow-up, explicit item.

**What happens today:** When the orchestrator writes review artifacts (`*.fetch.json`, `*.triage.json`) to `docs/product/delivery/<plan-key>/reviews/`, those paths are not in `cspell.json`'s `ignorePaths`. The first time a review artifact is written, spellcheck fails on it (P7.02 was broken mid-phase by this). Every consumer repo that sets up SoA hits this on their first code ticket with PR review enabled.

**Fix:** Add `docs/product/delivery/*/reviews/**` to `cspell.json`'s `ignorePaths` in the SoA source repo template. This is a one-line change to [cspell.json](../../cspell.json) in the SoA source repo itself, plus a note in `soa-sync.sh` that new consumers should add the same entry to their own `cspell.json` on setup.

This should also be added to the setup instructions in README.md's Install section alongside the existing `.prettierignore` guidance.

---

## Out of Scope

- Full `post-red` test harness analysis (which tests failed, how many, which files). The only assertion needed is "at least one test failed." Detailed failure attribution belongs to the agent reading the output, not to the orchestrator.
- Review artifact atomic commit with `advance`. The P6 retro flagged this as a desirable improvement but it requires changes to the advance boundary model and deserves its own design pass. Deferred.
- Shell script executable-bit enforcement (automated). The right fix is one sentence in the ticket template stub: "If creating or modifying shell scripts, run `chmod +x <path>` after writing." No infrastructure needed; agents catch this quickly when reminded once.
- `reconcile-late-review` finalize path. Deferred.

---

## Rationale

The `post-red` command closes the primary loophole in the TDD gate: an agent can currently skip failing tests entirely without the orchestrator detecting it. The commit subject is a human-readable convention; the SHA record makes it machine-readable and verifiable. For beta, SoA's TDD story should be "the orchestrator verified a failing test before implementation," not "the agent was supposed to write a failing test first."

The uncommitted-changes warning is a one-function change that catches a class of subtle agent mistakes (implementing something, running verify, forgetting to commit) that are otherwise invisible until code review.

The `cspell.json` fix is pure hygiene — it hits every consumer on their first code ticket and takes one line to fix.

Together these three items complete the delivery contract hardening that makes beta a credible "hand it to a stranger and expect them to succeed" moment.
