# Ssak (싹) — Project Handoff

**Written 2026-09-04** as a handoff from Claude Code to a new agent/toolchain (OpenAI Codex).
**Updated 2026-09-05 for final archival synchronization.**
This document describes the project as it **actually exists today**, not as any older plan
or instruction file describes it.

> ### Read this first — the project is closed
>
> Ssak is **finished and archived**. The GitHub repo `mhju0/ssak` is **archived read-only**
> (still public), first closed 2026-08-24 and temporarily reopened for final archival
> synchronization on 2026-09-05. See [FINAL_ARCHIVE.md](FINAL_ARCHIVE.md).
> Product development remains closed. There is no roadmap of pending work; see
> [`ROADMAP.md`](ROADMAP.md), which is mostly a record of what was deliberately *not* done.
>
> This handoff exists so the project is legible to a future reader/agent, **not** because
> work is expected to resume. If you do resume, the repo must be un-archived on GitHub first
> (pushes are rejected while archived).

Evidence tags follow this repo's convention: **[Verified]** = read/executed in this session ·
**[Inferred]** = reasoned from what was read · **[Unknown]** = not determinable ·
**[Conversation]** = the only source is Claude conversation history / session transcripts.

---

## 1. Purpose

Ssak (싹, "sprout") is a cozy, calm **iOS game**: you keep **one** plant on a windowsill and
raise it from seed to bloom **on the real clock**, then press the bloom to a shelf and start
the next of **six species**. No timers to beat, no currency, no failure state.

It was built as a deliberate two-goal experiment [Conversation, recorded in `RETROSPECTIVE.md` §1]:

1. Build a game (the author had never made one).
2. Run one whole project end-to-end by driving an AI coding agent (Anthropic's Fable model
   via Claude Code), to find out where that workflow breaks.

Neither goal was "ship to the App Store." It was never submitted, and won't be.

Ssak is itself a **restart**. The same repo began as **Meok (먹)**, an ink-wash skilling RPG
with six interlocking progression systems, scrapped at day five as over-scoped. Meok's full
history is preserved at the git tag `meok-archive` [Verified: `git ls-remote --tags`].

---

## 2. Architecture

```
ssak/
├── App/                    thin iOS app shell (@main, 14 lines) + AppIcon asset catalog
├── SsakCore/               SwiftPM pkg — pure game logic. No SwiftUI, no clock of its own.
├── SsakArt/                SwiftPM pkg — every flower hand-drawn in SwiftUI Paths
├── SsakApp/                SwiftPM pkg — the screens, over one GardenModel reducer
├── project.yml             XcodeGen spec → generates Ssak.xcodeproj (NOT committed)
├── art/                    icon SVG sources, README hero, walkthrough GIF, social card
└── docs/                   specs, plans, ADRs, agent-harness docs, design mockups
```

**Dependency direction** [Verified: the three `Package.swift` files]:

```
App  →  SsakApp  →  SsakArt  →  SsakCore
  └────────────────────────────────┘  (App also links SsakCore directly)
```

`SsakCore` depends on nothing but Foundation. `SsakArt` depends on `SsakCore` (for `Species`
/ `GrowthStage`) and SwiftUI. `SsakApp` depends on both.

**Platforms**: `platforms: [.iOS(.v16), .macOS(.v13)]` on all three packages [Verified].
The macOS floor is load-bearing, not incidental — the headless render harness and the whole
test suite run on the Mac via `swift test`, with **no simulator and no Xcode project needed**.
Every iOS-26-only API (Liquid Glass, historically) had to be `#if os(iOS)`-gated so the macOS
module still compiles.

**Three hard architectural rules**, held across the entire project [Verified in specs + code]:

1. **Time is injected.** `SsakCore` never reads the wall clock. Every transition takes a
   `now: Date` (and often a `Calendar`). The real `Date()` is read only at the interaction
   boundary in `RootView` [Verified: `SsakApp/Sources/SsakApp/RootView.swift:8`, `:34-36`].
2. **Art is authored, never generated at runtime.** No procedural drawing engine — that is
   named in the spec as "the specific trap that sank Meok" [Verified: design spec §5.1].
   Flowers are static SwiftUI `Path`/`Shape` code, authored through a render-to-PNG loop.
