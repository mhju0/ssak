import Foundation

/// Last-fetched conditions, persisted across launches.
public struct SkyCache {
    private static let key = "meok.sky.cached-conditions"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func save(_ conditions: WorldConditions) {
        defaults.set(try? JSONEncoder().encode(conditions), forKey: Self.key)
    }

    public func load() -> WorldConditions? {
        defaults.data(forKey: Self.key).flatMap {
            try? JSONDecoder().decode(WorldConditions.self, from: $0)
        }
    }
}

/// Fetches the real sky for the default city and always resolves to a value:
/// live fetch → cached → clear-sky default. Never blank, never an error.
public final class SkyStore: @unchecked Sendable {
    /// Seoul, the default city until the picker (#18) / location (M7) land.
    public static let seoulLatitude = 37.5665
    public static let seoulLongitude = 126.978
    public static let seoulURL = URL(string:
        "https://api.open-meteo.com/v1/forecast?latitude=37.5665&longitude=126.978"
        + "&current=precipitation,weather_code,wind_speed_10m&wind_speed_unit=ms&timezone=auto")!

    private let cache: SkyCache
    private let session: URLSession

    public init(defaults: UserDefaults = .standard, session: URLSession = .shared) {
        self.cache = SkyCache(defaults: defaults)
        self.session = session
    }

    /// The fallback ladder. Pure; the reason a sky always exists.
    /// Cached entries keep their weather but re-derive the sun (time-of-day,
    /// darkness) and season from the clock — a cache saved at night must not
    /// render night at noon.
    public static func resolve(
        fetched: WorldConditions?,
        cached: WorldConditions?,
        now: Date,
        timeZone: TimeZone
    ) -> WorldConditions {
        if let fetched { return fetched }
        guard var conditions = cached else {
            return clearDefault(now: now, timeZone: timeZone)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        conditions.timeOfDay = Solar.timeOfDay(
            date: now, latitude: seoulLatitude, longitude: seoulLongitude)
        conditions.darkness = Solar.darkness(
            date: now, latitude: seoulLatitude, longitude: seoulLongitude)
        conditions.season = OpenMeteo.season(month: calendar.component(.month, from: now))
        return conditions
    }

    /// Cold-start default: clear sky under the real sun.
    public static func clearDefault(now: Date, timeZone: TimeZone) -> WorldConditions {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return WorldConditions(
            weather: .clear,
            precipitation: 0,
            windSpeed: 0,
            timeOfDay: Solar.timeOfDay(
                date: now, latitude: seoulLatitude, longitude: seoulLongitude),
            season: OpenMeteo.season(month: calendar.component(.month, from: now)),
            darkness: Solar.darkness(
                date: now, latitude: seoulLatitude, longitude: seoulLongitude)
        )
    }

    /// Current best-known conditions without touching the network.
    public func current(now: Date = .now, timeZone: TimeZone = .current) -> WorldConditions {
        Self.resolve(fetched: nil, cached: cache.load(), now: now, timeZone: timeZone)
    }

    /// Fetches live conditions; on any failure falls back down the ladder.
    public func refresh(now: Date = .now, timeZone: TimeZone = .current) async -> WorldConditions {
        let fetched: WorldConditions?
        if let (data, _) = try? await session.data(from: Self.seoulURL) {
            fetched = try? OpenMeteo.conditions(fromJSON: data)
        } else {
            fetched = nil
        }
        if let fetched { cache.save(fetched) }
        return Self.resolve(fetched: fetched, cached: cache.load(), now: now, timeZone: timeZone)
    }
}
