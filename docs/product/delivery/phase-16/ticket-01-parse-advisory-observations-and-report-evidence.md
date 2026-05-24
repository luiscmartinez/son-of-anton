# P16.01 Parse Advisory Observations and Report Evidence

Size: 3 points
Type: feat
Scope: delivery
Red: required

## Outcome

- A delivery helper can parse `Actionable findings` and `Advisory Observations` sections from subagent-review report Markdown.
- The parser treats `None.`, empty bodies, and missing sections as no findings.
- The parser preserves advisory observation prose as triageable items without treating them as blocking actionable findings.
- The helper can inspect subagent-review ledger rows and report paths to flag suspicious evidence when a `clean/completed` row points to missing or empty report prose.

## Red

- Add behavior-first tests covering:
  - `Advisory Observations` with bullet items.
  - `Advisory Observations` with prose paragraphs.
  - `Advisory Observations` containing `None.`.
  - Missing `Advisory Observations` section.
  - Existing `Actionable findings` parsing still detects blocking findings.
  - A `clean/completed` ledger row whose `rawOutput` file is missing or empty is flagged as suspicious evidence.
- Run the focused tests and confirm they fail.
- Commit with suffix `[red]`: `test(P16.01): parse advisory observations and report evidence [red]`.
- Do not write implementation until this commit exists on the branch.

## Green

- Add a focused delivery module or extend the existing reconciliation parsing module with advisory-observation parsing helpers.
- Reuse existing `Actionable findings` parsing behavior where practical, but keep advisory observations as separate non-blocking output.
- Represent suspicious evidence as structured data that later tickets can render or persist.

## Refactor

- Keep parsing helpers pure and filesystem-light where possible.
- Avoid coupling parser output to the eventual CLI command format.

## Review Focus

- Verify that advisory observations do not become blocking actionable findings.
- Verify heading matching tolerates whitespace and common Markdown drift without accepting unrelated sections.
- Verify suspicious evidence detection is warning-oriented data, not a reconciliation failure.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.

Red first: [what test failed first]
Why this path: [why this implementation was the smallest acceptable]
Alternative considered: [one rejected alternative and why]
Deferred: [what was intentionally left out of this ticket]
Contract note: record any deviation from the ticket metadata contract here, including missing/incorrect `Type:` or non-compliant `Scope:` fields, and why it happened.