3. **No backend, no dependencies.** 100% Swift/SwiftUI, zero third-party packages, fully
   offline, local-only persistence.

---

## 3. Major components

### SsakCore — the engine (11 source files, 39 tests)

| File | Role |
|---|---|
| `GrowthEngine.swift` | The whole game rule set: `reconcile(_:to:species:tuning:)`, `water(...)`, `plant(...)`, `stage(forProgress:)`. All `static`, all pure. |
| `PlantState.swift` | The one persisted plant record (`speciesID, progress, moisture, lastUpdate, lastWateredAt, streak, isNursing, plantedAt`). |
| `GameState.swift` | `{ plant: PlantState, collected: [String] }` — the whole save file. |
| `GrowthTuning.swift` | Every calibration constant in one struct. `waterAmount 0.6 · drainPerDay 0.55 · dryThreshold 0.2 · tooWetThreshold 1.0 · moistureMax 1.3 · wiltAfterDryDays 4 · glowStreak 3`. **The one place to tune feel.** |
| `Species.swift` | `SpeciesCatalog` — six flowers with `bloomDays` 7/8/9/10/11/13, marigold the starter. |
| `GrowthStage.swift` | `seed → sprout → leaves → bud → bloom`, `Comparable`, with `.previous`. |
| `SoilState.swift` | `dry / moist / overfull` classification from moisture vs tuning. One home for a category the UI reads out three ways. |
| `CalendarDayGap.swift` | `Calendar.dayGap(from:to:)` — start-of-day to start-of-day. Shared by the streak counter and the streak-alive check so they cannot disagree. |
| `PlantStore.swift` | Save/load one `Codable` JSON file (`ssak.json`) in the app's Documents directory. Atomic write; both load failure modes return `nil`. |

**The growth math** [Verified: `GrowthEngine.reconcile`]: progress accrues only during the
*healthy* portion of the elapsed window. `reconcile` integrates: how long the plant was
waterlogged (paused), then how long until it hit `dryThreshold` (growing), capped by elapsed
time. Growth rate is `1 / species.bloomDays` per healthy day. Moisture drains linearly.

**The wilt setback** [Verified: `GrowthEngine.swift:69-78`]: if not already nursing, and
`unwateredDays >= wiltAfterDryDays`, and post-drain moisture is below `dryThreshold`, the plant
regresses **exactly one stage** (never below seed) and sets `isNursing`. The `!isNursing`
guard is load-bearing — without it a neglected plant would lose a stage on every foreground.

### SsakArt — the drawings (17 source files, 4 tests)

- `PlantView.swift` — the single dispatch seam: a 24-arm `switch (species.id, stage)` →
  per-species art, with `default → Placeholder`. **Deliberately not abstracted** — see
  [ADR-0002](adr/0002-species-art-dispatch.md).
- Six species files: `Marigold`, `Cosmos`, `Zinnia`, `Sunflower`, `Nasturtium`, `MorningGlory`
  — each with `sprout / leaves / bud / bloom`. The `seed` stage is shared (`SeedSoil.swift`)
  with only a species tint.
- `Droop.swift` — one reusable sag+desaturate effect layered over any stage, not drawn per stage.
- `SpeciesPalette.swift` — per-species colors keyed by `SsakCore` species id.
- **Three generations of backdrop, all still present**: `Backdrop.swift` (`Sill`/`Pot`, round 0),
  `SkyBackdrop.swift` (round 1 real-time sky), `RoomScene.swift` (round 2 living room),
  `HanjiBackdrop.swift` (round 3 album paper — **the only one the app uses today**).
  See §10, Technical debt.
- `SsakMark.swift` — the 싹 sprout mark, shared by app icon, watermark and empty shelf slots.
- `PNGRenderer.swift` — `pngData(for:size:)`, the headless `ImageRenderer` wrapper.

### SsakApp — the screens (10 source files, 15 tests)

