import Foundation

/// Rarity tier shared by every condition-gated collectible (fish, forageables).
/// Rarity also derives from reality's own rarity — a storm night is rare by
/// itself, so its species need not be heavily down-weighted.
public enum Tier: String, Sendable {
    case baseline, uncommon, rare, apex
}

/// Anything the world offers on a (season × time-of-day × weather) key, gated
/// by skill level. The spec's "one engine" (§2: all six skills share
/// condition-gated activities) — fish and forageables are both `ConditionGated`,
/// and the draw below is the single shared implementation.
public protocol ConditionGated {
    var seasons: Set<WorldConditions.Season> { get }
    var timesOfDay: Set<WorldConditions.TimeOfDay> { get }
    var weathers: Set<WorldConditions.Weather> { get }
    var unlockLevel: Int { get }
    /// Relative spawn weight among currently eligible peers.
    var weight: Int { get }
}

public extension ConditionGated {
    /// Level unlocks; the sky gates presence. The two never cross (spec §2).
    func isEligible(_ conditions: WorldConditions, level: Int) -> Bool {
        level >= unlockLevel
            && seasons.contains(conditions.season)
            && timesOfDay.contains(conditions.timeOfDay)
            && weathers.contains(conditions.weather)
    }
}

/// The shared content draw: what's eligible right now, and a seeded weighted
/// pick over the eligible pool. Every gathering skill routes through here.
public enum ConditionDraw {
    public static func eligible<T: ConditionGated>(
        _ table: [T], _ conditions: WorldConditions, level: Int
    ) -> [T] {
        table.filter { $0.isEligible(conditions, level: level) }
    }

    /// Weighted pick by `weight`; nil for an empty pool.
    public static func weightedPick<T: ConditionGated, R: RandomNumberGenerator>(
        from pool: [T], using rng: inout R
    ) -> T? {
        weightedPick(from: pool, weight: { $0.weight }, using: &rng)
    }

    /// Weighted pick with a per-element weight override — e.g. a better rod
    /// boosting rare species. Consumes exactly one draw, like the default.
    public static func weightedPick<T: ConditionGated, R: RandomNumberGenerator>(
        from pool: [T], weight: (T) -> Int, using rng: inout R
    ) -> T? {
        let total = pool.reduce(0) { $0 + weight($1) }
        guard total > 0 else { return pool.first }
        var pick = Int.random(in: 0..<total, using: &rng)
        for candidate in pool {
            let candidateWeight = weight(candidate)
            if pick < candidateWeight { return candidate }
            pick -= candidateWeight
        }
        return pool.last
    }
}

/// Deterministic RNG for kernel draws (SplitMix64) — seedable so the same sky
/// and seed replay the same session. Shared by every skill's draw.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
