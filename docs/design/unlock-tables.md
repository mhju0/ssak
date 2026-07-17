# Unlock tables — all six skills

**Status:** drafted 2026-07-17 by the implementing agent under Michael's "do M2" go-ahead. The spec (§2 Pacing)
reserves this drafting as a paper step before M2's engine work; treat this document as that draft, submitted for
Michael's review (issue #20). Every number here is data — the kernel reads these tables, so edits after review are
cheap and safe. The engine work encodes the *shape* (curve invariants, cadence, coverage rule), not the values.

Spec anchors: §2 Pacing model (pinned invariants), §2 Condition gating, §2 Skills, Appendix A D-decisions.

---

## 1. XP curve (shared by all six skills)

**Reference rate: 100 XP/min** of focused activity (a baseline fishing catch cycle ≈ 40 s ≈ 60 XP).

Cost to advance from level ℓ to ℓ+1, in XP:

| Range | Formula | Shape |
|---|---|---|
| 1 ≤ ℓ ≤ 89 | `round(250 × 1.018^(ℓ−1))` | gentle exponential: 250 XP (≈2.5 min) at level 1 → ≈1,200 XP (≈12 min) at level 89 |
| 90 ≤ ℓ ≤ 98 | `round(1210 × 1.29^(ℓ−90))` | the steep tail — begins exactly where the seal era begins (Artistry 90) |

Pinned invariants (kernel-tested, spec §2):

- **Total 1→99 ≈ 91,000 XP ≈ 15.2 h** at reference rate (×6 skills ≈ 90 active hours to master all).
- **Level 1→2 costs 250 XP ≈ 2.5 min** — "level 2 in minutes."
- **Levels 90→99 cost ~40% of the skill's total** (≈37,000 XP ≈ 6.2 h).
- **98→99 alone ≈ 9,300 XP ≈ 1.55 h** — a focused week at reference pace.

The two regimes are continuous at the seam (cost(89) ≈ 1,201; cost(90) = 1,210): no visible kink until the tail
accelerates.

## 2. The two-currency rule (kernel-tested)

**Hours gate levels; the sky gates collection — never cross them.**

- No XP requirement may demand specific weather. Unlocks are level-only.
- **Coverage invariant:** every (season × time-of-day × weather) combination yields at least one XP-earning
  activity per gathering skill. For Fishing this is carried by two all-conditions species (crucian carp, common
  carp) available from level 1. The kernel test enumerates all 4×4×6 = 96 combinations against the species table.
- No double gates: a species gated by Fishing 90 is **not** also gated by a crafted tool; crafted rods adjust
  feel and bite weights, never access.

## 3. Content budget / cadence check (spec's adjust-now clause)

| Skill | Species/plantables | Dishes | Notes |
|---|---|---|---|
| Fishing | 11 | — | all rows below; M2 authors ~7 recipes, rest by M3 checkpoint |
| Foraging | 8 | — | M3 rows |
| Gardening | 6 | — | M3 rows (herb/pepper beds reuse foraging recipes — no new art) |
| Cooking | — | 9 | M4 rows; dish art from 2 cheap archetypes (bowl, skewer) |
| **Total** | **25** | **9** | **34 ≈ the ~30 budget** (spec allows the list to flex here, not mid-build) |

Stroke archetypes (~12 budget): carp-shape, slender-shape, whisker-shape, small-fry · leafy, mushroom-cap,
fruit, tree · bowl, skewer · tool, furniture = **12 ✓**. Cadence holds: every skill lands a touchable unlock at
least every 10 levels without exceeding the species budget. **No adjustment needed — check passed.**

## 4. Per-skill unlock tables (a touchable unlock every ~10 levels)

### Fishing 낚시

| Lv | Unlock |
|---|---|
| 1 | Pond fishing, complete: crucian carp 붕어 · common carp 잉어 · pale chub 피라미 |
| 10 | Catfish 메기 — the night waters wake |
| 20 | Eel 뱀장어 — rain-fed nights |
| 30 | Mandarin fish 쏘가리 · "read the line" — fight telegraphs sharpen |
| 40 | Snakehead 가물치 |
| 50 | Icefish 빙어 — winter's fish |
| 60 | Cherry trout 산천어 — spring dawns |
| 70 | Pale carp 흰잉어 — a fog rarity |
| 80 | Old friends — rare-tier bite weight increases |
| 90 | **Ink carp 먹잉어** — the storm-night apex chase |
| 99 | Master's flourish — seated pose gains a stroke; ledger page gains the angler's mark |

### Foraging 채집 (M3 data rows)

