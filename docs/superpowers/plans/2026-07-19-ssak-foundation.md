# Ssak Foundation & Growth Engine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Archive Meok safely, rename the project to Ssak, and build `SsakCore` — a pure Swift package holding the species data, the growth/moisture/streak engine, and local persistence — fully covered by `swift test`.

**Architecture:** `SsakCore` is a standalone SwiftPM package with **no SwiftUI and no UIKit** — just Foundation. All game logic is pure functions on value types with time injected as a `Date` parameter, so every rule is unit-testable from the command line without a simulator. The SwiftUI app (Plan 3) will depend on this package but holds no game rules of its own.

**Tech Stack:** Swift 5.9+, SwiftPM, XCTest, Foundation (`Date`, `Calendar`, `Codable`). No third-party dependencies.

## Global Constraints

- **Package name:** `SsakCore`. No SwiftUI/UIKit imports anywhere in it.
- **Time is always injected.** No function in `SsakCore` calls `Date()` internally. Tests pass fixed dates built from a **UTC** calendar to avoid timezone/DST flakiness.
- **Local-only, no backend, no dependencies.**
- **The six species (id, EN, KO, bloomDays):** marigold/Marigold/메리골드/7 (starter), nasturtium/Nasturtium/한련화/8, cosmos/Cosmos/코스모스/9, zinnia/Zinnia/백일홍/10, sunflower/Sunflower/해바라기/11, morning_glory/Morning glory/나팔꽃/13. `bloomDays` = real days of *healthy* growth to bloom; all values tunable.
- **Growth model:** progress ∈ [0,1] accrues with real elapsed time **only while moisture is in the healthy band**; stalls otherwise; never punishes beyond delay. See `GrowthTuning` for the calibration constants — they are feel knobs, not derived truths.
- **License:** MIT, `Copyright (c) 2026 Michael Ju (github.com/mhju0)`.

---

## Roadmap (this plan is #1 of 3)

1. **Foundation & Growth Engine** ← this document. Deliverable: `SsakCore` package, green `swift test`. No UI, no art.
2. **Art** (separate plan): per-species `FlowerArt` SwiftUI drawings (~30 stages, detail ramping to a lavish bloom) + the droop/overwater tint effect, validated visually in Xcode previews. Uses the marigold hero sample as the detail bar.
3. **App UI** (separate plan): the `Ssak` Xcode app — Windowsill + Shelf screens, drop-gauge, water/share buttons, seed chooser, onboarding, `ImageRenderer` share export — wiring `SsakCore` to `FlowerArt`.

---

## Task 0: Archive Meok & rename to Ssak

**⚠ Execution note:** steps 3 (push), 4 (GitHub repo rename), and 6 (folder rename) are outward-facing / hard to reverse. Confirm with Michael immediately before running each. GitHub auto-redirects the old repo URL, but confirm anyway.

**Files:** none created; this is git/gh/filesystem plumbing.

- [ ] **Step 1: Stash the stray working-tree change**

```bash
git stash push -m "meok wip xcstrings" -- Meok/Localizable.xcstrings
git status --short   # expect clean
```

- [ ] **Step 2: Tag the current state as the Meok archive**

```bash
git tag -a meok-archive -m "Final state of Meok (먹) before Ssak restart"
git tag --list | grep meok-archive
```

- [ ] **Step 3: Push the 3 unpushed commits + the tag (CONFIRM FIRST)**

```bash
git push origin main
git push origin meok-archive
git rev-list --count origin/main..HEAD   # expect 0
```

- [ ] **Step 4: Rename the GitHub repo meok → ssak (CONFIRM FIRST)**

```bash
gh repo rename ssak --repo mhju0/meok --yes
git remote set-url origin https://github.com/mhju0/ssak.git
git remote -v   # expect ssak.git
```

- [ ] **Step 5: Verify the archive is recoverable, then clear the old app tree from the working set**

The old code stays in history and under `meok-archive`. Remove the Meok app sources from the working tree so Ssak starts clean (they remain in git history / the tag):

```bash
git rm -r Meok Meok.xcodeproj MeokKit
git commit -m "chore: clear Meok app tree; Ssak starts fresh (old code under tag meok-archive)"
git show meok-archive:Meok/ >/dev/null && echo "archive intact"
```

- [ ] **Step 6: Rename the local folder (CONFIRM FIRST)**

```bash
cd .. && mv meok ssak && cd ssak && pwd   # expect .../Projects/ssak
```

