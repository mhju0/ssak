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
