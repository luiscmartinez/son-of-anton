# P14.04 Artifact triplet rename

Size: 2 points
Type: refactor
Scope: subagent-review
Red: skip

## Outcome

- The three subagent-review artifact files are written under new names:
  - `*-subagent-adversarial-prompt.md` → `*-subagent-review.prompt.md`
  - `*-subagent-review-outcome.md` → `*-subagent-review.report.md`
  - `*-subagent-runner.json` → `*-subagent-review.ledger.json`
- The orchestrator and CLI write only the new names. No dual-name fallback.
- All consumer-repo-discoverable references to the old triplet names are updated: orchestrator writers, file-resolution probes, retrospective templates, agent-facing skill prose, README, `docs/template/**` references, `.gitignore` template snippets, example/fixture file paths in tests.
- The `runnerKind` field name inside the ledger row is unchanged — only the artifact _filename_ changes.
- Existing flow tests (which were previously asserting old-name file existence) are updated to reference new names; no behavior regression.
- **Green test target:** `bun test` (full suite) passes after the rename sweep; specifically `tools/delivery/test/cli-runner.test.ts` and `tools/delivery/test/orchestrator.test.ts` continue to pass with new-name file expectations.
- **Manual demo command:** run an end-to-end ticket through the orchestrator in a fixture worktree. Inspect the resulting `docs/product/delivery/<plan>/reviews/` directory. Verify `*-subagent-review.{prompt.md, report.md, ledger.json}` exist for the ticket; verify the old-name files (`*-subagent-adversarial-prompt.md`, `*-subagent-review-outcome.md`, `*-subagent-runner.json`) are **absent** from the writer output.

## Red

`Red: skip` — this ticket is a mechanical file-path rename. Per the ticket template:

> **Doc-only tickets (branch touches only `.md` or `.json` files): skip the Red step structurally, regardless of the `Red:` value.**

The TypeScript path-constant updates touch `.ts` files but are still rename-only (no new behavior). Existing flow tests prove no regression. Writing new tests that assert specific filename strings would couple the test suite to legitimate path changes without quality signal. The acceptance gate is the full test suite passing post-rename.

No `[red]` commit. Proceed directly to the rename sweep.

## Green

- Update path constants in `tools/delivery/subagent-runner.ts` and `tools/delivery/cli-runner.ts` where the writer composes filenames.
- Update `tools/delivery/subagent-prompt.ts` and any prompt-writing step that names the prompt file.
- Update `tools/delivery/state.ts` if it stores the artifact paths in state.json.
- Update file-resolution probes (anywhere code reads `*-subagent-runner.json` to discover prior rows): the new name is the only path probed.
- Update test fixtures and any test that asserts a filename match.
- Update `docs/template/delivery/delivery-orchestrator.md` references.
- Update `docs/template/delivery/adversarial-review-template.md` references.
- Update `docs/template/delivery/son-of-anton.md` references if it names the triplet.
- Update `docs/template/stubs/*` if any stub mentions the old names.
- Update `.agents/skills/**/SKILL.md` files that reference the old names.
- Update `README.md` if the artifact names appear there.
- Update `scripts/soa-sync.sh` if it copies or mentions the artifact paths.
- Update `.gitignore` template snippets (if any) that pattern-match old names.
- Update example fixtures in `tools/delivery/test/fixtures/` and consumer-facing examples.
- Run `bun test`; confirm full suite green.
- Run a fixture end-to-end ticket via `bun run deliver --plan <fixture> execute <ticket>`; verify produced files match new triplet.
- Commit: `refactor(P14.04): rename subagent-review artifact triplet to {prompt,report,ledger}`

## Refactor

- If filename composition was duplicated across writers, extract a single `subagentReviewArtifactPaths(ticket)` helper that returns `{prompt, report, ledger}`. Only consolidate what you touched.

## Review Focus

- **Completeness of the sweep.** This is the load-bearing review concern for this ticket. Use `git grep` for `subagent-runner.json`, `subagent-review-outcome.md`, `subagent-adversarial-prompt.md`, and any near-spellings across the entire repo (including `.son-of-anton/`-prefixed paths in consumer subtree contexts). Any remaining hit is a stop-condition trigger per the implementation plan.
- **No dual-name fallback.** Verify the reader probes only the new name. If a reader silently falls back to the old name on miss, the clean-cutover contract is violated.
- **Test fixture migration.** Any committed fixture artifact under `tools/delivery/test/fixtures/` should rename too, so fixtures reflect post-Phase-14 reality. Don't leave stale-named example artifacts.
- **`runnerKind` field is unchanged.** Only filenames change; the JSON schema field `runnerKind` keeps its value (`claude-cli`, `codex-cli`). A grep for `runnerKind` should show no diff.
- **Gitignore template.** If the `.gitignore` template in `docs/template/stubs/` patterns the old `trace.log` location, update it. (P14.05 owns the trace.log mechanism itself; P14.04 only updates path strings already in the template surface.)

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: [N/A — Red:skip rename ticket; no failing test required]
Why this path: [why this rename approach was chosen, especially if a single-sweep vs incremental approach was considered]
Alternative considered: [one rejected alternative and why]
Deferred: [what was intentionally left out of this ticket]
Contract note: record any deviation from the ticket metadata contract here.
