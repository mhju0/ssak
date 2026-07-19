import Foundation

public enum GrowthStage: String, Codable, CaseIterable, Comparable {
    case seed, sprout, leaves, bud, bloom

    private var order: Int { Self.allCases.firstIndex(of: self)! }
    public static func < (a: GrowthStage, b: GrowthStage) -> Bool { a.order < b.order }

    public var previous: GrowthStage? {
        order > 0 ? Self.allCases[order - 1] : nil
    }
}