- [ ] **Step 7: Update project docs & memory to Ssak** (do inline, then commit)

Update `CLAUDE.md` (title, repo URL github.com/mhju0/ssak, drop Meok-specific spec path), and the auto-memory note. Then:

```bash
git add -A && git commit -m "docs: retitle project Meok → Ssak"
```

---

## Task 1: Scaffold the SsakCore package

**Files:**
- Create: `SsakCore/Package.swift`
- Create: `SsakCore/Sources/SsakCore/SsakCore.swift` (placeholder)
- Create: `SsakCore/Tests/SsakCoreTests/TestSupport.swift`
- Create: `SsakCore/Tests/SsakCoreTests/SmokeTests.swift`

**Interfaces:**
- Produces: a buildable SwiftPM package `SsakCore`; test helpers `utcCal` and `day(_:hour:)` for all later test tasks.

- [ ] **Step 1: Create the package manifest**

`SsakCore/Package.swift`:
```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SsakCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "SsakCore", targets: ["SsakCore"])],
    targets: [
        .target(name: "SsakCore"),
        .testTarget(name: "SsakCoreTests", dependencies: ["SsakCore"]),
    ]
)
```

- [ ] **Step 2: Add a placeholder source so the package builds**

`SsakCore/Sources/SsakCore/SsakCore.swift`:
```swift
import Foundation

public enum SsakCore {
    public static let version = "0.1.0"
}
```

- [ ] **Step 3: Add the shared test helpers**

`SsakCore/Tests/SsakCoreTests/TestSupport.swift`:
```swift
import Foundation

let utcCal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}()

func day(_ n: Int, hour: Int = 9) -> Date {
    utcCal.date(from: DateComponents(year: 2026, month: 7, day: 1 + n, hour: hour))!
}
```

- [ ] **Step 4: Add a smoke test**

`SsakCore/Tests/SsakCoreTests/SmokeTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class SmokeTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(SsakCore.version, "0.1.0")
    }
    func testDayHelperIsUTC() {
        XCTAssertEqual(day(1).timeIntervalSince(day(0)), 86400, accuracy: 0.5)
    }
}
```

- [ ] **Step 5: Build & test**

