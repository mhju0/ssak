# ADR 0001: Charm Gate verdict — proceed with fully-procedural ink

- **Date:** 2026-07-17
- **Status:** Accepted
- **Decided by:** Michael Ju (gate owner), per design spec §5

## Context

M0 built the Charm Gate stack — living hanji paper, mountain wash, rain-bleed
driven by real weather, the stroke-spline engine, the carp recipe, and the
staffage keeper (materials: `docs/m0-charm-gate/`). The spec gates all
downstream milestones on charm-at-completion: strangers should recognize and
respond to the procedural art, with a fallback ladder (commission ~15 hero
assets as vector stroke data → pivot to flat-silhouette art direction) if it
failed.

## Decision

**Proceed — ladder rung 1.** The fully-procedural stroke-engine art direction
is confirmed for v1. No commission, no art pivot.

## Evidence

- Michael showed the M0 composite and reveal to 3+ people outside the
  project; all identified the carp unprompted (the #6 hallway test) and the
  review supported proceeding (#8).
- 60 fps on device (iPhone 13 mini — Debug, Release, and forced rain)
  confirmed after the background-bake fix (#12).

## Consequences

- M1 (walkable vertical scroll) planning is unblocked.
- Species art continues as stroke recipes (~30 species budget; per-recipe
  cost checkpoint at M3 per spec §5 stands).
- The commission/pivot ladder remains documented in the spec as a risk
  fallback but is not scheduled.