- `GardenModel.swift` — **the only stateful object in the app.** `@MainActor ObservableObject`
  wrapping `GameState` + `PlantStore` + `GrowthTuning` + `Calendar`. Every transition takes
  `now`. Views never reach into `state.plant`; the model exposes derived reads
  (`stage`, `soil`, `moistureFraction`, `streak`, `currentDay(now:)`, `nextUncollected`,
  `isGardenComplete`, `hasWateredToday(now:)`, `isStreakAlive(now:)`).
- `RootView.swift` — the app root. A `TimelineView(.periodic(by: 60))` minute tick re-injects
  `now`; `InkNavTabs` switches Windowsill/Shelf; `StartGuide` overlays on first run;
  `scenePhase == .active` triggers `reconcileOnOpen`. Also owns the share sheet.
- `WindowsillView.swift` — the home screen (round 3 "압화집" hanji album page).
- `ShelfView.swift` — the six-slot collection. **This is where the core loop closes**: the
  current plant's slot becomes a seal-red "지금 눌러 두기" press target the moment it blooms.
- `StartGuide.swift` — first-run coach marks (welcome sheet + seed picker → 3 spotlight steps),
  anchored via a `PreferenceKey` (`guideTarget(_:)`).
- `InkKit.swift` — the round-3 ink components: `SealBadge`, `InkGauge`, `InkNavTabs`,
  `InkWaterButton`, `InkShareButton`, `BandClock`.
- `BloomCard.swift` — the shareable portrait card + `shareImage()` via `ImageRenderer`.
- `SsakFonts.swift` — registers bundled Nanum Myeongjo (SIL OFL) through CoreText, so the
  same path works in the app, tests, and the macOS render harness (no Info.plist dependency).
- `InkColors.swift` — `inkText()` adaptive color + the `Design` token enum (pad/radii/shadow)
  + the shared `Pressable` button style.

---

## 4. Data flow

```
 App launch
   └─ App/SsakApp.swift  →  GardenModel(store: PlantStore(), now: Date())
                              └─ PlantStore.load()  ← ~/Documents/ssak.json
                                 (nil → plant the starter marigold, save immediately)

 RootView
   ├─ TimelineView(.periodic, 60s) ──→ now ──→ WindowsillView / ShelfView   (cosmetic clock)
   ├─ scenePhase == .active ────────→ model.reconcileOnOpen(now: Date())
   └─ user taps water / plant ──────→ model.water(now: Date())
                                        └─ GrowthEngine.water → reconcile → save

 Every mutating transition:  GrowthEngine (pure) → state → try? store.save(state)
```

**Two clock reads, deliberately separated** [Verified: `RootView.swift:22-24` comment]:
the minute tick drives only *cosmetic* things (which hanji paper band, night ink flip, the
band clock). Anything that affects game state stamps its own `Date()` at the interaction
boundary and passes it into the model.

**Persistence is fire-and-forget**: `try? store.save(state)` — a failed local write is
non-fatal and silent, by decision (spec §4 states table: "persistence `try?` (local,
non-fatal) — silent, documented").

---

## 5. External services, database, state

- **External services: none.** No network code anywhere in the Ssak tree [Verified: no
  URLSession/network imports in any `SsakCore`/`SsakArt`/`SsakApp` source]. No accounts,
  no analytics, no ads, no IAP, no push, no iCloud.
  *(The predecessor Meok did call Open-Meteo for live weather — that code lives only under
  the `meok-archive` tag.)*
- **Database: none.** State is a single `Codable` JSON file, `ssak.json`, in the app's
  Documents directory, written atomically [Verified: `PlantStore.swift`].
- **Other persisted state**: exactly one `@AppStorage("hasOnboarded")` bool
  [Verified: `RootView.swift:11`]. That is the complete list of persistent keys.
- **Schema migration: none exists.** A `GameState` that fails to decode returns `nil` and the
  game silently starts fresh [Verified: `PlantStore.load()` + `PersistenceTests.testLoadCorruptFileReturnsNil`].
  This is an accepted trade-off for a local, zero-stakes save, not an oversight.

---

## 6. Environment & setup

**Requirements** [Verified on this machine, 2026-09-04]:

| Tool | Version present | Notes |
|---|---|---|
| macOS | Darwin 25.6 | |
| Xcode | 26.6 (17F113) | README says "Xcode 26" |
| Swift | 6.3.3 | packages declare `swift-tools-version:5.9`, build clean on 6.3.3 |
| XcodeGen | installed via Homebrew | only needed to (re)generate `Ssak.xcodeproj` |

