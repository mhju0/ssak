import Foundation

/// Open-Meteo current-weather provider (free, keyless; WeatherKit swaps in
/// behind WorldConditions at ~M7).
public enum OpenMeteo {
    struct Response: Decodable {
        struct Current: Decodable {
            var precipitation: Double
            var weather_code: Int
            var wind_speed_10m: Double
        }
        var latitude: Double
        var longitude: Double
        var utc_offset_seconds: Int
        var current: Current
    }

    /// Maps a raw Open-Meteo response to WorldConditions. Time-of-day and
    /// darkness come from the real sun at the response's own coordinates;
    /// season from the month in the response's UTC offset.
    public static func conditions(fromJSON data: Data, now: Date = .now) throws -> WorldConditions {
        let response = try JSONDecoder().decode(Response.self, from: data)
        let current = response.current

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: response.utc_offset_seconds) ?? .current

        return WorldConditions(
            weather: weather(fromWMOCode: current.weather_code),
            precipitation: current.precipitation,
            windSpeed: current.wind_speed_10m,
            timeOfDay: Solar.timeOfDay(
                date: now, latitude: response.latitude, longitude: response.longitude),
            season: season(
                month: calendar.component(.month, from: now), latitude: response.latitude),
            darkness: Solar.darkness(
                date: now, latitude: response.latitude, longitude: response.longitude)
        )
    }

    static func weather(fromWMOCode code: Int) -> WorldConditions.Weather {
        switch code {
        case 0, 1: .clear
        case 45, 48: .fog
        case 51...67, 80...82: .rain
        case 71...77, 85, 86: .snow
        case 95...99: .storm
        default: .cloudy
        }
    }

    static func timeOfDay(hour: Int) -> WorldConditions.TimeOfDay {
        switch hour {
        case 5...7: .dawn
        case 8...16: .day
        case 17...19: .dusk
        default: .night
        }
    }

    /// Meteorological seasons, hemisphere-aware: July is summer in Seoul
    /// and winter in Sydney.
    static func season(month: Int, latitude: Double = 90) -> WorldConditions.Season {
        let shifted = latitude < 0 ? (month + 5) % 12 + 1 : month
        return switch shifted {
        case 3...5: .spring
        case 6...8: .summer
        case 9...11: .autumn
        default: .winter
        }
    }
}
