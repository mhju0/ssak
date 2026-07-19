# Ssak (싹) — Design Spec

**Date:** 2026-07-19
**Status:** Drafted in brainstorming + grilling session with Michael Ju. Pending user review before writing-plans.
**Working title:** Ssak (싹, "sprout"). One-syllable Korean word, echoes the previous project *Meok* (먹). Rename freely; App Store name check deferred.

**Supersedes:** Meok (먹). The Meok codebase is not extended — it is archived (git tag + push), and Ssak starts fresh in the same repository. See §12.

---

## 1. Concept

Ssak is a **cozy, calm iOS game about raising one flower at a time from seed to bloom**, drawn live by hand-authored vector art, running on the player's real clock. You tend a single plant on a windowsill: water it, watch it grow over real days on its own species' schedule, and when it blooms you press the flower onto a shelf and start the next one. Collect all six species.

The lineage from Meok is deliberate but the ambition is not: same quiet soul (a growing thing, soft ink aesthetic, real time), a fraction of the scope. This is a **first game built to actually finish.**

- No combat, no servers, no accounts, no ads, no IAP. 100% Swift / SwiftUI. Fully offline. Local-only persistence.
- Genre reference points: the calm of a Tamagotchi without the death anxiety; the daily ritual of watering a real windowsill plant.

### Pillars (every decision filters through these)

1. **Finishable first.** The entire reason for the restart. Scope is cut ruthlessly; ~30 authored drawings and two screens is the whole game. If a feature isn't in this spec, it's a someday.
2. **Cozy, never cruel.** No hard fail from a single mistake. Neglect *delays*, it doesn't destroy. The collected shelf is never lost.
3. **Real life, gently compressed.** Each flower grows on its own real (compressed) timeline — a nasturtium is genuinely faster than a morning glory. Watering keeps it healthy enough to grow, exactly like a real plant.
4. **Authored, never generated.** Every drawing is hand-authored static vector art (SwiftUI `Path`/`Shape`). No runtime procedural art engine — that is the specific trap that sank Meok.
5. **Pretty enough to share.** The bloom is a hero moment, exported as a clean framed image.

---

## 2. Core loop

