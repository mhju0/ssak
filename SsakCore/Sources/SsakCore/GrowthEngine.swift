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

    public static func plant(_ species: Species, at now: Date) -> PlantState {
        PlantState(speciesID: species.id, progress: 0, moisture: 0.6,
                   lastUpdate: now, lastWateredAt: now, streak: 1,
                   isNursing: false, plantedAt: now)
    }

    public static func hasWateredToday(_ state: PlantState, now: Date,
                                       calendar: Calendar = .current) -> Bool {
        guard let last = state.lastWateredAt else { return false }
        return calendar.isDate(last, inSameDayAs: now)
    }
}
