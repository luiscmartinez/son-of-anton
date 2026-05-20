# P13.03 Make subagent-review consume the written prompt and enforce advisory-only behavior

Size: 5 points
Type: feat
Scope: delivery
Red: required

## Outcome

- `subagent-review --preferred-runner ...` sends the filled prompt produced by `write-subagent-adversarial-review`, not the current generic changed-files prompt.
- The runner artifact records the full filled prompt inline alongside the raw runner response.
- The subagent runner is advisory-only: any runner-created file change is treated as a contract violation, not as a valid patched review outcome.
- Primary-agent patch recording remains available through recorder mode after the primary agent applies findings.
- The old generic `buildSubagentReviewPrompt` path is removed or reduced to test-only/history-free code that cannot be used by the runner.

## Red

- Add failing coverage that runner invocation reads prompt content from the persisted prompt artifact.
- Add failing artifact coverage that the exact filled prompt is persisted inline on the invocation record.
- Add failing coverage that a runner modifying any tracked or untracked file cannot produce `outcome: clean` or `outcome: patched`.
- Add failing coverage that primary-agent recorder mode can still record `patched <reviewed-sha> <patch-sha>` after a runner returned findings.
- Run the targeted tests and confirm the new tests fail.
- Commit with suffix `[red]`: `test(P13.03): cover prompt consumption and advisory-only runner [red]`
- Do not write any implementation until this commit exists on the branch.

## Green

- Replace runner prompt construction with prompt-artifact reading.
- Add inline `filledPrompt` capture to each programmatic runner invocation in the artifact.
- Enforce a clean worktree before runner start or record the pre-existing dirty set and compare after runner exit. The final rule must prevent runner-created writes from being treated as valid review output.
- If a runner writes files, record an honest contract-violation outcome/termination state and block clean completion. Do not keep the current "patched means runner modified worktree" model for programmatic runner mode.
- Keep recorder mode for primary-agent follow-up patches. Patched outcomes should represent primary-agent-applied patches, not subagent writes.

## Refactor

- Separate runner process execution from post-run artifact decision logic enough that the no-write rule is testable without spawning real CLIs.
- Keep artifact additions additive unless a stop condition is reached.
- Remove or quarantine stale generic prompt builder behavior so future code cannot accidentally bypass the written prompt.

## Review Focus

- Verify the prompt sent to codex/claude is byte-for-byte the persisted filled prompt.
- Verify the artifact contains both `filledPrompt` and raw response evidence inline.
- Verify programmatic runner writes are not accepted as review patches.
- Verify recorder-mode patches still require `[subagent-review]` commit suffixes.
- Verify no-write enforcement handles untracked files and HEAD changes.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: prompt-consumption and no-write tests should fail because current code builds a generic prompt and treats runner writes as patched.
Why this path: make the docs' filled-template promise true and preserve role separation between advisory subagent and primary-agent patching.
Alternative considered: allow subagent patches but capture them better, rejected because it keeps reviewer and patcher roles conflated.
Deferred: docs/template wording cleanup and retrospective.
Contract note: `subagent-review` remains the command name, but it now means advisory subagent adversarial review.
