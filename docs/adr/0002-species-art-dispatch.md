# ADR 0003: Keep PlantView's (species, stage) switch — don't abstract art dispatch

- **Date:** 2026-07-20
- **Status:** Accepted
- **Decided by:** Michael Ju

## Context

The 2026-07-20 architecture review (`/improve-codebase-architecture`) flagged
`PlantView.plant(_:)` in **SsakArt** as a *shallow* module: a 24-arm
`switch (species.id, stage)` keyed on string literals, dispatching to per-species
art (`MarigoldArt.bloom(palette)`, `CosmosArt.sprout(palette)`, …) with a
`default → Placeholder` fallback for undrawn species. The proposed *deepening* was
a per-species art type or registry so `PlantView` dispatches once, adding a species
touches only its own file, and completeness is compiler-checked.

## Decision

**Keep the switch as-is.** Do not introduce a `SpeciesArt` protocol or a dispatch
registry.

## Reasons (why a future review should not re-suggest this)

1. **Compile-time completeness is impossible across the module boundary.**
   Hand-authored art lives in SsakArt (SwiftUI `View`s); the species catalog is
   plain data in **SsakCore** (`SpeciesCatalog.all: [Species]`, a runtime array),
   which has no SwiftUI dependency and cannot carry a `View`. No abstraction can
   make the compiler prove "every catalog species has art" — completeness is
   inherently a *runtime* property however dispatch is shaped. `Placeholder` is the
   honest expression of that seam.
2. **The abstraction fails the deletion test.** A `SpeciesArt` protocol with six
   conformers just relocates the 24 `(id, stage)` arms into six four-arm stage
   switches plus a lookup — it *moves* complexity rather than *concentrating* it,
   and adds a hop of indirection. Net more code, not less.
3. **`Placeholder` is a deliberate mechanism, not a defect.** It lets an undrawn
   species (the "undrawn species follow-up") ship and render a labeled stand-in
   rather than trap. Enforcing "no placeholder" would fight that intent.
4. At six species the switch is boring, local, and reads top to bottom.

**Reconsider only if:** the catalog grows well past ~10 species (linear switch
growth becomes a real drag), or the string keys start causing real bugs in
practice (a typo silently falling to `Placeholder` that testing doesn't catch).

## Consequences

- `PlantView.plant(_:)` stays the single runtime dispatch seam between the SsakCore
  data catalog and the SsakArt hand-authored drawings.
- Adding a species = add its `case`s in `PlantView` + a new art file (or
  intentionally leave it on `Placeholder`).
- `RenderInvariantsTests.testEachImplementedSpeciesRendersDistinctStages` asserts
  distinct-per-stage rendering but **not** non-`Placeholder` (placeholder text
  varies per stage, so it passes for an undrawn species). Accepted given reason 3 —
  art completeness is a ship-checklist item, not a test invariant.
