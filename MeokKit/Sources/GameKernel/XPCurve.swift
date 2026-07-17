import Foundation

/// The six crafts of the hermitage (spec §2).
public enum Skill: String, CaseIterable, Codable, Sendable {
    case fishing, foraging, gardening, cooking, crafting, artistry
}

/// One leveling curve shared by all six skills. Constants are pinned in
/// docs/design/unlock-tables.md §1: gentle exponential to 89, steep tail
/// 90–98, continuous at the seam; ~91k XP ≈ 15.2 h per skill at the
/// 100 XP/min reference rate.
public enum XPCurve {
    public static let maxLevel = 99

    /// XP to advance from `level` to `level + 1` (0 at the cap).
    public static func cost(toLeaveLevel level: Int) -> Int {
        precondition(level >= 1)
        guard level < maxLevel else { return 0 }
        return level < 90
            ? Int((250 * pow(1.018, Double(level - 1))).rounded())
            : Int((1210 * pow(1.29, Double(level - 90))).rounded())
    }

    /// Total XP at which `level` begins; level 1 begins at 0.
    public static func xpForLevel(_ level: Int) -> Int {
        (1..<level).reduce(0) { $0 + cost(toLeaveLevel: $1) }
    }

    /// The level a lifetime XP total has earned, capped at 99.
    public static func level(forXP xp: Int) -> Int {
        var level = 1
        var remaining = xp
        while level < maxLevel {
            let cost = cost(toLeaveLevel: level)
            if remaining < cost { break }
            remaining -= cost
            level += 1
        }
        return level
    }
}
