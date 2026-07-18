import Foundation

/// What the real sky has strewn across the path.
public enum Litter: String, Sendable {
    case leaves, snow
}

/// Sweeping is a ritual, not a skill (spec §2): the sky litters the path, a
/// finger-swipe clears it, and only *new* weather re-litters — never mere
/// time. This pure function is the "new weather" test; the swept state lives
/// in the view layer (a persisted litter kind), so clearing survives sessions
/// and re-appears only when the litter kind changes.
public enum Sweeping {
    public static func litter(
        for conditions: WorldConditions, windThreshold: Double = 5
    ) -> Litter? {
        if conditions.weather == .snow { return .snow }
        if conditions.season == .autumn || conditions.windSpeed >= windThreshold { return .leaves }
        return nil
    }
}
