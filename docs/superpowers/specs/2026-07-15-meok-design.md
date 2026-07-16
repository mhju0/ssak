# Meok (먹) — Design Spec

**Date:** 2026-07-15 (amended 2026-07-16: grilling decisions D1–D10 + four-lens self-review fixes — see Appendix A)
**Status:** Approved by Michael Ju (brainstorming session, section-by-section; grilling D1–D10 folded in; self-review fixes pending user read)
**Working title:** Meok (먹, "ink stick"). Alternates if the App Store name is taken: Sumuk (수묵), Mukhyang (묵향), Inkscroll. Name availability check happens at M8.

---

## 1. Concept

Meok is a cozy skilling RPG for iOS, painted in monochrome Korean ink-wash (수묵화) by a procedural brush-stroke engine — no drawn assets exist; the game draws itself, live. The player is the keeper of an abandoned mountain hermitage on a vertical hanging scroll (족자). The world runs on the player's **real clock, real weather, and real season**: rain where the player lives bleeds the ink; real night deepens the world to charcoal; the first real snowfall of winter is an in-game event. The player slowly masters quiet crafts — fishing, foraging, gardening, cooking, crafting, artistry — and fills a personal gallery with specimens and paintings they made in-game.

- No combat. No servers. No accounts. No ads. 100% Swift.
- Genre reference points: RuneScape (skill progression), Animal Crossing (real-clock cozy life), classical 산수화 hanging scrolls (composition and identity).
- Ships on the App Store (v1 milestone M8). Free, no IAP at v1.

### Pillars (every feature decision filters through these)

1. **The sky is real.** World state derives from real weather/time/season. Never faked.
2. **Slow numbers, warm ritual.** Sessions of 5–20 minutes; full mastery of all six skills takes roughly a year at the reference pace (15 min/day). Nothing decays; absence is never punished.
3. **Ink is the engine.** All rendering — world *and* every asset — is procedural brush-stroke and shader work on paper. Strictly monochrome, with exactly one exception: the earned red seal (낙관). If it can't be drawn in ink, it doesn't ship.
4. **Alone, peacefully.** Fully offline-capable, solo. Aliveness comes from the world and a tiny cast of condition-bound visitors, not other players.
5. **Ship it.** v1 scope is cut ruthlessly; the scroll grows after launch.

---

## 2. Core Loop & Systems

### First run (scripted, ~3 minutes, identical structure at any real hour)

1. Blank hanji paper. The scroll **paints itself in**, peak downward — the signature reveal is the first thing every player sees.
2. Arrival at the ruined hermitage; three guided beats taught by doing, no text walls: **sweep the porch** (swipe + haptics) → **light the lantern** (light-as-absence-of-ink; guarantees legibility on night first-runs) → **catch one fish** at the pond spur (cast/bite/reel, the haptic wow).
3. Control handed over. One ink-brushed line suggests the first goal: *"the kitchen roof has a hole."*

**Permission choreography (v1 requirement, not an afterthought):**

- The very first reveal renders on the **cold-start default sky** (see §4) so no iOS dialog interrupts the cinematic.
- Immediately after the reveal, a diegetic pre-prompt — *"the scroll wants to know your sky"* — leads into the iOS location dialog. Granted → the world upgrades to live conditions on the spot (its own small moment). Denied → manual city picker.
- The notification permission ask is deferred until the game first has something rare to tease (e.g., the first observed weather change), never during onboarding.

Every first-run shares the structure; the real sky makes each one different. Two players comparing first screenshots see different games.

### Session loop (5–20 min)

Open app → scroll reflects right now (weather, light, season) → check today's conditions (what's biting, what's in bloom, who might visit) → fish / forage / garden / paint / cook / craft / restore / sweep → haul feeds crafting and the gallery → XP ticks → leave anytime.

### Skills — six at v1

All six share one engine: condition-gated activities + XP curve + unlock table.

| Skill | Verb | Feeds |
|---|---|---|
| Fishing 낚시 | cast, read the haptic bite, reel | Gallery specimens, cooking, visitor trades |
| Foraging 채집 | wander the scroll, find herbs/mushrooms/persimmons | Cooking, ink materials, restoration |
| Gardening 원예 | plant beds and trees; growth = real elapsed days, always (see mechanics below) | Cooking, materials. Planted trees persist forever — the scroll becomes a forest the player grew |
| Cooking 요리 | recipes from catch + harvest; seasonal dishes (김장 in real winter); meals give gentle buffs (e.g., better bite rates) | Buffs, visitor requests |
| Crafting 공예 | rods, baskets, furniture, brushes; brush quality affects Artistry; restoration consumes crafted goods | Tool tiers gate deeper content |
| Artistry 서화 | paint the actual current scene (mechanic below) | The Gallery — the signature skill |

