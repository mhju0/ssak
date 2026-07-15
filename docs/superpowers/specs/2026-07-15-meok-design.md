# Meok (먹) — Design Spec

**Date:** 2026-07-15
**Status:** Approved by Michael Ju (brainstorming session, section-by-section)
**Working title:** Meok (먹, "ink stick"). Alternates if the App Store name is taken: Sumuk (수묵), Mukhyang (묵향), Inkscroll. Name availability check happens at M7.

---

## 1. Concept

Meok is a cozy skilling RPG for iOS, painted entirely in monochrome Korean ink-wash (수묵화). The player is the keeper of an abandoned mountain hermitage on an endless paper scroll. The world runs on the player's **real clock, real weather, and real season**: rain where the player lives bleeds the ink; real night deepens the world to charcoal; the first real snowfall of winter is an in-game event. The player slowly masters quiet crafts — fishing, foraging, gardening, cooking, crafting, artistry — and fills a personal gallery with specimens and paintings they made in-game.

- No combat. No servers. No accounts. No ads. 100% Swift.
- Genre reference points: RuneScape (skill progression), Animal Crossing (real-clock cozy life), Alto's Odyssey (ambient side-view beauty).
- Ships on the App Store (v1 milestone M7). Free, no IAP at v1.

### Pillars (every feature decision filters through these)

1. **The sky is real.** World state derives from real weather/time/season via WeatherKit + location. Never faked.
2. **Slow numbers, warm ritual.** Sessions of 5–20 minutes; a skill reaches 99 in roughly a month of daily play. Collection completion is the long tail. Nothing decays; absence is never punished.
3. **Ink is the engine.** All rendering is procedural brush-and-ink shaders on paper. Strictly monochrome. If it can't be drawn in ink, it doesn't ship.
4. **Alone, peacefully.** Fully offline-capable, solo. Aliveness comes from the world and a tiny cast of condition-bound visitors, not other players.
5. **Ship it.** v1 scope is cut ruthlessly; the scroll grows after launch.

---

## 2. Core Loop & Systems

### Session loop (5–20 min)

Open app → scroll reflects right now (weather, light, season) → check today's conditions (what's biting, what's in bloom, who might visit) → fish / forage / garden / paint / cook / craft / restore → haul feeds crafting and the gallery → XP ticks → leave anytime.

### Skills — six at v1

Each skill is a 1–99 XP curve tuned so daily play reaches 99 in ~1 month. All six share one engine: condition-gated activities + XP curve + unlock table.

| Skill | Verb | Feeds |
|---|---|---|
| Fishing 낚시 | cast, haptic bite, reel | Gallery specimens, cooking, visitor trades |
| Foraging 채집 | wander the scroll, find herbs/mushrooms/persimmons | Cooking, ink materials, restoration |
| Gardening 원예 | plant beds and trees; crops grow in real days; real rain waters them (rainy day = no watering chore); seasons gate crops | Cooking, materials. Planted trees persist forever — the scroll becomes a forest the player grew |
| Cooking 요리 | recipes from catch + harvest; seasonal dishes (김장 in real winter); meals give gentle buffs (e.g., better bite rates) | Buffs, visitor requests |
| Crafting 공예 | rods, baskets, furniture, brushes; brush quality affects Artistry; restoration consumes crafted goods | Tool tiers gate deeper content |
| Artistry 서화 | sit at any spot and paint the actual current scene; the painting captures the live WorldConditions | The Gallery — the signature skill |

**Sweeping (ritual, not a skill at v1):** leaves accumulate on paths from real wind/season; snow drifts in real snowfall. Finger-swipe sweeps them — haptic rustle, ink leaves scatter. No XP bookkeeping. Graduates to a full "Keeping" skill post-launch if loved.

### Condition gating — the content engine

Every species, material, and visitor has a condition key: **(season × time-of-day × weather)**. Rain-only fish, night mushrooms, a fish that bites only during real snowfall. Rarity derives from reality's rarity. Content lives in bundled data tables; adding a species is a data row, not code.

### The hermitage

Ruined at start; restored room by room with materials + Crafting. Four rooms at v1, each unlocking function: kitchen → cooking; studio → larger paintings; gallery wing → display space; (fourth room: tool shed → tool storage/upgrades).

### The Gallery

Collection endgame: fish specimens, pressed plants, and the player's own paintings, hung on restored walls. Completion = all species caught and all weather-variants painted; designed to take months.

