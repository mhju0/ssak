import Foundation

/// A forageable found while wandering the scroll (spec §2 Foraging), from
/// docs/design/unlock-tables.md §4. Condition-gated like a fish, but gathered
/// on sight — no bite, no fight. `weathers` is also its weather-variant set.
public struct Forageable: Identifiable, Equatable, Sendable, ConditionGated {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    public let tier: Tier
    public let unlockLevel: Int
    public let seasons: Set<WorldConditions.Season>
    public let timesOfDay: Set<WorldConditions.TimeOfDay>
    public let weathers: Set<WorldConditions.Weather>
    public let xp: Int
    /// Relative spawn weight among currently eligible forageables.
    public let weight: Int
    /// Stroke-recipe archetype (StrokeEngine recipe key).
    public let archetype: String

    public init(
        id: String, nameEN: String, nameKO: String, tier: Tier, unlockLevel: Int,
        seasons: Set<WorldConditions.Season>, timesOfDay: Set<WorldConditions.TimeOfDay>,
        weathers: Set<WorldConditions.Weather>, xp: Int, weight: Int, archetype: String
    ) {
        self.id = id
        self.nameEN = nameEN
        self.nameKO = nameKO
        self.tier = tier
        self.unlockLevel = unlockLevel
        self.seasons = seasons
        self.timesOfDay = timesOfDay
        self.weathers = weathers
        self.xp = xp
        self.weight = weight
        self.archetype = archetype
    }
}

/// The foraging gathering skill: what the scroll offers to gather right now.
public enum Foraging {
    public static func available(_ conditions: WorldConditions, level: Int) -> [Forageable] {
        ConditionDraw.eligible(ForagingTable.all, conditions, level: level)
    }

    /// One weighted find for a spot on the scroll — seeded, deterministic.
    public static func spot<R: RandomNumberGenerator>(
        _ conditions: WorldConditions, level: Int, using rng: inout R
    ) -> Forageable? {
        ConditionDraw.weightedPick(from: available(conditions, level: level), using: &rng)
    }
}

/// The 8 M3 rows, verbatim from docs/design/unlock-tables.md §4. Mugwort and
/// shepherd's purse are the all-conditions baselines that carry the two-currency
/// coverage invariant (every sky yields a level-1 forage).
public enum ForagingTable {
    private static let allSeasons = Set(WorldConditions.Season.allCases)
    private static let allTimes = Set(WorldConditions.TimeOfDay.allCases)
    private static let allWeathers = Set(WorldConditions.Weather.allCases)

    public static let all: [Forageable] = [
        Forageable(
            id: "mugwort", nameEN: "Mugwort", nameKO: "쑥",
            tier: .baseline, unlockLevel: 1,
            seasons: allSeasons, timesOfDay: allTimes, weathers: allWeathers,
            xp: 40, weight: 100, archetype: "leafy"),
        Forageable(
            id: "shepherds-purse", nameEN: "Shepherd's purse", nameKO: "냉이",
            tier: .baseline, unlockLevel: 1,
            seasons: allSeasons, timesOfDay: allTimes, weathers: allWeathers,
            xp: 45, weight: 80, archetype: "leafy"),
        Forageable(
            id: "oyster-mushroom", nameEN: "Oyster mushroom", nameKO: "느타리",
            tier: .uncommon, unlockLevel: 10,
            seasons: [.spring, .summer, .autumn], timesOfDay: allTimes, weathers: allWeathers,
            xp: 70, weight: 45, archetype: "mushroom-cap"),
        Forageable(
            id: "moon-mushroom", nameEN: "Moon mushroom", nameKO: "달버섯",
            tier: .uncommon, unlockLevel: 20,
            seasons: [.summer, .autumn], timesOfDay: [.night], weathers: allWeathers,
            xp: 95, weight: 35, archetype: "mushroom-cap"),
        Forageable(
            id: "persimmon", nameEN: "Persimmon", nameKO: "감",
            tier: .uncommon, unlockLevel: 30,
            seasons: [.autumn], timesOfDay: [.day, .dusk], weathers: allWeathers,
            xp: 100, weight: 35, archetype: "fruit"),
        Forageable(
            id: "pine-nuts", nameEN: "Pine nuts", nameKO: "잣",
            tier: .uncommon, unlockLevel: 40,
            seasons: [.autumn, .winter], timesOfDay: allTimes, weathers: allWeathers,
            xp: 110, weight: 30, archetype: "fruit"),
        Forageable(
            id: "matsutake", nameEN: "Matsutake", nameKO: "송이",
            tier: .rare, unlockLevel: 60,
            seasons: [.autumn], timesOfDay: [.dawn, .day], weathers: [.clear, .cloudy, .fog],
            xp: 160, weight: 16, archetype: "mushroom-cap"),
        Forageable(
            id: "snow-lotus", nameEN: "Snow lotus", nameKO: "설련화",
            tier: .apex, unlockLevel: 90,
            seasons: [.winter], timesOfDay: allTimes, weathers: [.snow],
            xp: 250, weight: 8, archetype: "flower"),
    ]
}
