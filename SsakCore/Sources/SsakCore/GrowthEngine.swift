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

    // Note: reconcile deliberately does NOT reset `streak` on a missed day. Spec §3.2's
    // "resets on a missed day" is derived at the streak's consumer (glow/share, Plan 3)
    // from `lastWateredAt` — like `hasWateredToday` — so the persisted counter can briefly
    // overstate after neglect until the next water() re-bases it. Penalty-free by design
    // (D12); no calendar param needed here. ponytail: derive effective streak in UI.
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
            let timeUntilDry: Double
            if drain == 0 {
                timeUntilDry = moistureAtStart > t.dryThreshold ? .infinity : 0
            } else {
                timeUntilDry = max(0, (moistureAtStart - t.dryThreshold) / drain)
            }
            healthyDuration = max(0, min(elapsed, healthyStart + timeUntilDry) - healthyStart)
        }
        // startM < dryThreshold → dry the whole window → no growth

        out.progress = min(1.0, state.progress + healthyDuration / species.bloomDays)
        out.moisture = max(0, startM - drain * elapsed)
        out.lastUpdate = now

        // Wilt setback: prolonged dry neglect regresses one stage (never below seed).
        let neglectRef = state.lastWateredAt ?? state.plantedAt
        let unwateredDays = now.timeIntervalSince(neglectRef) / 86400.0
        if !state.isNursing, unwateredDays >= t.wiltAfterDryDays, out.moisture < t.dryThreshold {
            let current = stage(forProgress: out.progress)
            if let prev = current.previous {
                out.progress = progressAtStartOf(prev)
                out.isNursing = true
            }
        }
        return out
    }

    public static func water(_ state: PlantState, at now: Date, species: Species,
                             tuning t: GrowthTuning = .default,
                             calendar: Calendar = .current) -> PlantState {
        var out = reconcile(state, to: now, species: species, tuning: t)

        if let last = out.lastWateredAt {
            let from = calendar.startOfDay(for: last)
            let to = calendar.startOfDay(for: now)
            let dayDelta = calendar.dateComponents([.day], from: from, to: to).day ?? 0
            switch dayDelta {
            case 0:  break               // already counted today
            case 1:  out.streak += 1     // consecutive day
            default: out.streak = 1      // gap (or backwards) resets
            }
        } else {
            out.streak = 1
        }

        out.moisture = min(t.moistureMax, out.moisture + t.waterAmount)
        out.lastWateredAt = now
        out.isNursing = false
        return out
    }
}