There are **no environment variables**, no `.env` file, no secrets, and no credentials of any
kind in this project [Verified: no `.env*` files tracked or untracked; no secret-shaped strings].
`gh` CLI auth is a machine-level concern, not a project one.

```sh
brew install xcodegen      # once
xcodegen generate          # repo root → Ssak.xcodeproj (gitignored, regenerate freely)
open Ssak.xcodeproj        # pick a Simulator ▸ Run
```

---

## 7. Build / run / test commands

```sh
# Unit tests — no Xcode, no simulator. This is the primary verification loop.
(cd SsakCore && swift test)      # 39 tests
(cd SsakArt  && swift test)      #  4 tests
(cd SsakApp  && swift test)      # 15 tests

# Headless visual verification — renders screens to PNG, no simulator.
(cd SsakArt && swift run SsakArtRender)   # → SsakArt/rendered/*.png   (species sheets)
(cd SsakApp && swift run SsakAppRender)   # → SsakApp/rendered/*.png   (whole screens)

# iOS app build
xcodegen generate
xcodebuild -project Ssak.xcodeproj -scheme Ssak \
           -destination 'generic/platform=iOS Simulator' build
```

**There is no linter and no CI** [Verified: no `.github/` directory, `gh workflow list`
returns nothing, no SwiftLint/SwiftFormat config anywhere]. "Green" has always meant
`swift test` × 3 + eyeballing the rendered PNGs.

**Verified state as of 2026-09-05:**

- `swift test` — **58 tests, 0 failures** across the three packages (39 / 4 / 15) [Verified: run this session].
- `xcodebuild … build` — **BUILD SUCCEEDED** against a freshly generated `Ssak.xcodeproj` on Xcode 26.6 [Verified: run this session].

**Render-harness gotcha (important, easy to trip over)**: PNG bytes are
**environment-sensitive** — the committed reference PNGs were rendered on a different SDK and
already differ byte-wise on the current host. Never diff a fresh render against the committed
refs to prove a change is safe; capture a same-machine baseline before the edit and diff
against that [Verified: stated as a hard constraint in `docs/superpowers/plans/2026-07-20-ssak-redesign-ui.md`,
"Global Constraints" and Task 3].

---

## 8. Deployment

**None, and none planned.** Never submitted to the App Store: no provisioning profile, no
App Store Connect record, or distribution automation. `project.yml` defines shared
`settings.base`; XcodeGen generates Debug and Release configurations, but no App Store
export options, fastlane, or CI are configured. `MARKETING_VERSION` is `0.1.0`, bundle id `com.mhju.ssak`.

"Deployment" for this project means: `git tag v1.0-final` and archiving the GitHub repo. Both done.

---

## 9. What works / partial / broken

### Works (verified end to end)

- The full core loop: plant → water → grow across five visibly distinct stages → bloom →
  press to shelf → pick the next species. Six species, all art authored.
- Time-gated growth: progress accrues only while moisture is inside the healthy band; pauses
  when dry or over-full; resumes on watering.
- Forgiving realism: droop, nursing state, one-stage wilt setback, never below seed, shelf
  never lost.
- Streak counting on calendar days (not 24h blocks), including the "streak alive" derivation.
- Local persistence across restarts, incl. graceful reset on a corrupt file.
- Share: `ImageRenderer` → hanji specimen card → iOS share sheet.
- First-run start guide with a working seed picker and an interactive "your first watering" step.
- Accessibility: VoiceOver labels on hero/water/share/gauge/shelf slots, Dynamic Type via
  semantic styles, Reduce Motion gating, ≥44pt targets.
- The whole thing builds and every test passes on a current toolchain.

### Partial / with caveats

- **Device coverage is thin.** Simulator-verified throughout; only some polish passes were
  checked on real hardware [Verified: `RETROSPECTIVE.md` §5].
