import Foundation
import SwiftData
import SkyState
import GameKernel

/// Lifetime XP for one skill. XP is monotonic — rows only ever grow
/// (the invariant the v1.1 iCloud merge design leans on).
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

/// What one catch did to the ledgers — the fishing view's payoff line.
public struct CatchOutcome: Equatable, Sendable {
    public let xpAwarded: Int
    public let totalXP: Int
    public let level: Int
    public let leveledUp: Bool
    public let firstCatchOfSpecies: Bool
    public let newWeatherVariant: Bool
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
            for: SkillProgress.self, SpeciesRecord.self))
    }

    /// Throwaway store for tests and previews.
    public static func inMemory() throws -> GameStore {
        try GameStore(container: ModelContainer(
            for: SkillProgress.self, SpeciesRecord.self,
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
    ) -> CatchOutcome {
        let progress = progress(for: .fishing)
        let levelBefore = XPCurve.level(forXP: progress.xp)
        progress.xp += species.xp
        let levelAfter = XPCurve.level(forXP: progress.xp)

        let record = recordCreatingIfNeeded(for: species.id)
        let firstCatch = record.timesCaught == 0
        record.timesCaught += 1
        let newVariant = !record.caughtWeathers.contains(weather.rawValue)
        if newVariant { record.caughtWeathers.append(weather.rawValue) }

        try? context.save()
        return CatchOutcome(
            xpAwarded: species.xp,
            totalXP: progress.xp,
            level: levelAfter,
            leveledUp: levelAfter > levelBefore,
            firstCatchOfSpecies: firstCatch,
            newWeatherVariant: newVariant)
    }

    /// A lost fish costs only the moment — and logs the silhouette.
    public func recordEscape(of species: FishSpecies) {
        recordCreatingIfNeeded(for: species.id).gotAway = true
        try? context.save()
    }
}