**Gardening mechanics (pinned):** growth is a pure function of real elapsed days — crops never pause, wither, or regress (pillar 2). Watering is a **bonus ritual, never a chore**: real rain waters automatically, or the player waters by hand on dry days; either grants a small Gardening XP tick and a cosmetic dew/bloom flourish. An unwatered garden grows exactly as fast — watering adds delight, not obligation.

**Sweeping (ritual, not a skill at v1):** leaves accumulate on paths from real wind/season; snow drifts in real snowfall. Finger-swipe sweeps them — haptic rustle, ink leaves scatter. Swept state persists across sessions; only new real wind/leaf-fall/snowfall re-litters a path — sweeping is never undone by mere time passing. No XP bookkeeping. Graduates to a full "Keeping" skill post-launch if loved.

### Fishing mechanics (M2 template skill)

- **Haptic signatures:** the bite is not a binary buzz. Species have haptic patterns (nibble-nibble-strike; slow heavy pull) the player learns to read through their palm before committing the hook. The phone is the rod; mastery is haptic literacy.
- **Accessibility mirror (built with the system, not retrofitted):** every haptic signature has a synchronized **visual cue** (the bobber's stroke trembles in the same pattern) and an audio cue — for players who disable haptics, play on a table, or can't perceive the patterns.
- **Gentle fight:** rare fish add a ~10-second tension dance — hold to reel, ease off when the line "sings" (sharp haptic). No hard failure: a lost fish slips away; no bait loss, no penalty. Failure costs only the moment.
- **Shadow entries:** a lost fish logs a silhouette "one that got away" flag on its `SpeciesRecord` — visible in the species ledger from M2, displayed as a gallery silhouette from M5. Failure becomes collection intel.

### Artistry mechanics

- Player chooses composition (frame + focal subject), then performs a handful of **guided brushstrokes** — finger following ghost paths; speed and steadiness subtly affect stroke character — and the stroke engine completes the painting. Authorship without the ability to ruin it.
- The live WorldConditions are baked into the painting: the same pond in rain, snow, and fog yields genuinely different collectible works.
- Brush quality (Crafting) unlocks stroke vocabulary; the studio room unlocks larger canvases.
- **The red seal (낙관), unlocked at Artistry 90:** the player earns their seal (chooses their mark) as the steep tail begins; stamping a finished painting places the game's only color. Levels 90–99 are the "sealed era" — mastery works signed in red. This is the sanctioned exception to pillar 3.

### Pacing model

- **Reference player: 15 minutes/day.** All curves tune to this.
- **Budget: ~90 active hours to master all six skills** (~15 h per 99), leveled in parallel (a session naturally touches 2–3 skills). At reference pace: first 99 ≈ month 3–4; full mastery ≈ month 12. At hardcore pace (2 h/day): full mastery ≈ 45 days — still over a month.
- **Curve shape:** cost-per-level grows the whole way (level 2 in minutes); **steep tail** — levels 90→99 cost ~40% of a skill's total time; 98→99 alone ≈ 1.5 h (a focused week at reference pace). Each 99 is a genuine event.
- **Levels unlock, never gate fun:** a touchable unlock (species tier, stroke type, recipe, tool) at least every ~10 levels per skill; **full unlock tables for all six skills are drafted on paper before M2 builds the unlock engine** — if the content counts can't support the cadence, the cadence or the content list is adjusted then, not mid-implementation. Level 1 fishing is already complete fishing.
- **Weekly "something new" beat:** between level unlocks, the other clocks (hermitage rooms, visitor arcs, seasonal firsts) must deliver a fresh beat at least weekly at reference pace.
- **The two-currency rule: hours gate levels; the sky gates collection — never cross them.** No XP requirement may demand specific weather, **and** the content tables must satisfy a coverage invariant: every (season × time-of-day × weather) combination yields at least one XP-earning activity per gathering skill (an all-conditions baseline tier). Any day, any sky, grinding always progresses; only collection waits on reality. Both halves are kernel-tested.
- Gallery completion (all species, all weather-variants painted) stretches beyond the year — the true endgame.

### Condition gating — the content engine

Every species, material, and visitor has a condition key: **(season × time-of-day × weather)**. Rain-only fish, night mushrooms, a fish that bites only during real snowfall. Rarity derives from reality's rarity. Content lives in bundled data tables; adding a species is a data row — including its art, which is a stroke-recipe parameter set (see §3).

**"Weather-variant," defined precisely:** a species' variant key is the **weather dimension only** (clear / rain / snow / fog / …) — season and time-of-day never create variants. A species' variant set = the weather values its condition key allows. `SpeciesRecord` tracks caught/painted per that set; completion math and gallery UI use the same definition.

### Climate honesty (collection fairness)

- **Climate capability is computed, not guessed:** a bundled static climate table (Köppen-derived, keyed from coarse coordinates or the picked city) determines which weather values the player's location can produce. Recomputed on location change; species already collected never leave the completion denominator. Implemented at M2 alongside the condition engine.
- **Per-climate 100%:** gallery completion is defined against what the player's sky can produce; climate-locked species carry an honest label — *"not native to your sky"* — and don't count against their completion.
- **Visitors as the pressure valve:** traveling visitors periodically offer species the player's climate can't produce (target cadence: roughly one climate-locked offer per real month), so completionists everywhere have a slow path to the full ledger. Weather events themselves stay location-honest.

### The hermitage

Ruined at start; restored room by room with materials + Crafting. Four rooms at v1, each unlocking function: kitchen → cooking; studio → larger paintings; gallery wing → display space; tool shed → tool storage/upgrades.

### The Gallery

Collection endgame: fish specimens, pressed plants, shadow "got away" silhouettes, and the player's own paintings, hung on restored walls. A minimal **species ledger** (list view over `SpeciesRecord`) ships early at M2; the full gallery experience (walls, paintings, completion views) lands at M5. Designed to take months; variants wait on real weather diversity.

### Visitors — three at v1

| Visitor | Condition | Role |
|---|---|---|
| The old fisherman | morning rain | Teaches recipes; trades rain species; fishing lore |
| The dokkaebi | storm nights | Mischief trades — odd goods for odd prices; storm-only species |
| The traveling peddler | seasonal arrivals | **The climate-trade valve:** carries species not native to the player's sky; requests dishes and paintings in exchange |

Trades are barter against visitor requests (dishes, paintings, materials — no currency). Hand-authored dialogue, a few exchanges deep at most, authored in EN + KO. Roster grows post-launch.

### Deliberately absent

Combat, energy systems, wait-timers, ads, social feeds, other players.

### Post-launch roadmap (parking lot)

- Skills: Stargazing 천문 (real constellations, real moon phase) · Papermaking 한지 · Tea 차 · Wayfaring 지도 (extends the scroll) · Keeping 관리
- **iCloud sync (v1.1):** deferred out of v1 — see §4
- Procedural rain-synth audio; keeper outfit variations; home-screen widget (v1.5 headline); more visitors

---

## 3. World Structure & Rendering

### The scroll (vertical)

One continuous **vertical hanging scroll (족자)** — the world descends a mountain, thumb-scrolled downward like the most natural phone gesture there is. Five hand-composed zones at v1, stacked by altitude, each with per-player procedural dressing (tree placement, rock shapes, seeded per save):

1. **Peak / mountain path** (top) — foraging, trailhead (Wayfaring extends upward later)
2. **Forest** — foraging, night mushrooms, autumn leaf-sweeping
3. **Hermitage** (mid-slope, home) — restoration, cooking, crafting, gallery, visitor arrivals
4. **Garden terrace** — gardening beds and planted trees
5. **Valley pond** (bottom) — fishing, best Artistry vistas

Portrait-only. Drag to scroll the mountain; tap to walk the keeper; activities open focused full-screen views (fishing view, painting view, kitchen). Altitude is the zone logic: forage high, fish low.

### The keeper (player character)

A **staffage figure** in the classical 산수화 manner: five to ten brushstrokes — 갓 (hat) silhouette, robe, staff — deliberately tiny against the vast scroll. That scale relationship is the genre's signature composition. ~8 poses at v1 (walk-bob, seated fishing, sweeping, painting crouch, etc.); no face, no complex cycles. Outfit variations: parking lot.

### Parallax ink layers (back to front; layers scroll at different vertical rates)

- L0 Paper: hanji fiber grain, vignette — always visible; fog fades the world back to this
- L1 Far mountains: lightest wash; biggest rain-bleed
- L2 Mid ridge & mist band: where fog lives
- L3 Playfield: ground, trees, buildings, keeper, visitors — crispest strokes
- L4 Foreground accents: grass, reeds, falling leaves/snow — real wind drives sway

### Procedural assets — the stroke engine (D9, the central technical bet)

**No drawn or generated image assets exist.** A brush-stroke engine renders every asset from parameter data at runtime: strokes as splines with ink dynamics (pressure profile, dry-brush breakup, edge pooling, bleed). The engine is mandatory scope regardless — the paint-itself-in reveal and Artistry's shader-completed paintings both require strokes as ordered, timed path data.

- **Species = stroke recipes from ~12 archetypes** (carp-shape, eel-shape, crab-shape; cap-mushroom, bracket-fungus; …). Each species is a distinct recipe — never one template with slider variants. Sumi-e precedent: the Mustard Seed Garden Manual has taught fish, bamboo, and figures as codified stroke sequences for centuries.
- **Recipe authoring is budgeted, not implicit:** ~30 species at v1 (cut from 50 by self-review — the unlock cadence survives with spaced tiers). Authoring is distributed across M2–M5, and after the first ~10 recipes (by M3) the per-recipe time cost is measured; if it blows the budget, the species count cuts further or the commission fallback triggers *then*, not at the end.
- Visitors, keeper poses, hermitage states, tools, UI iconography: stroke templates in the same engine. Style unity is by construction.
- Weather-variants come free: the renderer inks wetter in rain, denser at night, reserves paper under snow — per-stroke operations impossible on baked sprites.
- AI-generated imagery may be used as *reference* while tuning parameters; never as shipped assets.
- **Fallback ladder (no single failure scratches the project):** if the Charm Gate (M0) fish lacks charm → commission ~15 hero assets **delivered as vector stroke/path data (ordered stroke recipes), not raster images** — so the engine's per-stroke weathering still applies and the ladder's promise holds → if the ink look itself fails → art direction pivots to flat silhouette style; all game systems survive unchanged.

### Weather → ink mapping

| Real condition | Ink behavior |
|---|---|
| Rain | Strokes bleed downward (directional blur + noise), intensity-scaled; puddles bloom as ink rings |
| Fog/mist | Layers dissolve toward paper (never gray) |
| Night | Denser charcoal redraw; **light is the absence of ink** — lanterns are bare-paper halos |
| Snow | White reserve accumulates (paper left unpainted on surfaces); flakes are paper-dots |
| Wind | Real m/s drives sway amplitude and leaf-particle rate |
| Time of day | Continuous ink-density curve mapped to real sun position |

**Signature moment:** entering an area, the world paints itself in — stroke-reveal animation with brush-on-paper sound and a soft haptic. (Honors Reduce Motion: reveals shorten to a gentle fade when the system setting is on.)

### Freshness — four independent change-clocks on one set of compositions (D7)

1. **Weather** (daily): the shader mapping above.
2. **Seasonal parameterization** (nearly free): foliage density collapses in autumn; snow reserve persists through winter; waterline drops in dry months; mist thickens in spring. Each zone composed once with four seasonal parameter states.
3. **Hand-authored seasonal set-pieces:** one per zone per season (~20 total) — persimmons ripen on the terrace tree; the pond edge freezes to bare-paper ice; a magpie nest appears at the peak in spring. Drip-fed "that's new" beats on the calendar's schedule.
4. **The player's permanence:** planted trees grow forever, restored rooms accumulate, and swept paths persist until real weather re-litters them. By month 6, a player's scroll visibly diverges from a new one.

### Art direction rules (monochrome discipline)

- Monochrome ink on warm paper. The single exception: the earned red seal on finished paintings.
- Readability rule: interactables get the darkest ink + subtle motion; hierarchy by stroke weight, never color.

### Accessibility (v1 requirements)

- Every haptic gameplay signal has a synchronized visual and audio mirror (fishing bite-cues above are the template).
- VoiceOver and Dynamic Type on all non-scene UI (menus, ledger/gallery, settings, dialogs).
- Reduce Motion honored for paint-in reveals and parallax.
- UI text meets contrast minimums even within the ink aesthetic (darkest-ink-on-paper for all reading surfaces).

### Rendering tech

SpriteKit scene graph + custom Metal fragment shaders (SKShader — GLSL-style language, directly adjacent to the developer's WebGL experience), embedded in SwiftUI via SpriteView. No Unity/Godot — a cozy 2D scroller doesn't need them, and 100% Swift is the portfolio story. If SKShader hits limits, escalate to a custom Metal render pass, not an engine switch.

### Audio & haptics

- AVAudioEngine ambient layers mixed by weather state (rain stems scale with intensity; wind; birds by time of day). v1 sources: curated CC0 stems (freesound.org), credited in Settings. Procedural synthesis: parking lot.
- CoreHaptics patterns: species bite-signatures, tension "singing line," sweep-rustle, brushstroke, paint-in reveal. Haptics require a physical device (Simulator does not play them); the developer's own iPhone is the test rig.

---

## 4. Architecture & Data

### Modules (dependency rule: everything points inward at the kernel)

```
App (SwiftUI shell, navigation, settings)
 ├─ WorldRender   — SpriteKit scenes + Metal shaders + the stroke engine
 │                   (renders state, owns none)
 ├─ SkyState      — weather provider + CoreLocation + local astronomy
 │                   → emits WorldConditions(season, timeOfDay, weather, wind, moon)
 │                   Provider is swappable: Open-Meteo (free, keyless, M0 onward) →
 │                   WeatherKit (at ~M7, after Developer Program enrollment)
 ├─ GameKernel    — pure Swift, zero UI/IO: skills & XP curves, condition engine,
 │                   climate-capability table, inventory, growth timers.
 │                   Deterministic & seedable
 └─ Persistence   — SwiftData models, local-only at v1 (iCloud sync: v1.1)
```

**Condition engine (heart of GameKernel):** pure function `(WorldConditions, skill levels, tools, seed) → available spawns/loot/visitors`. All content in bundled data tables keyed by season × time × weather; a species row carries both its gameplay data and its stroke-recipe parameters. The engine also owns the **climate-capability lookup** (bundled Köppen-derived table) that powers per-climate completion.

### Data model (SwiftData, local-only at v1; no accounts)

- `SkillProgress` — xp per skill
- `InventoryItem`
- `SpeciesRecord` — caught/painted status per weather-variant (weather dimension only); shadow "got away" flag
- `Painting` — WorldConditions snapshot + composition seed + rendered PNG (gallery display + share sheet) + seal state
- `HermitageRoom` — restoration state
- `GardenPlot` / `PlantedTree` — planted-at date; growth = real elapsed days (no watering state affects growth; watering grants XP/cosmetic only)
- `VisitorLog` — encounters, trades, requests

### Weather pipeline

- Coarse CoreLocation, while-in-use only. Fetch on foreground + every ~30 min while active.
- **Provider ladder:** Open-Meteo from M0 (free, keyless — same API used in the developer's seoulsky project); swap to WeatherKit behind the same `WorldConditions` interface at ~M7 with Developer Program enrollment.
- **Closed-app gap replay:** accumulation systems (leaf fall, snow drift, garden watering credit) depend on weather that happened while the app was closed. On foreground, fetch hourly conditions for the gap from the provider's history API (both Open-Meteo and WeatherKit support historical queries) and replay them through the accumulation systems. History unavailable → interpolate the last cached conditions forward. Provider parity here is a swap-acceptance criterion at M7.
- Sun/moon computed locally (no network): real sunrise/sunset gradients, real moon phase.
- Location denied → manual city picker (default Seoul). Offline → last cached conditions persist.
- **Cold-start default (first launch, no cache, no permission yet):** clear conditions + locally computed sun/moon for the default city; upgraded live the moment a real fetch succeeds. The first-run reveal renders on this default so no dialog interrupts it (§2).
- **Never-blank rule:** the game never shows an error where a sky should be.

### Time integrity

Gentle. Clock manipulation is not punished (Animal Crossing precedent: time-travelers are still fans).

### Persistence & sync

v1 is **local-only SwiftData** — an honest cut, not an accident: SwiftData's CloudKit mirroring exposes no custom merge hooks (system-managed last-writer-wins underneath), so the required "XP is monotonic" guarantee isn't implementable on the default path. iCloud sync ships in **v1.1** with a mergeable design (append-only XP events or per-device rows maxed at read time — decided in the v1.1 planning cycle). For a free, offline, no-accounts cozy game, local-first at launch is acceptable; the data model above avoids foreclosing the v1.1 design.

### Settings screen (v1 surface)

Home for: manual city picker · notification opt-in management · haptics/audio toggles · accessibility options · weather-data attribution (WeatherKit requires visible attribution; Open-Meteo requires CC BY credit) · CC0 audio credits · licenses. Grows incrementally: city picker at M1, toggles by M3, attribution/credits complete by M8.

### Notifications

Opt-in local notifications via BGAppRefresh condition checks, a few times daily. Only genuinely rare events ("First snow is falling on your scroll," typhoon visitor). Never streak nags. No server push.

### Localization

English + Korean from day one. All strings externalized from the first commit.

---

## 5. v1 Scope, Milestones, Risks

### v1 ships with

5 zones (vertical scroll) · 6 skills · scripted first-run with permission choreography · hermitage restoration (4 rooms) · species ledger (M2) growing into the full Gallery (M5) with shadow entries · 3 visitors incl. the climate-trade peddler · swipe-sweeping · full real-weather/time/season engine with gap replay · ~30 species/recipes from ~12 stroke archetypes · red-seal Artistry endgame (unlock: Artistry 90) · rare-event local notifications · settings screen · accessibility baseline (§3) · EN + KO localization. **Local-only saves (iCloud sync in v1.1).**

### Out (parking lot)

Post-launch skills (Stargazing, Papermaking, Tea, Wayfaring, Keeping) · iCloud sync (v1.1) · home-screen widget (v1.5 headline) · Apple Watch · iPad-optimized layout · procedural audio synthesis · keeper outfits · additional visitors.

### Monetization

v1 is free — no ads, no IAP. A portfolio game's job is to be played. Pricing is a v2 conversation only if it finds an audience.

### Cost profile

$0 until ~M7 (Open-Meteo, local saves, Simulator + personal device). At ~M7: Apple Developer Program $99/year (unlocks WeatherKit, TestFlight, App Store). Optional bounded fallback if the Charm Gate partially fails: ~$1–2k asset commission (vector stroke data). Privacy policy hosted free on GitHub Pages.

### Plan cadence (self-review, high-severity)

**One implementation-plan cycle per milestone. The first plan covers M0 only** — the Charm Gate verdict (proceed / commission / art pivot) materially changes everything downstream, so planning M1+ before it is planning work the verdict may invalidate.

### Milestones (each independently demoable; commit at every verified checkpoint)

- **M0 — the Charm Gate:** ordered sub-gates: paper + wash shader → live rain-bleed from real weather (Open-Meteo) → stroke-spline core (pressure, dry-brush, pooling, bleed) → one carp recipe → one staffage figure. **Pass = a stranger calls the carp and figure beautiful. The kill criterion is charm-at-completion, not the calendar** — 2–3 weeks is the target, but a slow M0 in a brand-new stack (Swift + SpriteKit + Metal) is expected, not a failure signal. Fail → fallback ladder (§3), not project death.
- **M1 —** vertical scroll walkable: 5 stacked zones, parallax, real day/night, the keeper walking; settings screen v0 (city picker)
- **M2 —** condition engine + climate-capability table + Fishing end-to-end (cast → haptic signature + visual/audio mirror → fight → catch → XP → `SpeciesRecord` incl. shadow flags) + minimal species ledger. **Unlock tables for all six skills drafted on paper before this milestone's engine work.** First ~10 stroke recipes authored here and at M3; per-recipe cost measured → species-count checkpoint.
- **M3 —** Foraging + Gardening (real-day growth, watering ritual) + sweeping; haptics/audio toggles in settings
- **M4 —** Cooking + Crafting + restoration
- **M5 —** Artistry (guided strokes, red seal at 90) + full Gallery (walls, paintings, per-climate completion views)
- **M6 —** Visitors (all three, incl. climate trades), EN+KO dialogue
- **M7 —** First-run script + permission choreography, notifications, polish pass, localization completion · **Developer Program enrollment: WeatherKit swap (gap-replay parity check), TestFlight**
- **M8 —** App Store submission: name check, **app icon** (designed in the stroke aesthetic, tested at 60 px on light/dark early), screenshots, privacy labels, **hosted privacy policy (GitHub Pages)**, weather attribution

### Risks (ranked)

1. **The stroke engine is the whole bet — charm, not just atmosphere** → M0 Charm Gate exists to fail fast and cheap; fallback ladder bounds every outcome.
2. **Swift depth is new** → kernel-first development: pure-Swift testable logic while platform skills grow; shader work lands in familiar GLSL-adjacent territory.
3. **Recipe-authoring volume** → ~30 species budgeted, authoring distributed M2–M5, cost checkpoint after first ~10 recipes with an explicit cut/commission trigger.
4. **Species samey-ness in monochrome** → archetype recipes (never slider clones) + shadow-entry intrigue; reviewed each milestone.
5. **Monochrome readability** → stroke-weight hierarchy rule + interactable motion + accessibility contrast floor; enforced from M1.
6. **Mid-game desert (months 2–8)** → weekly "something new" beat + four change-clocks + unlock cadence backed by drafted tables.
7. **Scope creep** → pillars + parking lot; new ideas go to the lot, not the milestone.

### Testing strategy

- **GameKernel:** thorough unit tests — XP curves (steep-tail totals vs. the 90-hour budget), condition tables, **both halves of the two-currency rule** (no weather in XP requirements; all-conditions coverage invariant), climate-capability lookups, growth math; deterministic via seed.
- **SkyState:** contract tests against recorded fixtures for both providers (Open-Meteo, WeatherKit), including gap-replay history queries.
- **Stroke engine/scenes:** screenshot harness for manual eyeball review (golden-image shader tests are brittle; honest review beats flaky CI).
- **UI:** happy-path smoke tests only.
- Regression tests must genuinely discriminate (fail on unfixed code) per repo convention.

---

## 6. Platform & Tooling Summary

- iOS 17+ (SwiftData requirement), iPhone-only at v1, **portrait-only**
- Swift 5.10+, SwiftUI + SpriteKit + Metal (SKShader), SwiftData (local-only at v1), Open-Meteo → WeatherKit (M7), CoreLocation (coarse, while-in-use), CoreHaptics, AVAudioEngine, BackgroundTasks, WidgetKit (v1.5)
- No third-party dependencies at v1
- Repo: `~/Workspace/Projects/meok`, MIT license, no backend

---

## Appendix A — Decision ledger

### Grilling session (2026-07-16), D1–D10

| # | Decision |
|---|---|
| D1 | Vertical hanging scroll (족자); zones stacked by altitude; portrait-only |
| D2 | Scripted 3-min first-run: paint-in reveal → sweep → lantern → first fish; diegetic |
| D3 | Climate honesty: per-climate 100% + "not native to your sky" labels + visitor trades |
| D4 | Haptic-signature fishing, gentle fights, no punishment, shadow "got away" entries |
| D5 | Guided-stroke Artistry; the earned red seal (낙관) is the game's only color |
| D6 | Pacing: 15 min/day reference; ~90 h/12 months full mastery; steep tail (90→99 ≈ 40%); two-currency rule; weekly beat |
| D7 | Three-layer freshness + weather = four change-clocks |
| D8 | Staffage keeper: 5–10 strokes, 갓 silhouette, ~8 poses |
| D9 | Fully procedural assets via stroke engine; M0 = Charm Gate; recipe archetypes; fallback ladder (commission heroes → silhouette pivot) |
| D10 | Defer Developer Program; Open-Meteo first; audio = CC0 stems; location = coarse, while-in-use |

### Self-review fixes (2026-07-16) — judgment calls flagged for user review

| Fix | Call made |
|---|---|
| iCloud sync | **Deferred to v1.1** (SwiftData+CloudKit can't honor monotonic-XP merge; local-only v1) |
| Species count | **50 → ~30** with per-recipe cost checkpoint at M3 |
| Red seal unlock | **Artistry 90** (start of the steep tail; 90–99 = "sealed era") |
| Developer Program timing | **~M3 → ~M7** (with sync deferred, nothing needs it before TestFlight; $0 phase extended) |
| Milestones | **Renumbered M0–M8**; M6 kitchen-sink split (visitors ≠ release prep); first-run script built at M7 when all three taught mechanics exist |
| Unlock cadence | every ~5 levels → **every ~10 levels**, tables drafted before M2 |
| Watering | Pure-elapsed-days growth; watering = bonus ritual (XP + cosmetic), never a chore/pause |
| Visitors | Pinned to **3** named archetypes (fisherman, dokkaebi, peddler) |
| New v1 items | Permission choreography, accessibility baseline, settings screen, gap replay, cold-start sky, app icon, privacy policy page |