- **VoiceOver is English-only while the visible UI is Korean-first.** Round 3 made the UI
  Korean (메리골드 / 창가 / 압화집 / 흙이 촉촉해요) but explicitly deferred localizing the
  accessibility labels rather than silently mixing them
  [Verified: round-3 spec D1, and `InkKit.swift:86` `// VoiceOver stays English this round`].
- **`StartGuide` copy** was Koreanized in `1aa0770`, but the round-3 spec had listed a
  StartGuide restyle as a non-goal — the guide is the least design-integrated screen.
- **The long game has never been played.** A six-species collection takes weeks of real time;
  it has only ever been observed by moving the clock forward [Verified: `RETROSPECTIVE.md` §5].
- **Zero players.** Every claim that the game "feels calm" is untested against anyone but the author.

### Broken / known defects (all deliberately left)

1. **A historical report says the iOS 26.0 simulator renders the chrome nearly invisible** on the cream hanji background
   (top nav, day counter, water button). **iOS 26.5 renders correctly.** The cause was not independently diagnosed;
   the existing walkthrough uses the 26.5 simulator. [Conversation — recorded only in Claude auto-memory
   `ssak-closed.md`, never in the repo.]
2. **The 압화집 tab's hit area sits ~14pt below its label.** Synthetic taps at the glyphs
   (device y≈90) do nothing; y≈104 works. A real thumb hits it, so it was left alone.
   [Conversation — same source.]
3. `Placeholder` (`SsakArt/Marigold.swift:215`, reached from `PlantView.swift:72`) is
   unreachable in practice — all six species have art. It is a deliberate mechanism, not dead
   code; see [ADR-0002](adr/0002-species-art-dispatch.md) reason 3.

---

## 10. Technical debt & temporary hacks

| # | Item | Evidence | Assessment |
|---|---|---|---|
| 1 | **Two dead backdrop generations in SsakArt.** `SkyBackdrop` (round 1) and `RoomScene` (round 2) are no longer used by any screen — only by `SsakAppRender`. `HanjiBackdrop` (round 3) is what ships. | [Verified: `git grep RoomScene\|SkyBackdrop` — app hits are only in `SsakAppRender/Render.swift`] | **Deliberate.** Round-3 spec D12 kept them as "art library + harness references". Genuinely dead weight if anyone resumes; ~320 lines. |
| 2 | **Persisted `streak` can overstate after neglect.** `reconcile` deliberately does *not* reset the streak on a missed day; the "is the streak alive" truth is derived at the UI from `lastWateredAt`. The stored counter re-bases on the next `water()`. | [Verified: `GrowthEngine.swift:36-40` comment + `GardenModel.isStreakAlive`] | Documented, intentional, spec §3.2. A `ponytail:` note in the code proposes deriving the effective streak in the UI — never done. |
| 3 | **Render-harness `ScrollView` workaround.** `ShelfView` uses `#if os(iOS) ScrollView #else` top-aligned+clipped, because `ImageRenderer` can't lay out a `ScrollView` on macOS. | [Verified: `ShelfView.swift:22-28`] | A real hack, well commented, low risk. |
| 4 | **Font warm-up hack in the render harness.** A freshly CoreText-registered custom font's *first* one-shot `ImageRenderer` layout comes up zero-sized, so `SsakAppRender` renders a throwaway warm-up view first. | [Verified: `SsakApp/Sources/SsakAppRender/Render.swift:17-23`] | Load-bearing; deleting it silently breaks every reference render. |
| 5 | **Shelf grid is a hand-rolled `VStack`/`HStack`, not `LazyVGrid`** — lazy children never materialize under `ImageRenderer`, so the reference renders came out empty. | [Verified: `ShelfView.swift:52` comment] | Correct call; worth knowing before "modernizing" it. |
| 6 | **ADR numbering corrected** to ADR 0002 during final archival synchronization. | `docs/adr/0002-species-art-dispatch.md:1` | Resolved documentation mismatch. |
| 7 | **Reference PNGs are not reproducible across machines/SDKs.** See §7. | [Verified: plan doc, Global Constraints] | Inherent to `ImageRenderer`; the mitigation (same-machine baselines) is documented, not automated. |
| 8 | **`docs/agents/` is agent-harness scaffolding checked into the product repo** — issue-tracker conventions, a triage-label mapping, and a domain-doc reading protocol, all written for the `mattpocock-skills` Claude plugin (`/triage`, `/wayfinder`, `/domain-modeling`). It is instructions *to an agent*, not knowledge *about the game*. | [Verified: `docs/agents/*.md`; plugin still installed at `~/.claude/plugins/.../mattpocock-skills/1.2.3`] | Not project knowledge, and Claude-toolchain-specific. Safe to delete under a different harness. `CONTEXT.md` and `docs/adr/` **are** project knowledge — keep those. |

