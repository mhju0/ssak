# Ssak — domain glossary

Single-context repo. This is the shared vocabulary for the game's domain; use these
terms (not synonyms) in issues, tests, refactor proposals, and code. Decisions that
constrain the domain live in `docs/adr/`. Seeded lazily — extend it as concepts get named.

## The plant

- **Plant** — the *one* flower currently being raised, seed → bloom. One at a time; there is
  no garden of many. State: `PlantState` (SsakCore).
- **Species** — one of six flowers: **marigold** (starter), nasturtium, cosmos, zinnia,
  sunflower, morning glory. Catalog: `SpeciesCatalog`.
- **Growth stage** — `seed → sprout → leaves → bud → bloom` (`GrowthStage`), read from
  `progress` by fixed thresholds.
- **Progress** — 0…1 accrual toward bloom. Advances *only while the plant is healthy*, on the
  species' compressed real-time schedule (`GrowthEngine.reconcile`, gated by care).

## Care & water

- **Moisture** — the soil's water level (`0…moistureMax`). Drains a little each real day;
  watering adds `waterAmount`.
- **Soil state** — the plant's *care category*: **dry**, **moist** (healthy), or **over-full**.
  Classified from `moisture` against the tuning thresholds by `SoilState` (SsakCore). This is
  the single home for a category the UI reads out three ways — the drop-gauge colour, the
  status label, and the VoiceOver phrase. Growth pauses when the soil is dry or over-full, so
  `SoilState`'s boundaries are the same ones `GrowthEngine` uses to gate growth.
- **Dry threshold / too-wet threshold** — the `GrowthTuning` boundaries that bracket the
  healthy (**moist**) band. Growth pauses below `dryThreshold` and above `tooWetThreshold`.
- **Tuning** — `GrowthTuning`, the calibration knob for all growth math (drain rate,
  thresholds, water amount, wilt timing). The one place to tune feel.

## Forgiving realism (never punishing)

- **Streak** — consecutive-day watering count. **Alive** unless a full calendar day passes
  with no watering (derived at the UI from `lastWateredAt`, spec §3.2 — not reset in the engine).
- **Nursing** — the recovery flag set after a wilt setback; cleared the next time you water.
  Signals "this plant needs gentle attention," never a penalty.
- **Wilt setback** — after prolonged dry neglect the plant regresses *one* stage (never below
  seed). No permadeath; the shelf is never lost.

## Collecting

- **Bloom & press** — a bloomed plant is **pressed** to the shelf and replaced by the next
  species (`pressAndReplant`).
- **Shelf** — the six-slot collection of pressed blooms. Filling all six completes the garden.

## Screens

- **Windowsill** — the home screen: the current plant growing on a real-time sky.
- **Shelf** — the collection screen (above).
- **Bloom card** — the clean framed portrait shared from the windowsill.
