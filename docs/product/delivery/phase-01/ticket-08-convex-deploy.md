# P1.08 Convex Cloud production deploy + two-profile smoke

Size: 2 points
Type: chore
Scope: convex

## Outcome

- A production Convex deployment exists, owned by the project owner.
- The HTTP action URL is recorded in `docs/contracts/convex-deployment.md` (private — not in public docs) along with deployment ID and Convex dashboard link.
- Both owner and buddy have run `curl`-based smoke POSTs to `/sync` and received valid responses. Their two profiles are visible in the Convex dashboard with independent state.
- A short smoke-test script at `scripts/convex-smoke.ts` (Bun) can be re-run any time to verify deploy health: POSTs a fixed test payload, asserts response shape, checks no cross-bleed.
- `~/.codogotchi/config.json` schema (defined for P1.12) reserves a `convex_http_url` field. Owner + buddy's configs are populated manually for this ticket; P1.12's `setup` command consumes the URL going forward.

## Red

- Skip Red — deploy is an ops action, not a behavior change. The `convex-smoke.ts` script *is* the assertion artifact and runs in this ticket but is not a `[red]` commit.

## Green

- Run `bun x convex deploy --prod` (or equivalent) from the project owner's machine. Capture the deployment URL.
- Author `docs/contracts/convex-deployment.md` recording: deployment ID, HTTP action URL, dashboard link, who has owner/admin access.
- Author `scripts/convex-smoke.ts` that:
  - Reads the URL from `process.env.CODOGOTCHI_CONVEX_URL` or a CLI flag.
  - POSTs a synthetic-signals payload for two distinct UUIDs.
  - Asserts both responses have populated `total_xp` and independent values.
  - Exits non-zero on failure.
- Run the smoke from owner's machine. Then have the buddy run it from theirs (or run a buddy-payload manually with their UUID). Capture screenshots/output in the PR description.

## Refactor

- None.

## Review Focus

- Deployment URL is **not** committed in any public-tracked file (the contract doc has limited circulation; consider gitignoring it or storing only the dashboard link publicly).
- `scripts/convex-smoke.ts` is runnable post-merge by anyone with the URL; it's not a one-time artifact.
- Two-profile assertion is real (uses two UUIDs, asserts both rows exist with independent `total_xp`), not just "two HTTP 200s."
- PR description includes the smoke output or a screenshot of the Convex dashboard showing two distinct profile rows.
- No production secrets leak into the PR description.

## Rationale

> Append here (do not edit above) when behavior or trade-offs change during implementation.