**No TODO / FIXME / HACK / XXX markers exist anywhere in the source** [Verified: `git grep -nEi`
across all tracked Swift/yml/json]. Debt was recorded in ADRs, commit bodies and doc comments instead.

---

## 11. Git state at the pre-archive baseline

This table records `a46f851` (before the handoff documents were added). It is historical,
not a claim about the final HEAD. See [FINAL_ARCHIVE.md](FINAL_ARCHIVE.md) for the final PR;
`git status`, `git log -1`, and GitHub are authoritative for current refs.

| | |
|---|---|
| Branch | `main` only, local and remote. No other branches exist [Verified: `git branch -a`, `gh api .../branches`]. |
| Working tree | **Clean.** No uncommitted changes, no stashes [Verified: `git status`, `git stash list`]. |
| HEAD | `a46f851` — *docs: rename POSTMORTEM.md to RETROSPECTIVE.md* (2026-08-24) |
| In sync with origin | Yes [Verified: `git ls-remote`] |
| Tags | `meok-archive` → `8c88a63` (the Meok endpoint) · `v1.0-final` → `b69e754` (the closing commit). Both pushed. |
| Commits | **190 total**: 67 Meok-era (2026-07-15 → 07-19) + 123 Ssak-era (07-19 → 08-24), 3 merge commits [Verified: `git rev-list --count`]. |
| Merged PRs | #33 (`ssak-core-engine`), #34 (`ssak-art-foundation`), #36 (`ssak-art-species`). #35 was closed unmerged — it targeted the wrong base branch and was re-opened as #36 [Inferred from `gh pr list`: same head branch, `#35 → ssak-art-foundation`, `#36 → main`]. |
| Issues | 32 issues, **all closed, all Meok-era**. Zero issues were ever filed for Ssak [Verified: `gh issue list --state all`]. |
| Releases | None. |
| CI | None. |
| Dangling objects | 26 dangling commits, all `git stash` WIP snapshots plus two amend-predecessors of the closing commit. Nothing lost [Verified: `git fsck --lost-found` + `git log` on each]. |
| Untracked/ignored locally | `.superpowers/` (agent session scratch), `docs/ko/RETROSPECTIVE.ko.md` (Korean translation, deliberately never committed), `Ssak.xcodeproj/`, `.build/`, `.DS_Store`. |

---

## 12. Recent major development (reverse chronological)