1. Open app → your current plant sits on a windowsill.
2. Check its state (the plant's posture and soil, backed by a small water-drop gauge and a "watered today ✓").
3. Water it if it needs it (a tap). Keeping it healthy lets it keep growing.
4. Over real days it advances: **seed → sprout → leaves → bud → bloom** (~1 real week per plant at cozy pace).
5. On bloom: a seed drops. Press the bloom onto the **shelf**, pick your next species from the remaining seeds, and begin again.
6. Collect all six. The shelf fills; the game keeps being there.

A session is 20 seconds to a couple of minutes. Leave anytime; nothing decays punitively.

---

## 3. Growth model — time-based, gated by care

This is the keystone system; everything else hangs off it.

- **Progress accrues with real elapsed time, but only while the plant is healthy.** A well-watered plant advances on its species' schedule. A thirsty or over-wet plant **stalls** (growth pauses) and resumes the instant you fix it. Being away = it dries = growth pauses = the gentle, non-punishing cost of absence.
- **Stages are visual checkpoints along a continuous 0→1 progress value:**

  | Stage | Progress threshold (tunable) |
  |---|---|
  | seed (in soil) | 0.0 |
  | sprout | ≥ 0.15 |
  | leaves | ≥ 0.40 |
  | bud | ≥ 0.75 |
  | bloom | 1.0 |

- **Growth rate** = `1 / bloomDays` progress per real day, applied only during healthy time. `bloomDays` is per-species (§4).
- All thresholds/rates are **calibration constants**, tuned by feel, not derived. Treat them like a physical-world calibration knob.

### 3.1 Moisture / health

- `moisture` ∈ [0, 1]. Watering raises it toward full. It depletes from full to dry over **~1 real day** (~1.2d, tunable).
- **Healthy band** ≈ [0.25, 0.90]. Inside it, growth accrues normally.
- **Too dry** (< 0.25) or **too wet** (> ~0.95): growth **pauses** and the plant shows the droop/yellow warning (§5.2). Fully recoverable.
- **Multiple waterings per day are allowed** (freedom). Watering when already high pushes toward too-wet. A single day's overwater drains back harmlessly. **Sustained** daily overwatering keeps the plant in the stress zone → prolonged stall.
- **Wilt setback (rare):** only after *many consecutive* stressed days, ignoring the warning throughout, does the plant wilt to a "needs nursing" state (regress one stage, must be nursed back). **Never permadeath. The shelf is never affected.**
- **Overwater nudge:** tapping water when already full shows a gentle *"it's had plenty today"* first; you can still choose to overwater. Freedom + the warning the player asked for.

### 3.2 Streak (global)

- `+1` each real calendar day the plant is kept healthy (watered that day). Resets to 0 on a fully missed day.
- **No penalty** for breaking it — purely a soft reward.
- Shown as a small soft count near the pot. Past a threshold (~3 days), the plant gains a **gentle cosmetic glow**. Rides along on the share card ("day 12").

---

## 4. The six species

Chosen for a fast→slow pacing spread, distinct silhouettes, and a quiet thread of Korean flower-meanings. Real timelines are from verified horticultural research (2026-07-19); game `bloomDays` = real center ÷ ~7 (cozy pace), rounded, all tunable.

| # | Flower (KO) | Meaning / hook | Real sow→bloom | Game bloomDays |
|---|---|---|---|---|
| 1 ★ | **Marigold** 메리골드 | 꽃말 "happiness that's sure to come" — the **starter**, tuned fastest | ~50–60d | **~7** |
| 2 | **Nasturtium** 한련화 | edible petals (a wink at 먹); lily-pad leaves + spurred trumpet | ~50–70d | ~8 |
| 3 | **Cosmos** 코스모스 | the Korean autumn flower; airy, nostalgic | ~55–75d | ~9 |
| 4 | **Zinnia** 백일홍 | name = "hundred-day red," a patient bloomer — on-theme | ~60–75d | ~10 |
| 5 | **Sunflower** 해바라기 | most iconic; sun-facing, good-fortune | ~55–100d | ~11 |
| 6 | **Morning glory** 나팔꽃 | opens at dawn, closes afternoon — real-time hook | ~60–120d | ~13 |

- **Starter is Marigold**, tuned to bloom soonest so the first payoff lands within a week.
- **Species order after the starter:** the player **chooses** their next seed from the remaining species when a bloom drops one (a simple seed-packet chooser). Light agency, cozy, cheap. *(If this proves fiddly, fall back to an auto fast→slow order.)*
- **Morning glory** may key its open/closed petal state to the real time of day (dawn-open / afternoon-close) — a small, optional flourish, not required for v1.

---

## 5. Art

### 5.1 Pipeline & the guardrail

- **All art is hand-authored static vector art**, authored in-code by Claude as SwiftUI `Path`/`Shape`. No one draws by hand; no AI raster pipeline (Higgsfield was evaluated — free-plan account has ~0 credits and 30 consistent frames is costly/drift-prone). Vector-by-Claude is free, perfectly consistent, resolution-independent, theme-aware, animatable, and tiny.
- **Hard line:** "authored, not generated" refers to **runtime**. Assets are fixed and pre-made. There is **no procedural plant-drawing engine** in the app. (Using tooling at *design time* to help author assets would be fine; we simply don't need it.)
- **Detail ramps to the bloom.** Sprout/leaf stages are refined but restrained; **bud and bloom are lavish hero art** — the screenshot moment. The agreed detail bar is the detailed marigold sample from the session (dense tonal petals, ruffled tips, species foliage, pot on a sill).

### 5.2 Asset list (~30 drawings)

- **6 species × 5 stages** (seed, sprout, leaves, bud, bloom). Every stage is unique per species (no two species share an identical sprout/leaf).
- **Exception:** the literal **seed-in-soil** stage is a near-shared simple frame (soil mound) with only a subtle species tint — a buried seed genuinely looks alike, and this is cheap. Sprout onward is fully distinct.
- **Droop/overwater is NOT drawn per stage.** It is **one reusable effect** — a slight sag transform + a yellow/desaturate tint — layered over whatever stage is showing. One effect, applies everywhere.
- Gentle SwiftUI animation is in scope and cheap: a bloom-open transition, a soft idle sway, the glow.

---

## 6. Screens

- **Windowsill (home):** the current plant in its pot on a sill, the water-drop gauge, the "watered today ✓", the streak count, the water action, the share button. Designed chrome-light so it is screenshot-ready as-is.
- **Shelf (collection):** the pressed blooms, filling as species complete. Reached by a swipe. Shows a quiet **"garden complete"** state at six; any species can be **replanted** to keep tending. No hard ending.
- **First-run guide:** a 3-beat coach — *water once a day · watch the drop · don't drown it.*

---

## 7. Sharing

- **One share button** on the windowsill. Uses SwiftUI `ImageRenderer` to compose a **clean framed portrait card** — the bloom, its name (EN + KO), and the streak/date, no UI chrome — and hands it to the iOS share sheet (Messages, Instagram, save to Photos). Crisp at any size because the source is vector.
- Sharing the whole shelf as a "my garden" image is a someday extension; v1 shares the current bloom.

---

## 8. Technical shape

- **Pure SwiftUI**, iOS 16+ (for `ImageRenderer`). No engine, no dependencies, no backend.
- **Two layers:**
  - **`SsakCore`** (pure Swift, unit-tested): `Species` data, `PlantState` (`Codable`), and a `GrowthEngine` that advances progress + moisture + streak given *elapsed time and watering events*. Time is injected (a `Clock`/`Date` provider) so logic is testable without the wall clock. Local persistence (one `Codable` JSON file in the app's documents directory).
  - **`Ssak`** (SwiftUI app): `WindowsillView`, `ShelfView`, `PlantView` (dispatches to per-species stage drawings), the drop-gauge, the share export, onboarding, and the per-species `FlowerArt` drawings.
- **Persistence fields** (single stored struct): `currentSpecies`, `progress`, `moisture`, `stage`, `lastWateredDay`, `streak`, `plantedAt`, `collectedSpecies`, `nursingState`.
- **Real clock:** on each open, `GrowthEngine` reconciles elapsed real time since `lastWateredDay` / last update, depleting moisture and accruing healthy growth.

---

## 9. Testing

- **`SsakCore` unit tests for `GrowthEngine`** — the one non-trivial logic path, tested with injected elapsed time (never the wall clock):
  - healthy time accrues progress at the species rate; a plant blooms after exactly `bloomDays` of healthy time.
  - dryness (moisture < 0.25) pauses growth; growth resumes on watering.
  - overwater stress pauses growth; a single day's overwater drains back without lasting harm.
  - streak increments on a watered day, resets on a missed day.
  - stage thresholds map progress → stage correctly.
  - sustained neglect triggers the wilt setback (one-stage regression, shelf untouched).
- Tests must **genuinely discriminate** — assert on `GrowthEngine` state transitions given controlled inputs, not on incidental behavior.

---

## 10. Out of scope for v1

Add later only if the game proves fun: local notifications/reminders (push), weather/season reactivity, sound, iCloud sync, more than six species, gestures fancier than a tap, the postcard/share-studio, sharing the shelf as an image, and any AI-raster art path.

---

## 11. Success criteria

- A player can plant the marigold, water it over about a week, watch it bloom through five visibly distinct stages, press it to the shelf, and choose a next seed — all offline, with state surviving app restarts.
- Neglect never destroys a plant; the shelf is never lost.
- The bloom exports as a clean, pretty, shareable image.
- The whole thing ships. That is the point.

---

## 12. Archive & rename (implementation step 0, done before any Ssak code)

Executed carefully, preserving all Meok work, and confirmed with the user before running:

1. **Preserve Meok:** commit the pending `Localizable.xcstrings` change (or stash), tag `HEAD` as `meok-archive`, and **push** the 3 unpushed commits + the tag to `origin` so the old game is safe on GitHub forever.
2. **Rename the GitHub repo** `mhju0/meok` → `mhju0/ssak` (`gh repo rename`; GitHub auto-redirects old URLs). Update the local `origin` remote URL.
3. **Rename the local folder** `~/Workspace/Projects/meok` → `~/Workspace/Projects/ssak`.
4. **Fresh Xcode project `Ssak`** replacing the Meok project structure. Old code remains recoverable via the `meok-archive` tag and git history; it is not carried forward.
5. Update `CLAUDE.md`, licensing handle context, and auto-memory to reflect the new project.

---

## Appendix A — Decision ledger (grilling session, 2026-07-19)

| # | Decision | Choice |
|---|---|---|
| D1 | Platform | iOS / Swift (SwiftUI), local-only |
| D2 | Vibe | Cozy & calm; you tend one living thing |
| D3 | Concept | One plant, seed → bloom, collect 6 species |
| D4 | Fail state | Forgiving realism (b): stalls & droops, recovers; wilt only from sustained neglect; never permadeath; shelf never lost |
| D5 | Art scope | Path A: Claude hand-authors ~30 static vector drawings, **with more detail** than first pass; detail ramps to a lavish bloom |
| D6 | Art tool | No AI raster (Higgsfield ~0 credits, drift risk). Vector-by-Claude, free |
| D7 | Growth model | Time-based, gated by care |
| D8 | Pacing | Cozy (~1 real day = 1 plant-week); starter tuned fastest |
| D9 | Watering feedback | Diegetic + one quiet drop-gauge + "watered today ✓" + overwater nudge |
| D10 | The six | Marigold (starter) · Nasturtium · Cosmos · Zinnia · Sunflower · Morning glory |
| D11 | Sharing | One share button → framed export → iOS share sheet |
| D12 | Streak | Global, +1/day healthy, resets on miss, no penalty, soft glow ≥ ~3 |
| D13 | Completion | Quiet "garden complete"; replant freely; no hard end |
| D14 | Name | Ssak (싹); rename repo + folder from meok |
