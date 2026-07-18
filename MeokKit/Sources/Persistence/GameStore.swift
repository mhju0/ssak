import Foundation
import SwiftData
import GameKernel

/// Lifetime XP for one skill. XP is monotonic — rows only ever grow
/// (the invariant the v1.1 iCloud merge design leans on).
/// Note: `.unique` is incompatible with SwiftData's CloudKit mirroring —
/// fine at v1 (local-only by spec §4); the v1.1 sync design replaces this
/// model shape anyway (append-only events or per-device rows).
@Model
public final class SkillProgress {
    @Attribute(.unique) public var skillID: String
    public var xp: Int

    public init(skillID: String, xp: Int = 0) {
        self.skillID = skillID
        self.xp = xp
    }
}

/// Collection state for one species. Variant sets are the weather
/// dimension only (spec §2), stored as raw values for schema stability.
@Model
public final class SpeciesRecord {
    @Attribute(.unique) public var speciesID: String
    public var timesCaught: Int
    public var caughtWeathers: [String]
    public var paintedWeathers: [String]
    /// The shadow "one that got away" flag — collection intel, not failure.
    public var gotAway: Bool

    public init(speciesID: String) {
        self.speciesID = speciesID
        timesCaught = 0
        caughtWeathers = []
        paintedWeathers = []
        gotAway = false
    }
}

/// One thing growing in a garden bed. Growth is derived from `plantedAt` vs
/// now — never stored, so it can't drift or regress (spec §2, pillar 2).
/// Trees are planted forever; crops are removed when harvested.
@Model
public final class Planting {
    public var plantableID: String
    public var plantedAt: Date
    public var bedIndex: Int
    /// Last hand/rain watering — bounds the bonus tick to once per real day.
    public var lastWatered: Date?

    public init(plantableID: String, plantedAt: Date, bedIndex: Int) {
        self.plantableID = plantableID
        self.plantedAt = plantedAt
        self.bedIndex = bedIndex
        lastWatered = nil
    }

    public func daysGrown(now: Date) -> Double {
        max(0, now.timeIntervalSince(plantedAt)) / 86_400
    }

    /// Watered at most once per real day — a delight, never an obligation.
    public func canWater(now: Date) -> Bool {
        guard let lastWatered else { return true }
        return now.timeIntervalSince(lastWatered) >= 20 * 3_600
    }
}

/// What one haul did to the ledgers — an activity view's payoff line. Shared
/// by fishing catches and foraging finds (spec §2: "haul feeds crafting").
public struct HaulOutcome: Equatable, Sendable {
    public let xpAwarded: Int
    public let totalXP: Int
    public let level: Int
    public let leveledUp: Bool
    public let firstOfSpecies: Bool
    public let newWeatherVariant: Bool
}

/// What a gardening act (plant / water / harvest) gave — the garden's payoff.
public struct GrowthReward: Equatable, Sendable {
    public let xpAwarded: Int
    public let level: Int
    public let leveledUp: Bool
}

/// The one door to the save file. All game writes go through here so the
/// XP-monotonic and variant-set rules live in exactly one place.
@MainActor
public final class GameStore {
    public let context: ModelContext

    public init(container: ModelContainer) {
        context = ModelContext(container)
    }

    /// The app's on-disk store.
    public static func live() throws -> GameStore {
        try GameStore(container: ModelContainer(
            for: SkillProgress.self, SpeciesRecord.self, Planting.self))
    }