| When | What |
|---|---|
| **2026-08-24** | **Project closed.** `RETROSPECTIVE.md` written, README status block, walkthrough GIF, `v1.0-final` tag, GitHub repo archived. (`b69e754`, `832517a`, `ea29c50`, `a46f851`) |
| 2026-07-31 → 08-02 | **Licensing reversed**: MIT removed, all rights reserved, `LICENSE` file deleted; plan docs corrected; README license section moved to the end. Then the inlined "working standard" was removed from `CLAUDE.md`. (`722002e`, `9186553`, `f3fc8e7`, `9fa6a5d`) |
| 2026-07-27 | A shared working standard was inlined into `CLAUDE.md` (`2bc6db5`) — reversed six days later. |
| 2026-07-24 | Seed picker on the start screen; interactive watering tutorial; guide fixes. Last product-code commit is `63e1f4c` (2026-07-24). |
| 2026-07-23 | **UI redesign round 3** — the 한지 압화집 (hanji pressed-flower album). Retired the entire Liquid Glass kit. Plus a burst of real bug fixes: the unreachable core loop (`72c3b95`), share card always showing a bloom (`cfdbe05`), the frozen clock (`ec1646e`), the on-device spotlight miss (`ba0cb00`), over-full mixed signals (`1150f2f`), idle chrome-fade removed (`912f7fb`). |
| 2026-07-22 → 23 | **UI redesign round 2** — living `RoomScene`, top pill nav, coach-mark `StartGuide` replacing the 3-screen onboarding. |
| 2026-07-20 | **UI redesign round 1** — Liquid Glass, real-time sky, Bloom-Point app icon, accessibility pass, `SoilState` extraction, `Calendar.dayGap` dedup, ADR-0002. |
| 2026-07-19 | Ssak begins. Meok archived + repo/folder renamed; `SsakCore` engine (TDD, PR #33); `SsakArt` foundation + all six species (PRs #34, #36); `SsakApp` screens + iOS shell. |
| 2026-07-15 → 19 | Meok (먹): M0–M3, 67 commits, then scrapped. |

---

## 13. Important unresolved questions

1. **Does the six-species long game actually hold up?** Nobody has played a full collection in
   real time. The pacing (`bloomDays` 7→13, ~1 real day ≈ 1 plant-week) is calibrated by feel,
   not by observation [Verified: design spec §3 "tuned by feel, not derived"].
2. **Is it actually calm?** Zero players. Untested claim.
3. **Would the round-3 hanji direction survive on real hardware across all four time bands?**
   The README hero re-shoot was gated on device approval; only day/dusk/night were rendered
   and inspected headlessly. The round-3 plan lists the device pass as "flagged, not in-plan."
4. **The Korean retrospective was never posted to a blog.** The draft is now preserved
   at [`ko/RETROSPECTIVE.ko.md`](ko/RETROSPECTIVE.ko.md) as part of the final archive.
5. **Profile pin completed 2026-09-05.** `mhju0/ssak` was pinned through GitHub’s UI;
   the earlier inference that this could not be automated was incorrect (DECISIONS C-6).

---

## 14. Current development focus

**None.** The project is closed by an explicit decision, and the decision is recorded in three
places (`README.md` status block, `RETROSPECTIVE.md` §7, and the archived GitHub repo).

If a future session is asked to do something here, the correct default is: **read, explain,
or extract lessons — do not add features.** Anything else needs the repo un-archived first,
and an explicit statement from the author that Ssak is being resumed.

---

## 15. Known documentation discrepancies

Worth knowing before you trust any single number:

| Claim | Where | Reality |
|---|---|---|
| "186 commits" / "66 Meok + 119 Ssak" | `RETROSPECTIVE.md` §1, §2, §3 | 190 total (67 + 123) as of `a46f851` [Verified: `git rev-list --count`]. The retrospective's counts were taken mid-close and are approximate. |
| "63 Swift files, 5,720 LOC" | Claude auto-memory `ssak-closed.md` | Superseded. `832517a` corrected this to **59 files / 4,066 lines** (the earlier figure counted generated `.build/` artifacts). 59/4,066 describes the original close; final archive render tooling adds 32 lines (59/4,098) [Verified: `git ls-files '*.swift' \| xargs wc -l`]. |
| "`POSTMORTEM.md`" | Claude auto-memory `ssak-closed.md` | Renamed to `RETROSPECTIVE.md` in `a46f851`. |
| "Korean draft at `~/Workspace/Projects/ssak-retro.md`" | Claude auto-memory `ssak-closed.md` | That path no longer exists; the file is now `docs/ko/RETROSPECTIVE.ko.md` (tracked in the final archive). |
| Four "minor" test-discrimination findings (vacuous wilt test, untested `!isNursing` guard, untested corrupt-file path, untested wilt boundaries) | 2026-07-19 multi-agent review [Conversation] | **All four were fixed** in `888c3de`, each proven to fail on mutated source first [Verified: `WiltTests.swift`, `PersistenceTests.swift`]. Do not re-report them as open. |
| `CLAUDE.md` "Agent skills" section | repo root | Points at the `mattpocock-skills` Claude plugin's conventions. The plugin is still installed today, but the harness that actually built Ssak (the `superpowers` plugin — source of `docs/superpowers/` and the untracked `.superpowers/`) is **not** installed any more [Verified: absent from `~/.claude/plugins/cache`, only residual data dirs remain]. Accurate as a description of `docs/agents/`; not a portable instruction. |
