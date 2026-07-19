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

    public static func reconcile(_ state: PlantState, to now: Date, species: Species,
                                 tuning t: GrowthTuning = .default) -> PlantState {
        var out = state
        let elapsed = now.timeIntervalSince(state.lastUpdate) / 86400.0  // days
        guard elapsed > 0 else { out.lastUpdate = now; return out }

        let startM = state.moisture
        let drain = t.drainPerDay

        var healthyDuration = 0.0
        if startM >= t.dryThreshold {
            // paused while waterlogged at the start of the window
            let wetPause = startM > t.tooWetThreshold ? (startM - t.tooWetThreshold) / drain : 0
            let healthyStart = min(wetPause, elapsed)
            let moistureAtStart = startM - drain * healthyStart
            let timeUntilDry = max(0, (moistureAtStart - t.dryThreshold) / drain)
            healthyDuration = max(0, min(elapsed, healthyStart + timeUntilDry) - healthyStart)
        }
        // startM < dryThreshold → dry the whole window → no growth

        out.progress = min(1.0, state.progress + healthyDuration / species.bloomDays)
        out.moisture = max(0, startM - drain * elapsed)
        out.lastUpdate = now
        return out
    }
}