Run: `cd SsakCore && swift test`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add SsakCore && git commit -m "feat(core): scaffold SsakCore package with test helpers"
```

---

## Task 2: Growth stages & thresholds

**Files:**
- Create: `SsakCore/Sources/SsakCore/GrowthStage.swift`
- Create: `SsakCore/Sources/SsakCore/GrowthEngine.swift`
- Test: `SsakCore/Tests/SsakCoreTests/GrowthStageTests.swift`

**Interfaces:**
- Produces: `enum GrowthStage: String, Codable, CaseIterable, Comparable { case seed, sprout, leaves, bud, bloom }` with `var previous: GrowthStage?`; `enum GrowthEngine` with `static func stage(forProgress: Double) -> GrowthStage` and `static func progressAtStartOf(_ stage: GrowthStage) -> Double`.

- [ ] **Step 1: Write the failing test**

`SsakCore/Tests/SsakCoreTests/GrowthStageTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class GrowthStageTests: XCTestCase {
    func testStageThresholds() {
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.0), .seed)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.14), .seed)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.15), .sprout)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.50), .leaves)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 0.75), .bud)
        XCTAssertEqual(GrowthEngine.stage(forProgress: 1.0), .bloom)
    }
    func testPreviousStage() {
        XCTAssertEqual(GrowthStage.bloom.previous, .bud)
        XCTAssertEqual(GrowthStage.sprout.previous, .seed)
        XCTAssertNil(GrowthStage.seed.previous)
    }
    func testProgressAtStartOf() {
        XCTAssertEqual(GrowthEngine.progressAtStartOf(.leaves), 0.40, accuracy: 0.0001)
        XCTAssertEqual(GrowthEngine.progressAtStartOf(.seed), 0.0, accuracy: 0.0001)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd SsakCore && swift test --filter GrowthStageTests`
Expected: FAIL (GrowthStage / GrowthEngine undefined).

- [ ] **Step 3: Write minimal implementation**

`SsakCore/Sources/SsakCore/GrowthStage.swift`:
```swift
import Foundation

public enum GrowthStage: String, Codable, CaseIterable, Comparable {
    case seed, sprout, leaves, bud, bloom

    private var order: Int { Self.allCases.firstIndex(of: self)! }
    public static func < (a: GrowthStage, b: GrowthStage) -> Bool { a.order < b.order }

    public var previous: GrowthStage? {
        order > 0 ? Self.allCases[order - 1] : nil
    }
}
```

`SsakCore/Sources/SsakCore/GrowthEngine.swift`:
```swift
import Foundation

public enum GrowthEngine {
    public static func stage(forProgress p: Double) -> GrowthStage {
        switch p {
        case ..<0.15: return .seed
        case ..<0.40: return .sprout
        case ..<0.75: return .leaves
        case ..<1.0:  return .bud
        default:      return .bloom
        }
    }

    public static func progressAtStartOf(_ stage: GrowthStage) -> Double {
        switch stage {
        case .seed:   return 0.0
        case .sprout: return 0.15
        case .leaves: return 0.40
        case .bud:    return 0.75
        case .bloom:  return 1.0
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd SsakCore && swift test --filter GrowthStageTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SsakCore && git commit -m "feat(core): growth stages and progress thresholds"
```

---

## Task 3: Species & catalog

**Files:**
- Create: `SsakCore/Sources/SsakCore/Species.swift`
- Test: `SsakCore/Tests/SsakCoreTests/SpeciesCatalogTests.swift`

**Interfaces:**
- Produces: `struct Species: Identifiable, Codable, Equatable { let id, nameEN, nameKO: String; let bloomDays: Double }` and `enum SpeciesCatalog` with `all: [Species]`, `starter: Species`, `species(id:) -> Species?`, plus the six static members.

- [ ] **Step 1: Write the failing test**

`SsakCore/Tests/SsakCoreTests/SpeciesCatalogTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class SpeciesCatalogTests: XCTestCase {
    func testAllSixPresentInPacingOrder() {
        let ids = SpeciesCatalog.all.map(\.id)
        XCTAssertEqual(ids, ["marigold", "nasturtium", "cosmos", "zinnia", "sunflower", "morning_glory"])
    }
    func testStarterIsMarigoldAndFastest() {
        XCTAssertEqual(SpeciesCatalog.starter.id, "marigold")
        XCTAssertEqual(SpeciesCatalog.all.min(by: { $0.bloomDays < $1.bloomDays })?.id, "marigold")
    }
    func testLookup() {
        XCTAssertEqual(SpeciesCatalog.species(id: "cosmos")?.nameKO, "코스모스")
        XCTAssertNil(SpeciesCatalog.species(id: "rose"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd SsakCore && swift test --filter SpeciesCatalogTests`
Expected: FAIL (Species undefined).

- [ ] **Step 3: Write minimal implementation**

`SsakCore/Sources/SsakCore/Species.swift`:
```swift
import Foundation

public struct Species: Identifiable, Codable, Equatable {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    public let bloomDays: Double

    public init(id: String, nameEN: String, nameKO: String, bloomDays: Double) {
        self.id = id; self.nameEN = nameEN; self.nameKO = nameKO; self.bloomDays = bloomDays
    }
}

public enum SpeciesCatalog {
    public static let marigold     = Species(id: "marigold",      nameEN: "Marigold",      nameKO: "메리골드", bloomDays: 7)
    public static let nasturtium   = Species(id: "nasturtium",    nameEN: "Nasturtium",    nameKO: "한련화",   bloomDays: 8)
    public static let cosmos       = Species(id: "cosmos",        nameEN: "Cosmos",        nameKO: "코스모스", bloomDays: 9)
    public static let zinnia       = Species(id: "zinnia",        nameEN: "Zinnia",        nameKO: "백일홍",   bloomDays: 10)
    public static let sunflower    = Species(id: "sunflower",     nameEN: "Sunflower",     nameKO: "해바라기", bloomDays: 11)
    public static let morningGlory = Species(id: "morning_glory", nameEN: "Morning glory", nameKO: "나팔꽃",   bloomDays: 13)

    public static let all: [Species] = [marigold, nasturtium, cosmos, zinnia, sunflower, morningGlory]
    public static let starter: Species = marigold

    public static func species(id: String) -> Species? { all.first { $0.id == id } }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd SsakCore && swift test --filter SpeciesCatalogTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SsakCore && git commit -m "feat(core): species catalog (6 flowers, marigold starter)"
```

---

## Task 4: PlantState, planting, tuning, and "watered today"

**Files:**
- Create: `SsakCore/Sources/SsakCore/PlantState.swift`
- Create: `SsakCore/Sources/SsakCore/GrowthTuning.swift`
- Modify: `SsakCore/Sources/SsakCore/GrowthEngine.swift` (add `plant` and `hasWateredToday`)
- Test: `SsakCore/Tests/SsakCoreTests/PlantLifecycleTests.swift`

**Interfaces:**
- Produces:
  - `struct PlantState: Codable, Equatable { var speciesID: String; var progress: Double; var moisture: Double; var lastUpdate: Date; var lastWateredAt: Date?; var streak: Int; var isNursing: Bool; var plantedAt: Date }`
  - `struct GrowthTuning` with `waterAmount, drainPerDay, dryThreshold, tooWetThreshold, moistureMax, wiltAfterDryDays: Double`, `glowStreak: Int`, and `static let default`.
  - `GrowthEngine.plant(_ species: Species, at: Date) -> PlantState`
  - `GrowthEngine.hasWateredToday(_ state: PlantState, now: Date, calendar: Calendar = .current) -> Bool`

- [ ] **Step 1: Write the failing test**

`SsakCore/Tests/SsakCoreTests/PlantLifecycleTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class PlantLifecycleTests: XCTestCase {
    func testPlantStartsSeedMoistAndWatered() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        XCTAssertEqual(s.speciesID, "marigold")
        XCTAssertEqual(s.progress, 0, accuracy: 0.0001)
        XCTAssertEqual(GrowthEngine.stage(forProgress: s.progress), .seed)
        XCTAssertGreaterThan(s.moisture, GrowthTuning.default.dryThreshold)
        XCTAssertEqual(s.streak, 1)
        XCTAssertFalse(s.isNursing)
        XCTAssertEqual(s.lastWateredAt, day(0))
    }
    func testHasWateredToday() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        XCTAssertTrue(GrowthEngine.hasWateredToday(s, now: day(0, hour: 20), calendar: utcCal))
        XCTAssertFalse(GrowthEngine.hasWateredToday(s, now: day(2), calendar: utcCal))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd SsakCore && swift test --filter PlantLifecycleTests`
Expected: FAIL (PlantState / GrowthTuning / plant undefined).

- [ ] **Step 3: Write minimal implementation**

`SsakCore/Sources/SsakCore/PlantState.swift`:
```swift
import Foundation

public struct PlantState: Codable, Equatable {
    public var speciesID: String
    public var progress: Double        // 0...1 healthy growth
    public var moisture: Double        // 0...moistureMax
    public var lastUpdate: Date        // last engine reconciliation
    public var lastWateredAt: Date?    // for streak / watered-today / neglect
    public var streak: Int
    public var isNursing: Bool         // wilt-setback state
    public var plantedAt: Date

    public init(speciesID: String, progress: Double, moisture: Double, lastUpdate: Date,
                lastWateredAt: Date?, streak: Int, isNursing: Bool, plantedAt: Date) {
        self.speciesID = speciesID; self.progress = progress; self.moisture = moisture
        self.lastUpdate = lastUpdate; self.lastWateredAt = lastWateredAt; self.streak = streak
        self.isNursing = isNursing; self.plantedAt = plantedAt
    }
}
```

`SsakCore/Sources/SsakCore/GrowthTuning.swift`:
```swift
import Foundation

public struct GrowthTuning {
    public var waterAmount: Double     // moisture added per watering
    public var drainPerDay: Double     // moisture lost per real day
    public var dryThreshold: Double    // below this: too dry, growth pauses
    public var tooWetThreshold: Double // above this: waterlogged, growth pauses
    public var moistureMax: Double     // watering cap (can exceed tooWet → stress)
    public var wiltAfterDryDays: Double
    public var glowStreak: Int

    public init(waterAmount: Double = 0.6, drainPerDay: Double = 0.55,
                dryThreshold: Double = 0.2, tooWetThreshold: Double = 1.0,
                moistureMax: Double = 1.3, wiltAfterDryDays: Double = 4,
                glowStreak: Int = 3) {
        self.waterAmount = waterAmount; self.drainPerDay = drainPerDay
        self.dryThreshold = dryThreshold; self.tooWetThreshold = tooWetThreshold
        self.moistureMax = moistureMax; self.wiltAfterDryDays = wiltAfterDryDays
        self.glowStreak = glowStreak
    }

    public static let `default` = GrowthTuning()
}
```

Add to `GrowthEngine` (inside the existing `enum GrowthEngine`):
```swift
    public static func plant(_ species: Species, at now: Date) -> PlantState {
        PlantState(speciesID: species.id, progress: 0, moisture: 0.6,
                   lastUpdate: now, lastWateredAt: now, streak: 1,
                   isNursing: false, plantedAt: now)
    }

    public static func hasWateredToday(_ state: PlantState, now: Date,
                                       calendar: Calendar = .current) -> Bool {
        guard let last = state.lastWateredAt else { return false }
        return calendar.isDate(last, inSameDayAs: now)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd SsakCore && swift test --filter PlantLifecycleTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SsakCore && git commit -m "feat(core): PlantState, GrowthTuning, plant() and hasWateredToday"
```

---

## Task 5: Reconcile — healthy growth accrues over real time

**Files:**
- Modify: `SsakCore/Sources/SsakCore/GrowthEngine.swift` (add `reconcile`)
- Test: `SsakCore/Tests/SsakCoreTests/ReconcileGrowthTests.swift`

**Interfaces:**
- Produces: `GrowthEngine.reconcile(_ state: PlantState, to now: Date, species: Species, tuning: GrowthTuning = .default) -> PlantState`. Depletes moisture linearly and accrues `progress` by `healthyDuration / species.bloomDays`, where healthyDuration is the portion of the elapsed interval with moisture in `[dryThreshold, tooWetThreshold]`. Sets `lastUpdate = now`. (Wilt logic added in Task 8; not here.)

- [ ] **Step 1: Write the failing test**

`SsakCore/Tests/SsakCoreTests/ReconcileGrowthTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class ReconcileGrowthTests: XCTestCase {
    func testHealthyGrowthAccruesProportionally() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.85   // stays healthy across a short window
        let out = GrowthEngine.reconcile(s, to: day(0, hour: 21), species: SpeciesCatalog.marigold)
        // 0.5 day of healthy growth ÷ bloomDays 7
        XCTAssertEqual(out.progress, 0.5 / 7, accuracy: 0.005)
        XCTAssertEqual(out.moisture, 0.85 - 0.55 * 0.5, accuracy: 0.002)
        XCTAssertEqual(out.lastUpdate, day(0, hour: 21))
    }

    func testBloomsAfterExactlyBloomDaysOfHealthyTime() {
        var tuning = GrowthTuning.default
        tuning.drainPerDay = 0   // hold moisture so bloomDays alone governs
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.8
        let out = GrowthEngine.reconcile(s, to: day(7), species: SpeciesCatalog.marigold, tuning: tuning)
        XCTAssertEqual(out.progress, 1.0, accuracy: 0.001)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .bloom)
    }

    func testNoElapsedNoChange() {
        let s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        let out = GrowthEngine.reconcile(s, to: day(0), species: SpeciesCatalog.marigold)
        XCTAssertEqual(out.progress, s.progress, accuracy: 0.0001)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd SsakCore && swift test --filter ReconcileGrowthTests`
Expected: FAIL (reconcile undefined).

- [ ] **Step 3: Write minimal implementation**

Add to `GrowthEngine`:
```swift
    public static func reconcile(_ state: PlantState, to now: Date, species: Species,
                                 tuning t: GrowthTuning = .default) -> PlantState {
        var out = state
        let elapsed = now.timeIntervalSince(state.lastUpdate) / 86400.0  // days
        guard elapsed > 0 else { out.lastUpdate = now; return out }

        let startM = state.moisture
        let drain = t.drainPerDay

        var healthyDuration = 0.0
        if startM >= t.dryThreshold {
            // paused while waterlogged at the start of the window
            let wetPause = startM > t.tooWetThreshold ? (startM - t.tooWetThreshold) / drain : 0
            let healthyStart = min(wetPause, elapsed)
            let moistureAtStart = startM - drain * healthyStart
            let timeUntilDry = max(0, (moistureAtStart - t.dryThreshold) / drain)
            healthyDuration = max(0, min(elapsed, healthyStart + timeUntilDry) - healthyStart)
        }
        // startM < dryThreshold → dry the whole window → no growth

        out.progress = min(1.0, state.progress + healthyDuration / species.bloomDays)
        out.moisture = max(0, startM - drain * elapsed)
        out.lastUpdate = now
        return out
    }
```

Note: when `drain == 0`, the `wetPause`/`timeUntilDry` divisions are guarded by the `startM > tooWet` / branch structure — with `drain == 0` and `startM` inside the band, `wetPause` is 0 and `timeUntilDry` is `+inf`, so `min(elapsed, …)` clamps to `elapsed`. This is the intended "moisture held constant" behavior used by `testBloomsAfterExactlyBloomDaysOfHealthyTime`.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd SsakCore && swift test --filter ReconcileGrowthTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SsakCore && git commit -m "feat(core): reconcile accrues healthy growth over real time"
```

---

## Task 6: Reconcile — dryness pauses growth

**Files:**
- Modify: none (behavior already in `reconcile`; this task proves the dry-pause branch discriminates).
- Test: `SsakCore/Tests/SsakCoreTests/ReconcileDrynessTests.swift`

**Interfaces:**
- Consumes: `GrowthEngine.reconcile` from Task 5.

- [ ] **Step 1: Write the failing test** (fails only if the dry-pause logic is wrong; write it before trusting Task 5's branch)

`SsakCore/Tests/SsakCoreTests/ReconcileDrynessTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class ReconcileDrynessTests: XCTestCase {
    func testDrySoilAccruesNoGrowth() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.1   // below dryThreshold 0.2
        let out = GrowthEngine.reconcile(s, to: day(2), species: SpeciesCatalog.marigold)
        XCTAssertEqual(out.progress, 0, accuracy: 0.0001)
    }

    func testGrowthStopsWhenMoistureRunsDry() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 0.75   // drains to dry(0.2) after (0.75-0.2)/0.55 = 1.0 day
        let out = GrowthEngine.reconcile(s, to: day(3), species: SpeciesCatalog.marigold)
        // only ~1.0 healthy day out of 3 elapsed
        XCTAssertEqual(out.progress, 1.0 / 7, accuracy: 0.02)
        XCTAssertEqual(out.moisture, 0, accuracy: 0.0001)  // fully drained (clamped)
    }
}
```

- [ ] **Step 2: Run test to verify it passes** (Task 5 should already satisfy it)

Run: `cd SsakCore && swift test --filter ReconcileDrynessTests`
Expected: PASS. If it FAILS, the dry-pause math in `reconcile` is wrong — fix `reconcile` before continuing.

- [ ] **Step 3: Commit**

```bash
git add SsakCore && git commit -m "test(core): dryness pauses growth"
```

---

## Task 7: Reconcile — overwatering (waterlogged) pauses growth

**Files:**
- Test: `SsakCore/Tests/SsakCoreTests/ReconcileOverwaterTests.swift`

**Interfaces:**
- Consumes: `GrowthEngine.reconcile`.

- [ ] **Step 1: Write the failing test**

`SsakCore/Tests/SsakCoreTests/ReconcileOverwaterTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class ReconcileOverwaterTests: XCTestCase {
    func testWaterloggedPausesGrowth() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 1.3   // above tooWet 1.0; drains to 1.0 after (1.3-1.0)/0.55 = 0.545 day
        // window 0.5 day < 0.545 → waterlogged the whole time → no growth
        let out = GrowthEngine.reconcile(s, to: day(0, hour: 21), species: SpeciesCatalog.marigold)
        XCTAssertEqual(out.progress, 0, accuracy: 0.003)
    }

    func testWaterloggedThenResumes() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 1.3
        // over 2 days: paused 0.545 day, then healthy until dry: (1.0-0.2)/0.55 = 1.454 day
        let out = GrowthEngine.reconcile(s, to: day(2), species: SpeciesCatalog.marigold)
        XCTAssertEqual(out.progress, 1.454 / 7, accuracy: 0.02)
    }
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd SsakCore && swift test --filter ReconcileOverwaterTests`
Expected: PASS. If it FAILS, the waterlogged-pause branch in `reconcile` is wrong — fix it.

- [ ] **Step 3: Commit**

```bash
git add SsakCore && git commit -m "test(core): overwatering pauses then resumes growth"
```

---

## Task 8: Watering — moisture, streak, and clearing nursing

**Files:**
- Modify: `SsakCore/Sources/SsakCore/GrowthEngine.swift` (add `water`)
- Test: `SsakCore/Tests/SsakCoreTests/WateringTests.swift`

**Interfaces:**
- Produces: `GrowthEngine.water(_ state: PlantState, at now: Date, species: Species, tuning: GrowthTuning = .default, calendar: Calendar = .current) -> PlantState`. Reconciles to `now` first, then raises moisture (capped at `moistureMax`), updates the day-streak, stamps `lastWateredAt = now`, and clears `isNursing`.

- [ ] **Step 1: Write the failing test**

`SsakCore/Tests/SsakCoreTests/WateringTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class WateringTests: XCTestCase {
    func testWaterRaisesMoistureCappedAtMax() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.moisture = 1.0
        let out = GrowthEngine.water(s, at: day(0), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertEqual(out.moisture, 1.3, accuracy: 0.001)  // 1.0 + 0.6, capped at moistureMax 1.3
    }

    func testStreakConsecutiveSameGap() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))   // streak 1
        s = GrowthEngine.water(s, at: day(1), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertEqual(s.streak, 2)                                        // next day
        s = GrowthEngine.water(s, at: day(1, hour: 20), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertEqual(s.streak, 2)                                        // same day → unchanged
        s = GrowthEngine.water(s, at: day(4), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertEqual(s.streak, 1)                                        // gap → reset
    }

    func testWateringClearsNursing() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.isNursing = true
        let out = GrowthEngine.water(s, at: day(1), species: SpeciesCatalog.marigold, calendar: utcCal)
        XCTAssertFalse(out.isNursing)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd SsakCore && swift test --filter WateringTests`
Expected: FAIL (water undefined).

- [ ] **Step 3: Write minimal implementation**

Add to `GrowthEngine`:
```swift
    public static func water(_ state: PlantState, at now: Date, species: Species,
                             tuning t: GrowthTuning = .default,
                             calendar: Calendar = .current) -> PlantState {
        var out = reconcile(state, to: now, species: species, tuning: t)

        if let last = out.lastWateredAt {
            let from = calendar.startOfDay(for: last)
            let to = calendar.startOfDay(for: now)
            let dayDelta = calendar.dateComponents([.day], from: from, to: to).day ?? 0
            switch dayDelta {
            case 0:  break               // already counted today
            case 1:  out.streak += 1     // consecutive day
            default: out.streak = 1      // gap (or backwards) resets
            }
        } else {
            out.streak = 1
        }

        out.moisture = min(t.moistureMax, out.moisture + t.waterAmount)
        out.lastWateredAt = now
        out.isNursing = false
        return out
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd SsakCore && swift test --filter WateringTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SsakCore && git commit -m "feat(core): watering raises moisture, updates streak, clears nursing"
```

---

## Task 9: Reconcile — wilt setback after prolonged neglect

**Files:**
- Modify: `SsakCore/Sources/SsakCore/GrowthEngine.swift` (extend `reconcile` with wilt logic)
- Test: `SsakCore/Tests/SsakCoreTests/WiltTests.swift`

**Interfaces:**
- Consumes/extends: `GrowthEngine.reconcile`. New rule: if not already nursing, the plant has been un-watered for ≥ `wiltAfterDryDays` (measured from `lastWateredAt ?? plantedAt`), and it ends the interval dry (`moisture < dryThreshold`), then it wilts — regress to the start of the **previous** stage and set `isNursing = true`. (v1 simplification: wilt is triggered by dry neglect only; overwatering causes stalls but not wilt. `ponytail: dry-neglect wilt only; add overwater-wilt later if it matters.`)

- [ ] **Step 1: Write the failing test**

`SsakCore/Tests/SsakCoreTests/WiltTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class WiltTests: XCTestCase {
    func testProlongedNeglectWiltsBackOneStage() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.5                 // mid "leaves" stage
        s.moisture = 0.1                 // already dry
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(5), species: SpeciesCatalog.marigold)  // 5 days unwatered ≥ 4
        XCTAssertTrue(out.isNursing)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .sprout)  // leaves → sprout
    }

    func testShortNeglectDoesNotWilt() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.5
        s.moisture = 0.1
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(2), species: SpeciesCatalog.marigold)  // 2 days < 4
        XCTAssertFalse(out.isNursing)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .leaves)  // unchanged
    }

    func testWiltNeverTakesProgressBelowSeed() {
        var s = GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0))
        s.progress = 0.05                // seed stage
        s.moisture = 0.0
        s.lastWateredAt = day(0)
        let out = GrowthEngine.reconcile(s, to: day(6), species: SpeciesCatalog.marigold)
        XCTAssertGreaterThanOrEqual(out.progress, 0)
        XCTAssertEqual(GrowthEngine.stage(forProgress: out.progress), .seed)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd SsakCore && swift test --filter WiltTests`
Expected: FAIL (no wilt logic yet — `isNursing` stays false).

- [ ] **Step 3: Write minimal implementation**

In `reconcile`, replace the final `return out` with wilt handling appended just before it:
```swift
        // Wilt setback: prolonged dry neglect regresses one stage (never below seed).
        let neglectRef = state.lastWateredAt ?? state.plantedAt
        let unwateredDays = now.timeIntervalSince(neglectRef) / 86400.0
        if !state.isNursing, unwateredDays >= t.wiltAfterDryDays, out.moisture < t.dryThreshold {
            let current = stage(forProgress: out.progress)
            if let prev = current.previous {
                out.progress = progressAtStartOf(prev)
                out.isNursing = true
            }
        }
        return out
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd SsakCore && swift test --filter WiltTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SsakCore && git commit -m "feat(core): wilt setback after prolonged dry neglect (recoverable)"
```

---

## Task 10: Persistence — GameState save/load

**Files:**
- Create: `SsakCore/Sources/SsakCore/GameState.swift`
- Create: `SsakCore/Sources/SsakCore/PlantStore.swift`
- Test: `SsakCore/Tests/SsakCoreTests/PersistenceTests.swift`

**Interfaces:**
- Produces:
  - `struct GameState: Codable, Equatable { var plant: PlantState; var collected: [String] }`
  - `struct PlantStore { init(url: URL? = nil); func save(_ state: GameState) throws; func load() -> GameState? }` — default URL is `ssak.json` in the documents directory; `load()` returns `nil` on a missing/corrupt file.

- [ ] **Step 1: Write the failing test**

`SsakCore/Tests/SsakCoreTests/PersistenceTests.swift`:
```swift
import XCTest
@testable import SsakCore

final class PersistenceTests: XCTestCase {
    func testSaveLoadRoundTrip() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ssak-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tmp) }

        let store = PlantStore(url: tmp)
        let state = GameState(plant: GrowthEngine.plant(SpeciesCatalog.marigold, at: day(0)),
                              collected: ["cosmos", "zinnia"])
        try store.save(state)

        XCTAssertEqual(store.load(), state)
    }

    func testLoadMissingFileReturnsNil() {
        let store = PlantStore(url: URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).json"))
        XCTAssertNil(store.load())
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd SsakCore && swift test --filter PersistenceTests`
Expected: FAIL (GameState / PlantStore undefined).

- [ ] **Step 3: Write minimal implementation**

`SsakCore/Sources/SsakCore/GameState.swift`:
```swift
import Foundation

public struct GameState: Codable, Equatable {
    public var plant: PlantState
    public var collected: [String]   // species ids pressed to the shelf

    public init(plant: PlantState, collected: [String]) {
        self.plant = plant; self.collected = collected
    }
}
```

`SsakCore/Sources/SsakCore/PlantStore.swift`:
```swift
import Foundation

public struct PlantStore {
    public let url: URL

    public init(url: URL? = nil) {
        self.url = url ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ssak.json")
    }

    public func save(_ state: GameState) throws {
        let data = try JSONEncoder().encode(state)
        try data.write(to: url, options: .atomic)
    }

    public func load() -> GameState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(GameState.self, from: data)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd SsakCore && swift test --filter PersistenceTests`
Expected: PASS.

- [ ] **Step 5: Full suite green + commit**

Run: `cd SsakCore && swift test`
Expected: PASS (all tasks' tests).

```bash
git add SsakCore && git commit -m "feat(core): GameState persistence (save/load JSON)"
```

---

## Self-review (spec coverage)

- **Growth model (spec §3):** Tasks 2, 5, 6, 7 — stages, healthy accrual, dry pause, waterlogged pause. ✓
- **Moisture/health & overwater (spec §3.1):** Tasks 4, 5, 7, 8 — tuning band, drain, cap, waterlogged stall. ✓
- **Wilt setback, recoverable, shelf-safe (spec §3.1):** Task 9 (regress-only, never below seed; shelf lives in `GameState.collected`, untouched by plant reconciliation). ✓
- **Streak (spec §3.2):** Task 8 — +1 consecutive, unchanged same day, reset on gap. ✓ (glow threshold `glowStreak` exposed for the UI plan.)
- **Species & pacing (spec §4):** Task 3 — six flowers, marigold starter/fastest, pacing order. ✓
- **Persistence (spec §8):** Task 10 — `GameState` (plant + collected) round-trips. ✓
- **Archive & rename (spec §12):** Task 0. ✓
- **Testing (spec §9):** every rule has a discriminating test asserting state transitions from injected time — no wall-clock, no incidental behavior. ✓
- **Deferred to later plans:** the seed-chooser flow, bloom→press→collect transitions, and time-of-day petal state (morning glory) are UI/interaction concerns for Plan 3; `SsakCore` gives them the primitives (`plant`, `stage`, `GameState.collected`). Not a gap.

**Not in this plan (by design):** all SwiftUI, all art, the share export, onboarding — Plans 2 and 3.
