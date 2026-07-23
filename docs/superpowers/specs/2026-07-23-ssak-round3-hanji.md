# Ssak UI redesign round 3 — 압화집 (the hanji album), 2026-07-23

The windowsill becomes a page of the pressed-flower album the game ends in. Direction
picked by Michael from a 4-way mock exploration, then from 5 in-family variants:
**B4 "album at dusk"** — approved mockup at `docs/design/round3/ssak-round3-b4-dusk-mockup.html`
(rendered: `ssak-round3-b4-dusk.png`).

Visual/UI layer only. **No gameplay, engine, persistence, or species-art changes** —
SsakCore and the flower drawings are untouched, same rule as rounds 1–2.

## The thesis

Hanji paper, ink, and one red dojang seal. The paper itself follows the real clock
(`TimeBand`): bright cream by day, rosy at dawn, warm lamplit tan at dusk, deep
warm-dark at night with the ink flipped light. The living room scene retires from the
windowsill; the album page replaces it.

## Decisions

- **D1 — KO-first type.** 메리골드 is the display line (Nanum Myeongjo), MARIGOLD the
  tracked small-caps subordinate. Short UI strings on Windowsill/Shelf go Korean per the
  mock (창가 / 압화집 / 흙이 촉촉해요 / 오늘 물 줌 ✓ / 제 N 호 / 함께한 지 N일 / 연속).
  StartGuide content stays English this round (one-time screen; restyle is a non-goal).
  VoiceOver labels stay English this round — flagged as follow-up, not silently mixed.
- **D2 — Paper follows TimeBand, not system dark mode.** The album is a physical object;
  its tone is time-of-day. Night flips chrome to light ink via the existing
  `chromeScheme`/`inkText()` mechanism (RoomScene's night rule, reused verbatim).
  System dark mode alone does not change the paper.
- **D3 — The seal is the streak.** A red dojang square (rotated ~4°, double border)
  holding the count over 연속. Muted (0.55 opacity, gray-red) when the streak is dead.
  Replaces `StreakBadge`.
- **D4 — Ink hairline gauge replaces the drop gauge.** A 3pt track filled to
  `moistureFraction`; moss green when moist, amber when dry, murky slate when over-full
  (same `SoilState` → color contract as today). Left word = soil state, right = 오늘 물
  줌 ✓ when watered (hidden while over-full, per the round-2 mixed-signals fix).
  Replaces `MoistChip`/`DropGauge`/`WateredTodayTick` on this screen.
- **D5 — Ink-outline water button, bottom center.** 56pt circle, 1.5pt ink stroke,
  drop glyph. Replaces the blue glass `WaterButton`. Keeps `guideTarget("water")`,
  the pour dip, and tap-the-plant watering.
- **D6 — Text-tab nav.** 창가 / 압화집 as ink text, active tab underlined seal-red.
  Replaces the glass `TopNavPill`. Keeps `guideTarget("shelf")` and ≥44pt targets.
- **D7 — Band clock, top-left.** 아침/낮/저녁/밤 · h:mm — names why the paper changed.
  Driven by the same minute-tick `now` RootView already injects.
- **D8 — Specimen label.** 제 N 호 (N = collected count + 1) · 압화 예정, over
  함께한 지 N일 (`currentDay`). Replaces nothing — it's the album framing.
- **D9 — Share stays, quiet.** Small ink share glyph, bottom-right corner. Prominent
  (seal-red tint) at bloom. BloomCard restyles to a hanji specimen card (KO-first + seal).
- **D10 — Font: bundled Nanum Myeongjo (SIL OFL)** Regular + ExtraBold as SsakApp
  package resources, registered via CoreText at startup (no Info.plist dependency, works
  on the macOS render path too). OFL.txt ships next to the fonts. Fallback if
  registration fails: system serif (EN) / SD Gothic semibold (KO) — layout must not break.
- **D11 — Shelf joins the paper world.** Paper ground, hairline-bordered paper cards
  (glass retired here), 압화집 header, KO copy; press-here state goes seal-red dashed.
  Logic (press/replant/next-uncollected) unchanged.
- **D12 — Retire dead glass.** After the swap, delete components with no remaining
  consumer (`TopNavPill`, `WaterButton`, `GlassIconButton`, `StreakBadge`, `MoistChip`,
  `DropGauge`, `WateredTodayTick`) and their harness renders. `SsakGlass` survives only
  if something still uses it. RoomScene/SkyBackdrop stay in SsakArt (art library +
  harness references); the app just stops using RoomScene.

## Screen specs (from the approved mock)

**Windowsill** — top row: band clock left, nav right. Second row: specimen label left,
seal right. Plant center (art unchanged, wall:false board:false), soft elliptical ground
shadow. Name block: 메리골드 42pt-slot ExtraBold myungjo + MARIGOLD 12pt tracked
small-caps. Gauge row. Water button bottom center; share glyph bottom-right. Overwater
nudge keeps its logic, restyled to ink amber.

**Shelf** — 압화집 헤더 + KO count line; 2×3 paper cards, 3:4, hairline border; empty =
faint mono 싹; press-ready = dashed seal-red border + 지금 눌러 두기 caption.

**BloomCard** — hanji ground, plant, 메리골드 / MARIGOLD, day·streak line, small seal.

## Paper palette (per band; approved mock is the dusk row)

| band | paper top → bottom | accent |
|---|---|---|
| dawn | #F2E4D4 → #E8D4BC | rosy wash, faint |
| day | #F5EEDE → #EBE0C8 | none (the mock's original) |
| dusk | #E4D2AC → #C7AF82 | warm lamp radial top-right, vignette |
| night | #2E2820 → #1E1913 | ink flips light (existing dark-ink values) |

Fiber flecks (4–6 radial-gradient dots) on all bands, fainter at night.

## Non-goals (this round)

StartGuide restyle · KO VoiceOver localization · README hero re-shoot (waits until the
look is device-approved) · app icon changes · any engine/persistence work.

## Verification

Per-task: `swift test` all packages + harness re-render + visual inspection. Final:
tracked reference set re-approved (day/dusk/night windowsill), iOS Simulator build,
tests green (39 + 4 + 10), StartGuide overlays correctly on the paper windowsill.