| Lv | Unlock |
|---|---|
| 1 | Wild herbs, complete: mugwort 쑥 · shepherd's purse 냉이 |
| 10 | Oyster mushroom 느타리 |
| 20 | Moon mushroom 달버섯 — night-only |
| 30 | Persimmon 감 — autumn boughs |
| 40 | Pine nuts 잣 |
| 50 | Keen eye — find radius widens |
| 60 | Matsutake 송이 — autumn rare |
| 70 | Gentle hands — rare finds undamaged (ledger-quality) |
| 80 | Second sight — night finds glow faintly (paper-halo) |
| 90 | **Snow lotus 설련화** — blooms only in falling snow (the peddler's favorite trade) |
| 99 | Master's flourish |

### Gardening 원예 (M3 data rows; growth = real days, always)

| Lv | Unlock |
|---|---|
| 1 | First bed · radish 무 |
| 10 | Cabbage 배추 — 김장 begins here |
| 20 | Second bed · herb bed (reuses foraged herbs) |
| 30 | Plum tree 매화 — first planted tree, forever |
| 40 | Third bed |
| 50 | Pine tree 소나무 |
| 60 | Fourth bed · dew ritual flourish grows |
| 70 | Persimmon tree 감나무 |
| 80 | Quiet green — beds show bloom flourishes in any season |
| 90 | **The old ginkgo 은행나무** — the slow centerpiece tree |
| 99 | Master's flourish |

### Cooking 요리 (M4 data rows; meals give gentle buffs)

| Lv | Unlock |
|---|---|
| 1 | Grilled fish 생선구이 |
| 10 | Herb rice 나물밥 |
| 20 | Spicy fish stew 매운탕 — bite-rate buff |
| 30 | Mushroom soup 버섯국 |
| 40 | Kimchi 김장 — the winter ritual dish |
| 50 | Persimmon punch 수정과 |
| 60 | Pine-nut porridge 잣죽 |
| 70 | Full table 한상 — combined buffs |
| 80 | Warm hearth — buff durations lengthen |
| 90 | **The hermit's table** — apex feast |
| 99 | Master's flourish |

### Crafting 공예 (tools/furniture — templates, not species)

| Lv | Unlock |
|---|---|
| 1 | Mend the old rod |
| 10 | Bamboo rod — rare bite weight up |
| 20 | Forage basket — delicate finds carried safely |
| 30 | Repair kit — restoration goods, tier 1 |
| 40 | Horsehair brush — Artistry vocabulary grows |
| 50 | Keeper's rod — the fight eases |
| 60 | Furniture set — rooms furnish |
| 70 | Fine brush |
| 80 | Stone lantern — night halos for path and porch |
| 90 | **Master's rod** — flourish + gentlest fight (never an access gate) |
| 99 | Master's flourish |

### Artistry 서화

| Lv | Unlock |
|---|---|
| 1 | First composition: the pond vista |
| 10 | Second frame: the hermitage |
| 20 | Wet-wash technique |
| 30 | Third frame: the peak |
| 40 | Dry-brush technique |
| 50 | Pooling accents |
| 60 | Fourth frame: the forest |
| 70 | Mist gradation |
| 80 | Fifth frame: the terrace |
| 90 | **The red seal 낙관** — the game's only color, earned (pinned, spec §2) |
| 99 | The sealed era — retrospective wall |

(Larger canvases are unlocked by the **studio room** (restoration), not by level — rooms gate spaces, levels gate
technique; no double gates.)

## 5. Fishing species table (the M2 engine rows)

Tier weights: relative spawn weight *among currently eligible species*. Rarity also derives from reality's
rarity (a storm-night is rare by itself). `fight`: rare/apex tiers trigger the ~10 s tension dance.

| Species | KO | Tier | Lv | Seasons | Time | Weather | XP | Weight | Haptic signature | Archetype |
|---|---|---|---|---|---|---|---|---|---|---|
| Crucian carp | 붕어 | baseline | 1 | all | all | all | 60 | 100 | nibble-nibble-strike | carp-shape |
| Common carp | 잉어 | uncommon | 1 | all | all | all | 90 | 45 | slow heavy pull | carp-shape |
| Pale chub | 피라미 | baseline | 1 | all | day | clear·cloudy | 45 | 80 | quick flutter | small-fry |
| Catfish | 메기 | uncommon | 10 | all | night | all | 100 | 40 | deep double thud | whisker-shape |
| Eel | 뱀장어 | uncommon | 20 | spr·sum·aut | night | rain·storm | 120 | 35 | long slither | slender-shape |
| Mandarin fish | 쏘가리 | uncommon | 30 | summer | day·dusk | clear·cloudy | 120 | 35 | sharp double strike | carp-shape |
| Snakehead | 가물치 | rare | 40 | summer | all | all | 150 | 18 | violent run | slender-shape |
| Icefish | 빙어 | uncommon | 50 | winter | day | all | 110 | 40 | featherlight tick | small-fry |
| Cherry trout | 산천어 | rare | 60 | spring | dawn | clear·fog | 160 | 16 | three rising taps | slender-shape |
| Pale carp | 흰잉어 | rare | 70 | all | dawn·dusk | fog | 180 | 12 | fading pull | carp-shape |
| Ink carp | 먹잉어 | apex | 90 | all | night | storm | 250 | 8 | long silence, then everything | carp-shape |

Weather-variant sets follow the spec definition (weather dimension only): crucian carp has 6 variants; pale chub
2; ink carp 1. Completion math and the ledger use exactly these sets, intersected with climate capability.

## 6. Climate capability (per preset city, weather dimension)

Köppen-derived, honest to the city proper. Only `snow` is ever locked at v1 city spread — no fishing species
*requires* snow weather, so at M2 no fish is climate-locked anywhere; the first locked species is the M3 snow
lotus (the peddler valve's first customer).

| City | clear | cloudy | fog | rain | snow | storm |
|---|---|---|---|---|---|---|
| Seoul, Busan, Tokyo, London, Reykjavík, New York | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Singapore, Sydney, Cairo, San Francisco | ✓ | ✓ | ✓ | ✓ | — | ✓ |

## 7. Bite mechanics constants (M2)

- Time-to-bite: 5–20 s, drawn from the seeded RNG, weighted shorter for baseline tier.
- Strike window after the signature completes: **1.2 s** (generous — accessibility).
- Missed strike / lost fight: fish slips away; species previously uncaught → shadow "got away" flag. No other cost.
- Fight (rare/apex): ~10 s hold-to-reel; ease off within 0.8 s when the line "sings" (sharp haptic + visual
  shiver + audio cue); three failures to ease = the fish slips away.
- Haptic signatures are data: arrays of (offset s, intensity 0–1, sharpness 0–1, duration s). The bobber's
  visual tremble and the audio tick are driven by the *same* envelope — one source, three mirrors (spec §2
  accessibility).
