import Foundation

/// A crop or tree the player can plant (docs/design/unlock-tables.md §4).
/// Planting is level-gated; growth is then a pure function of real elapsed
/// days — no seasons, no weather, no chores (spec §2, pillar 2).
public struct Plantable: Identifiable, Equatable, Sendable {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    public let unlockLevel: Int
    /// Trees persist forever as scenery; crops are harvested at maturity.
    public let isTree: Bool
    /// Real days from planting to maturity.
    public let daysToMature: Double
    /// XP granted at the yield — a crop's harvest, or a tree's planting.
    public let xp: Int
    /// Stroke-recipe archetype (StrokeEngine recipe key).
    public let archetype: String

    public init(
        id: String, nameEN: String, nameKO: String, unlockLevel: Int,
        isTree: Bool, daysToMature: Double, xp: Int, archetype: String
    ) {
        self.id = id
        self.nameEN = nameEN
        self.nameKO = nameKO
        self.unlockLevel = unlockLevel
        self.isTree = isTree
        self.daysToMature = daysToMature
        self.xp = xp
        self.archetype = archetype
    }
}

/// A plant's visible growth stage — monotonic in elapsed days.
public enum GrowthStage: Int, Comparable, Sendable {
    case seed, sprout, young, mature, ancient
    public static func < (lhs: GrowthStage, rhs: GrowthStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Gardening growth: pure functions of real elapsed days. Watering and weather
/// are deliberately *not* parameters — nothing can pause, wither, or reverse a
/// crop; watering only adds delight (a bonus XP tick), never obligation.
public enum Garden {
    public static func stage(plantedDays: Double, _ plantable: Plantable) -> GrowthStage {
        let progress = max(0, plantedDays) / plantable.daysToMature
        switch progress {
        case ..<0.15: return .seed
        case ..<0.45: return .sprout
        case ..<0.85: return .young
        case ..<2.0: return .mature
        default: return plantable.isTree ? .ancient : .mature
        }
    }

    /// A crop is ready to harvest at maturity; trees are never harvested —
    /// they are the forest the player grows.
    public static func isReady(plantedDays: Double, _ plantable: Plantable) -> Bool {
        !plantable.isTree && plantedDays >= plantable.daysToMature
    }

    /// Growth toward maturity, clamped 0…1 — for a progress bar.
    public static func progress(plantedDays: Double, _ plantable: Plantable) -> Double {
        min(1, max(0, plantedDays) / plantable.daysToMature)
    }
}

/// The gardening skill's plantables (level unlocks, never gates fun).
public enum Gardening {
    public static func available(level: Int) -> [Plantable] {
        GardenTable.all.filter { level >= $0.unlockLevel }
    }

    public static func plantable(id: String) -> Plantable? {
        GardenTable.all.first { $0.id == id }
    }
}

/// The 6 M3 rows, verbatim from docs/design/unlock-tables.md §4. Trees mature
/// slowly — the old ginkgo is the four-month centerpiece.
public enum GardenTable {
    public static let all: [Plantable] = [
        Plantable(
            id: "radish", nameEN: "Radish", nameKO: "무",
            unlockLevel: 1, isTree: false, daysToMature: 3, xp: 50, archetype: "radish"),
        Plantable(
            id: "cabbage", nameEN: "Napa cabbage", nameKO: "배추",
            unlockLevel: 10, isTree: false, daysToMature: 5, xp: 70, archetype: "cabbage"),
        Plantable(
            id: "plum-tree", nameEN: "Plum tree", nameKO: "매화나무",
            unlockLevel: 30, isTree: true, daysToMature: 30, xp: 120, archetype: "tree-plum"),
        Plantable(
            id: "pine-tree", nameEN: "Pine tree", nameKO: "소나무",
            unlockLevel: 50, isTree: true, daysToMature: 45, xp: 140, archetype: "tree-pine"),
        Plantable(
            id: "persimmon-tree", nameEN: "Persimmon tree", nameKO: "감나무",
            unlockLevel: 70, isTree: true, daysToMature: 60, xp: 160, archetype: "tree-persimmon"),
        Plantable(
            id: "old-ginkgo", nameEN: "Old ginkgo", nameKO: "은행나무",
            unlockLevel: 90, isTree: true, daysToMature: 120, xp: 250, archetype: "tree-ginkgo"),
    ]
}
