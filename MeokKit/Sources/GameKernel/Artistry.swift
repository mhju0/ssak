import Foundation

/// A brush technique that widens the stroke vocabulary as Artistry levels
/// (docs/design/unlock-tables.md §4). Crafted brushes unlock more at M5+.
public enum Technique: String, Sendable, CaseIterable {
    case wetWash, dryBrush, pooling, mist
}

/// A painting composition — a framed scene of one zone (spec §2 Artistry). The
/// live WorldConditions bake in at paint time, so the same frame in rain vs.
/// snow is a different collectible work.
public struct Composition: Identifiable, Equatable, Sendable {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    public let unlockLevel: Int
    /// The zone this frame depicts.
    public let zone: Zone
    /// Artistry XP for completing the painting.
    public let xp: Int

    public init(
        id: String, nameEN: String, nameKO: String,
        unlockLevel: Int, zone: Zone, xp: Int
    ) {
        self.id = id
        self.nameEN = nameEN
        self.nameKO = nameKO
        self.unlockLevel = unlockLevel
        self.zone = zone
        self.xp = xp
    }
}

/// The Artistry skill (spec §2, the signature skill): five framed compositions
/// unlocked by level, techniques that deepen the brush, and the red seal at 90.
public enum Artistry {
    /// One frame per zone (docs/design/unlock-tables.md §4).
    public static let compositions: [Composition] = [
        Composition(id: "pond-vista", nameEN: "The pond vista", nameKO: "못가 풍경",
                    unlockLevel: 1, zone: .valleyPond, xp: 80),
        Composition(id: "hermitage", nameEN: "The hermitage", nameKO: "은자의 집",
                    unlockLevel: 10, zone: .hermitage, xp: 100),
        Composition(id: "peak", nameEN: "The peak", nameKO: "봉우리",
                    unlockLevel: 30, zone: .peak, xp: 130),
        Composition(id: "forest", nameEN: "The forest", nameKO: "숲",
                    unlockLevel: 60, zone: .forest, xp: 160),
        Composition(id: "terrace", nameEN: "The terrace", nameKO: "뜰",
                    unlockLevel: 80, zone: .gardenTerrace, xp: 190),
    ]

    public static func available(level: Int) -> [Composition] {
        compositions.filter { level >= $0.unlockLevel }
    }

    public static func composition(id: String) -> Composition? {
        compositions.first { $0.id == id }
    }

    /// Techniques unlock along the curve (spec §4): wet-wash 20, dry-brush 40,
    /// pooling 50, mist 70.
    public static func techniques(level: Int) -> Set<Technique> {
        var unlocked: Set<Technique> = []
        if level >= 20 { unlocked.insert(.wetWash) }
        if level >= 40 { unlocked.insert(.dryBrush) }
        if level >= 50 { unlocked.insert(.pooling) }
        if level >= 70 { unlocked.insert(.mist) }
        return unlocked
    }

    /// The red seal (낙관) is earned at 90 — the game's only color (spec §2).
    public static func sealEarned(level: Int) -> Bool { level >= 90 }
}