### Visitors

3–5 at v1, each bound to a condition (old fisherman in morning rain; dokkaebi on storm nights). They trade, teach recipes, request paintings. Hand-authored dialogue, a few exchanges deep at most. No dialogue-tree sprawl.

### Deliberately absent

Combat, energy systems, wait-timers, ads, social feeds, other players.

### Post-launch skill roadmap (parking lot)

- Stargazing 천문 — night-only; chart real constellations and the real moon phase
- Papermaking 한지 — better canvases → greater Artistry works
- Tea 차 — grow, dry, brew; ceremony mini-ritual with buffs
- Wayfaring 지도 — expeditions extending the scroll into new biomes
- Keeping 관리 — cleaning/mending as a full skill; tidiness influences visitors

---

## 3. World Structure & Rendering

### The scroll

One continuous horizontal side-view scroll (두루마리), read like a classical 산수화 landscape. Five hand-composed zones at v1, each ~5 screens wide, with per-player procedural dressing (tree placement, rock shapes, seeded per save):

1. Mountain path — foraging, trailhead (Wayfaring extends here later)
2. Forest — foraging, night mushrooms, autumn leaf-sweeping
3. **Hermitage** (center) — restoration, cooking, crafting, gallery, visitor arrivals
4. Garden terrace — gardening beds and planted trees
5. Pond & river — fishing, best Artistry vistas

Drag to pan; tap to walk; activities open focused full-screen views (fishing view, painting view, kitchen).

### Parallax ink layers (back to front)

- L0 Paper: hanji fiber grain, vignette — always visible; fog fades the world back to this
- L1 Far mountains: lightest wash; biggest rain-bleed
- L2 Mid ridge & mist band: where fog lives
- L3 Playfield: ground, trees, buildings, character, visitors — crispest strokes
- L4 Foreground accents: grass, reeds, falling leaves/snow — real wind drives sway

### Weather → ink mapping

| Real condition | Ink behavior |
|---|---|
| Rain | Strokes bleed downward (directional blur + noise), intensity-scaled; puddles bloom as ink rings |
| Fog/mist | Layers dissolve toward paper (never gray) |
| Night | Denser charcoal redraw; **light is the absence of ink** — lanterns are bare-paper halos |
| Snow | White reserve accumulates (paper left unpainted on surfaces); flakes are paper-dots |
| Wind | Real m/s drives sway amplitude and leaf-particle rate |
| Time of day | Continuous ink-density curve mapped to real sun position |

**Signature moment:** entering an area, the world paints itself in — stroke-reveal animation with brush-on-paper sound and a soft haptic.

### Art direction rules (monochrome discipline)

- Strictly monochrome ink on warm paper. No hue, ever.
- Readability rule: interactables get the darkest ink + subtle motion; hierarchy by stroke weight, never color.
- All art is procedural/shader-driven where possible; hand-drawn silhouette assets kept minimal and reusable.

### Rendering tech

SpriteKit scene graph + custom Metal fragment shaders (SKShader), embedded in SwiftUI via SpriteView. No Unity/Godot — a cozy 2D scroller doesn't need them, and 100% Swift is the portfolio story. If SKShader hits limits, escalate to a custom Metal render pass, not an engine switch.

### Audio & haptics

- AVAudioEngine ambient layers mixed by weather state (rain stems scale with intensity; wind; birds by time of day).
- CoreHaptics patterns: fishing bite-twitch, sweep-rustle, brushstroke, paint-in reveal.

---

## 4. Architecture & Data

### Modules (dependency rule: everything points inward at the kernel)

```
App (SwiftUI shell, navigation)
 ├─ WorldRender   — SpriteKit scenes + Metal shaders (renders state, owns none)
 ├─ SkyState      — WeatherKit + CoreLocation + local astronomy
 │                   → emits WorldConditions(season, timeOfDay, weather, wind, moon)
 ├─ GameKernel    — pure Swift, zero UI/IO: skills & XP curves, condition engine,
 │                   inventory, growth timers. Deterministic & seedable
 └─ Persistence   — SwiftData models + CloudKit mirror
```

**Condition engine (heart of GameKernel):** pure function `(WorldConditions, skill levels, tools, seed) → available spawns/loot/visitors`. All content in bundled data tables keyed by season × time × weather.

### Data model (SwiftData, CloudKit-mirrored; no accounts)

