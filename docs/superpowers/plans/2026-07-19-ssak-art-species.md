# Ssak Art — Remaining Five Species Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (or subagent-driven-development for the mechanical parts). Steps use checkbox (`- [ ]`). **These are visual/iterative art tasks** — each stage is *authored* against the render→inspect loop (see Plan 2's "authored, not transcribed" note), not transcribed from fixed coordinates. Author inline with a consistent hand; render, look, iterate.

**Goal:** Author the four unique stages (sprout, leaves, bud, bloom) for the remaining five species — Cosmos, Zinnia, Sunflower, Nasturtium, Morning glory — reusing the `SsakArt` framework built in Plan 2, so all six flowers grow through visibly distinct, species-true lifecycles.

**Architecture:** No new infrastructure. Each species gets one file (`Cosmos.swift`, …) with an enum exposing `sprout/leaves/bud/bloom(_ palette:) -> some View`, drawn in `Canvas` with the shared helpers (`leafPath`, `frondPath`, `petalPath`, `petalRing`, `stemPath`) plus species-specific helpers where a form needs one (feathery foliage, ray-disk, funnel/trumpet). `PlantView`'s dispatcher gains one case-group per species. The shared seed frame (`SeedSoil`) already covers every species' seed stage via tint.

**Tech Stack:** Same as Plan 2 — SwiftUI `Canvas`, `ImageRenderer`, SwiftPM. Verify with `cd SsakArt && swift build / swift test / swift run SsakArtRender`.

## Global Constraints

