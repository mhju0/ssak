import Foundation

/// Climate honesty (spec §2): completion is defined against what the
/// player's sky can produce. Köppen-derived per-city rows from
/// docs/design/unlock-tables.md §6. Pure functions — a city switch
/// "recomputes" for free.
public enum Climate {
    /// Weather values the city's sky can actually produce. Cities not in
    /// the table default to everything: missing data must never lock
    /// content. Keyed by preset-city name — when M7's live location adds
    /// arbitrary coordinates, unknown places fall to this generous default
    /// until a coordinate-keyed Köppen band lookup replaces the name key.
    public static func capability(of city: City) -> Set<WorldConditions.Weather> {
        snowless.contains(city.name)
            ? Set(WorldConditions.Weather.allCases).subtracting([.snow])
            : Set(WorldConditions.Weather.allCases)
    }

    /// A species is native when the city can produce at least one of its
    /// weather variants; otherwise the ledger shows the honest label and
    /// leaves it out of the completion denominator.
    public static func isNative(_ species: FishSpecies, to city: City) -> Bool {
        !species.weathers.isDisjoint(with: capability(of: city))
    }

    /// The only climate lock in the v1 city spread is snow.
    private static let snowless: Set<String> = [
        "Singapore", "Sydney", "Cairo", "San Francisco",
    ]
}