- `SkillProgress` — xp per skill
- `InventoryItem`
- `SpeciesRecord` — caught/painted status per weather-variant
- `Painting` — WorldConditions snapshot + composition seed + rendered PNG (gallery display + share sheet)
- `HermitageRoom` — restoration state
- `GardenPlot` / `PlantedTree` — planted-at date; growth = real elapsed days
- `VisitorLog` — encounters, trades, requests

### Weather pipeline

- WeatherKit + coarse CoreLocation. Fetch on foreground + every ~30 min while active. Free tier (500k calls/month) is ample at portfolio scale with aggressive caching.
- Sun/moon computed locally (no network): real sunrise/sunset gradients, real moon phase.
- Location denied → manual city picker (default Seoul). Offline → last cached conditions persist.
- **Never-blank rule:** the game never shows an error where a sky should be.

### Time integrity

Gentle. Clock manipulation is not punished (Animal Crossing precedent: time-travelers are still fans).

### Sync & conflicts

SwiftData + CloudKit default merge, with one guard: **XP is monotonic — take the max per skill on conflict.** Progress is never lost.

### Notifications

Opt-in local notifications via BGAppRefresh condition checks, a few times daily. Only genuinely rare events ("First snow is falling on your scroll," typhoon visitor). Never streak nags. No server push.

### Localization

English + Korean from day one. All strings externalized from the first commit.

---

## 5. v1 Scope, Milestones, Risks

### v1 ships with

5 zones · 6 skills · hermitage restoration (4 rooms) · Gallery · 3–5 visitors · swipe-sweeping · full real-weather/time/season engine · ~50 collectible species/recipes across weather-variants · rare-event local notifications · iCloud sync · EN + KO localization.

### Out (parking lot)

Post-launch skills (Stargazing, Papermaking, Tea, Wayfaring, Keeping) · home-screen widget (hermitage under live weather — v1.5 headline) · Apple Watch · iPad-optimized layout.

### Monetization

v1 is free — no ads, no IAP. A portfolio game's job is to be played. Pricing is a v2 conversation only if it finds an audience.

### Milestones (each independently demoable; commit at every verified checkpoint)

- **M0 — "Living paper" spike:** hanji texture + one mountain wash layer + real rain bleeding the ink. Proves or kills the wow in ~2–3 weeks before anything is built on top. **Explicit kill criterion: if the ink doesn't look beautiful after the spike, revisit art direction before proceeding.**
- **M1 —** scroll walkable: 5 zones, parallax, real day/night
- **M2 —** condition engine + Fishing end-to-end (cast → haptic bite → catch → XP → species record) — the template for all skills
- **M3 —** Foraging + Gardening (real-day growth) + sweeping
- **M4 —** Cooking + Crafting + restoration
- **M5 —** Artistry + Gallery
- **M6 —** Visitors, notifications, polish, localization → TestFlight
- **M7 —** App Store submission (name check, screenshots, privacy labels, WeatherKit attribution)

### Risks (ranked)

1. **The ink shader is the whole bet** → M0 exists to fail fast and cheap.
2. **Swift depth is new** → kernel-first development: pure-Swift testable logic while platform skills grow.
3. **Monochrome readability** → stroke-weight hierarchy rule + interactable motion; enforced from M1.
4. **WeatherKit limits/cost** → caching; free tier ample.
5. **Scope creep** → pillars + parking lot; new ideas go to the lot, not the milestone.

### Testing strategy

- **GameKernel:** thorough unit tests — XP curves, condition tables, growth math; deterministic via seed.
- **SkyState:** contract tests against recorded WeatherKit fixtures.
- **Shaders/scenes:** screenshot harness for manual eyeball review (golden-image shader tests are brittle; honest review beats flaky CI).
- **UI:** happy-path smoke tests only.
- Regression tests must genuinely discriminate (fail on unfixed code) per repo convention.

---

## 6. Platform & Tooling Summary

- iOS 17+ (SwiftData requirement), iPhone-first, portrait-primary
- Swift 5.10+, SwiftUI + SpriteKit + Metal (SKShader), SwiftData + CloudKit, WeatherKit, CoreLocation, CoreHaptics, AVAudioEngine, BackgroundTasks, WidgetKit (v1.5)
- No third-party dependencies at v1
- Repo: `~/Workspace/Projects/meok`, MIT license, no backend