- Reuse the Plan 2 framework; add NO new dependencies and no runtime generation engine. Static hand-authored vector art only. — verbatim.
- Every species' four post-seed stages must be **unique** (spec §5.2); seed stays the shared tinted `SeedSoil`. Detail ramps restrained (sprout/leaves) → lavish (bud/bloom). — verbatim.
- Each stage draws in its own frame with the **soil line at the bottom** (y = height), plant centered on x = width/2, growing up — so `PlantView` roots it correctly (same contract as marigold).
- Species identity/order/values come from `SsakCore.SpeciesCatalog`; do not redefine. Marigold's existing look is locked — do not regress it.
- Branch: `ssak-art-species` (stacked on `ssak-art-foundation` / PR #34, where `SsakArt` lives). Rebase onto `main` once #34 merges.

## Species form reference (the botanical direction)

| Species | Foliage | Bud | Bloom | Palette direction |
|---|---|---|---|---|
| **Cosmos** 코스모스 | fine, threadlike/feathery leaflets; wispy tall stem | slim green bud, faint pink tip | **single daisy**: 8 broad rounded ray petals in ONE ring around a small yellow disk; airy | pink `bloom`, magenta deep, pale-pink highlight, yellow center |
| **Zinnia** 백일홍 | opposite lance-shaped leaves, sturdy stem | plump green bud, red tips | **layered dahlia-like head**: 2–3 rings of broad rounded petals, tighter than marigold, yellow-fleck center | bold red/rose `bloom`, crimson deep, coral highlight |
| **Sunflower** 해바라기 | large broad heart/spade leaves, thick stem, tall | big green bud with sepals | **ray + disk**: ONE ring of long golden pointed ray petals around a LARGE brown seed disk (stippled) | golden-yellow `bloom`, amber deep, pale-yellow highlight, brown disk |
| **Nasturtium** 한련화 | round **peltate shield** leaves (circular, radiating veins) | small pointed bud | **open trumpet**: 5 broad rounded petals in a shallow funnel, dark throat nectar lines | orange-red `bloom`, deep red, yellow highlight, blue-green foliage |
| **Morning glory** 나팔꽃 | heart-shaped leaves on a **twining vine** | a **furled spiral** bud | **funnel trumpet** face-on: rounded pentagon face, pale 5-point star throat, violet rim | violet `bloom`, deep purple, pale-lilac highlight |

---

### Task 0: Palette centers + tune the five species palettes

**Files:** Modify `SsakArt/Sources/SsakArt/SpeciesPalette.swift`.

**Interfaces:** add `public let center: Color` to `SpeciesPalette` (the disk/eye color: marigold→`bloomDeep`-ish, cosmos/zinnia→yellow, sunflower→brown, nasturtium→deep throat, morning glory→pale). Replace the provisional `marigoldLike(...)` entries with tuned per-species palettes. Marigold's values are unchanged except gaining a `center`.

- [ ] Step 1: Add `center` to the struct + `init`; give marigold `center` = its `bloomDeep`.
- [ ] Step 2: Write real palettes for nasturtium/cosmos/zinnia/sunflower/morning_glory (bloom, bloomDeep, bloomHighlight, foliage, foliageDeep, seedTint, center) — pick from the table; foliage may vary (nasturtium blue-green, others warm green).
- [ ] Step 3: `swift build` + `swift test` green (palette test still passes; marigold renders unchanged — confirm `marigold_bloom.png` is visually identical).
- [ ] Step 4: Commit `feat(art): palette centers + tuned palettes for the five species`.

---

### Task 1: Cosmos (single daisy, feathery foliage)

**Files:** Create `SsakArt/Sources/SsakArt/Cosmos.swift`; modify `PlantView.swift` (add cosmos cases); modify `RenderInvariantsTests.swift` (distinctness for cosmos); modify `Render.swift` (write `cosmos_<stage>.png` + `cosmos_row.png`).

**Form:** sprout — thin stem, 2 narrow threadlike cotyledons. leaves — tall wispy stem with several **feathery** fronds (many very thin leaflets; add a `featheryFrond` helper: a rachis with 6–10 hair-thin leaflets). bud — slim green spindle bud, faint pink at the tip. bloom — **one ring of 8 broad rounded ray petals** (`petalRing` count 8, wide `petalPath`, pink) around a small yellow disk (`center`); simple, airy, clearly NOT a pompom.

- [ ] Step 1: Author the four stages in `Cosmos.swift` (Canvas), iterating each via render→inspect until it meets the form + detail bar.
- [ ] Step 2: Register cosmos in `PlantView` dispatcher.
- [ ] Step 3: Extend the distinctness test to cosmos (5 stages mutually distinct); `swift test` green.
- [ ] Step 4: Render `cosmos_row.png`, open it — five distinct, species-true stages, restrained→lavish. Iterate.
- [ ] Step 5: Commit `feat(art): cosmos lifecycle (single daisy, feathery foliage)`.

---

### Task 2: Zinnia (layered head, lance leaves)

**Files:** Create `Zinnia.swift`; modify `PlantView.swift`, `RenderInvariantsTests.swift`, `Render.swift`.

**Form:** sprout — sturdy short stem, 2 broad cotyledons. leaves — opposite **lance-shaped** leaves (use `leafPath`, longer/narrower) up a thick stem. bud — plump green bud, red petal tips showing. bloom — **layered dahlia-like head**: 2–3 `petalRing`s of broad rounded petals (fewer, broader, tighter than marigold), bold red/rose, small yellow-fleck center. Reads bold and geometric vs marigold's ruffled pompom.

- [ ] Step 1: Author the four stages (Canvas), render→inspect→iterate.
- [ ] Step 2: Register zinnia in `PlantView`.
- [ ] Step 3: Distinctness for zinnia; `swift test` green.
- [ ] Step 4: Render `zinnia_row.png`, open, iterate.
- [ ] Step 5: Commit `feat(art): zinnia lifecycle (layered head, lance leaves)`.

---

### Task 3: Sunflower (ray + disk, big leaves)

**Files:** Create `Sunflower.swift`; modify `PlantView.swift`, `RenderInvariantsTests.swift`, `Render.swift`.

**Form:** sprout — thick stem, 2 big cotyledons. leaves — large broad **heart/spade** leaves (a `broadLeaf` helper — wide with a notched base), thick tall stem. bud — big green bud wrapped in pointed sepals. bloom — **one ring of long golden pointed ray petals** (`petalRing`, count ~20, long, pointed `leafPath`-style, golden) around a LARGE brown seed disk (`center`) with a stippled texture (scatter small dots — a fixed hand-placed pattern, not random). The disk dominates; the head is big and cheerful.

- [ ] Step 1: Author the four stages (Canvas), render→inspect→iterate.
- [ ] Step 2: Register sunflower in `PlantView`.
- [ ] Step 3: Distinctness for sunflower; `swift test` green.
- [ ] Step 4: Render `sunflower_row.png`, open, iterate. Watch top-of-frame clipping (big head — give headroom).
- [ ] Step 5: Commit `feat(art): sunflower lifecycle (ray-and-disk head, broad leaves)`.

---

### Task 4: Nasturtium (round shield leaves, open trumpet)

**Files:** Create `Nasturtium.swift`; modify `PlantView.swift`, `RenderInvariantsTests.swift`, `Render.swift`.

**Form:** sprout — stem, 2 small rounded cotyledons. leaves — the signature **round peltate shield leaves** (circles with radiating vein lines from an off-center point; a `shieldLeaf` helper), a few on stalks. bud — small pointed green bud with a hint of the spur. bloom — **open trumpet**: 5 broad rounded petals (`petalRing` count 5, wide rounded `petalPath`) forming a shallow funnel, warm orange, with short dark **nectar guide lines** toward a small throat. One showy open flower.

- [ ] Step 1: Author the four stages (Canvas), render→inspect→iterate.
- [ ] Step 2: Register nasturtium in `PlantView`.
- [ ] Step 3: Distinctness for nasturtium; `swift test` green.
- [ ] Step 4: Render `nasturtium_row.png`, open, iterate.
- [ ] Step 5: Commit `feat(art): nasturtium lifecycle (shield leaves, open trumpet)`.

---

### Task 5: Morning glory (twining vine, funnel trumpet)

**Files:** Create `MorningGlory.swift`; modify `PlantView.swift`, `RenderInvariantsTests.swift`, `Render.swift`.

**Form:** sprout — thin stem, 2 heart cotyledons. leaves — **heart-shaped** leaves on a **twining vine** (stem drawn with a spiral/wrap around a support line). bud — a **furled spiral** bud (a twisted cone — a rolled petal). bloom — **funnel trumpet face-on**: a rounded pentagon face (5 gentle lobes), a pale **5-point star** radiating from a white throat, violet rim deepening outward. Distinctly a morning glory, not a daisy or pompom.

- [ ] Step 1: Author the four stages (Canvas), render→inspect→iterate.
- [ ] Step 2: Register morning glory in `PlantView` (id `morning_glory`).
- [ ] Step 3: Distinctness for morning glory; `swift test` green.
- [ ] Step 4: Render `morning_glory_row.png`, open, iterate.
- [ ] Step 5: Commit `feat(art): morning glory lifecycle (twining vine, funnel trumpet)`.

---

### Task 6: All-species collection sheet + final review gate

**Files:** Modify `Render.swift` (a 6×5 grid of every species×stage → `all_species_grid.png`); modify `.gitignore` (track the grid).

**Interfaces:** `SsakArtRender` writes `all_species_grid.png` — six rows (species in catalog order), five columns (stages) — the whole collectible garden at a glance.

- [ ] Step 1: Add the grid render (each cell `PlantView`, ~160×200).
- [ ] Step 2: Regenerate + `swift test` green (all species' distinctness).
- [ ] Step 3: **Visual review gate** — open `all_species_grid.png`: six clearly *different* flowers, each with five visibly distinct stages, cohesive under one calm style. This is the collection sign-off.
- [ ] Step 4: Track the grid; commit `feat(art): all-species collection grid + review gate`.

---

## Self-Review (spec coverage)

- **6 species × 5 stages, all unique post-seed (§5.2):** Tasks 1–5 add four unique stages each; seed shared via `SeedSoil`. ✓
- **Detail ramps to bloom; species-true forms:** each task ramps restrained→lavish and specifies a distinct bloom architecture (daisy / layered head / ray-disk / trumpet / funnel) so no two species read alike. ✓
- **Reuse framework, no new engine:** only `Canvas` + shared helpers + small per-species helpers; no dependencies. ✓
- **Marigold not regressed:** Task 0 keeps marigold values; palette gains `center` only. ✓
- **Testing discriminates:** per-species distinctness (5 stages mutually distinct) extends the Plan 2 guard; visual gates cover subjective quality. ✓

**Placeholder note:** as in Plan 2, the stage tasks carry form + palette + detail-bar + verification rather than final coordinates — the documented "authored, not transcribed" model for visual work.
