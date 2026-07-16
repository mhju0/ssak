import Foundation

/// The one value the world runs on: the player's real sky, reduced to what
/// the renderer and condition engine consume.
public struct WorldConditions: Codable, Equatable, Sendable {
    public enum Weather: String, Codable, Sendable {
        case clear, cloudy, fog, rain, snow, storm
    }

    public enum TimeOfDay: String, Codable, Sendable {
        case night, dawn, day, dusk
    }

    public enum Season: String, Codable, Sendable {
        case spring, summer, autumn, winter
    }

    public var weather: Weather
    /// Precipitation over the last hour, mm.
    public var precipitation: Double
    /// Wind speed, m/s.
    public var windSpeed: Double
    public var timeOfDay: TimeOfDay
    public var season: Season

    /// How hard the ink should run, 0…1. Perceptual sqrt curve where
    /// 8 mm/h ≈ downpour. Driven by measured precipitation regardless of
    /// the sky code (rain that just stopped still wets the paper) — except
    /// snow, which reserves paper white instead of running the ink.
    public var rainIntensity: Double {
        guard weather != .snow else { return 0 }
        return min(1, (precipitation / 8).squareRoot())
    }

    public init(
        weather: Weather,
        precipitation: Double,
        windSpeed: Double,
        timeOfDay: TimeOfDay,
        season: Season
    ) {
        self.weather = weather
        self.precipitation = precipitation
        self.windSpeed = windSpeed
        self.timeOfDay = timeOfDay
        self.season = season
    }
}