    /// Throwaway store for tests and previews.
    public static func inMemory() throws -> GameStore {
        try GameStore(container: ModelContainer(
            for: SkillProgress.self, SpeciesRecord.self, Planting.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    }

    public func progress(for skill: Skill) -> SkillProgress {
        let id = skill.rawValue
        var descriptor = FetchDescriptor<SkillProgress>(
            predicate: #Predicate { $0.skillID == id })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first { return existing }
        let fresh = SkillProgress(skillID: id)
        context.insert(fresh)
        return fresh
    }

    public func record(for speciesID: String) -> SpeciesRecord? {
        var descriptor = FetchDescriptor<SpeciesRecord>(
            predicate: #Predicate { $0.speciesID == speciesID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func recordCreatingIfNeeded(for speciesID: String) -> SpeciesRecord {
        if let existing = record(for: speciesID) { return existing }
        let fresh = SpeciesRecord(speciesID: speciesID)
        context.insert(fresh)
        return fresh
    }

    /// A landed fish: XP ticks, the ledger fills, variants accrue.
    public func record(
        catch species: FishSpecies, weather: WorldConditions.Weather
    ) -> HaulOutcome {
        award(.fishing, collectibleID: species.id, xp: species.xp, weather: weather)
    }

    /// A gathered forageable: the same ledger machinery, foraging XP.
    public func record(
        gather forageable: Forageable, weather: WorldConditions.Weather
    ) -> HaulOutcome {
        award(.foraging, collectibleID: forageable.id, xp: forageable.xp, weather: weather)
    }

    /// The one place XP ticks and a SpeciesRecord fills — shared by every
    /// gathering skill so the monotonic-XP and variant-set rules live once.
    private func award(
        _ skill: Skill, collectibleID: String, xp: Int, weather: WorldConditions.Weather
    ) -> HaulOutcome {
        let progress = progress(for: skill)
        let levelBefore = XPCurve.level(forXP: progress.xp)
        progress.xp += xp
        let levelAfter = XPCurve.level(forXP: progress.xp)

        let record = recordCreatingIfNeeded(for: collectibleID)
        let firstEver = record.timesCaught == 0
        record.timesCaught += 1
        let newVariant = !record.caughtWeathers.contains(weather.rawValue)
        if newVariant { record.caughtWeathers.append(weather.rawValue) }

        save()
        return HaulOutcome(
            xpAwarded: xp,
            totalXP: progress.xp,
            level: levelAfter,
            leveledUp: levelAfter > levelBefore,
            firstOfSpecies: firstEver,
            newWeatherVariant: newVariant)
    }

    /// A lost fish costs only the moment — and logs the silhouette.
    public func recordEscape(of species: FishSpecies) {
        recordCreatingIfNeeded(for: species.id).gotAway = true
        save()
    }

    // MARK: Gardening — growth is real days; watering is a bonus (spec §2)

    public func plantings() -> [Planting] {
        (try? context.fetch(FetchDescriptor<Planting>(
            sortBy: [SortDescriptor(\.bedIndex)]))) ?? []
    }

    /// Plant a crop or tree in a bed. A tree's yield is the planting itself
    /// (it stands forever); a crop yields later, at harvest.
    @discardableResult
    public func plant(_ plantable: Plantable, at bedIndex: Int, now: Date) -> Planting {
        let planting = Planting(plantableID: plantable.id, plantedAt: now, bedIndex: bedIndex)
        context.insert(planting)
        _ = addGardenXP(plantable.isTree ? plantable.xp : Self.plantXP)
        save()
        return planting
    }

    /// Harvest a ripe crop: its yield in XP, and the bed clears. Trees and
    /// unripe crops harvest nothing.
    public func harvest(_ planting: Planting, now: Date) -> GrowthReward? {
        guard let plantable = Gardening.plantable(id: planting.plantableID),
              Garden.isReady(plantedDays: planting.daysGrown(now: now), plantable)
        else { return nil }
        let reward = addGardenXP(plantable.xp)
        context.delete(planting)
        save()
        return reward
    }

    /// Water a plant by hand — a small XP tick, at most once per real day
    /// (real rain waters for free). Returns nil if already watered today.
    @discardableResult
    public func water(_ planting: Planting, now: Date) -> GrowthReward? {
        guard planting.canWater(now: now) else { return nil }
        planting.lastWatered = now
        let reward = addGardenXP(Self.waterXP)
        save()
        return reward
    }

    private static let plantXP = 15
    private static let waterXP = 10

    private func addGardenXP(_ xp: Int) -> GrowthReward {
        let progress = progress(for: .gardening)
        let before = XPCurve.level(forXP: progress.xp)
        progress.xp += xp
        let after = XPCurve.level(forXP: progress.xp)
        return GrowthReward(xpAwarded: xp, level: after, leveledUp: after > before)
    }

    /// A local-only save failing (disk full) is exceptional; the in-memory
    /// context stays authoritative for the session either way, but never
    /// swallow it silently — XP is supposed to be monotonic on disk too.
    private func save() {
        do {
            try context.save()
        } catch {
            assertionFailure("GameStore save failed: \(error)")
            print("GameStore save failed: \(error)")
        }
    }
}
