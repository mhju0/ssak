import Foundation
import GameKernel

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

    public func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}

/// Fetches the real sky for the default city and always resolves to a value:
/// live fetch → cached → clear-sky default. Never blank, never an error.
public final class SkyStore: @unchecked Sendable {
    private static let cityKey = "meok.sky.city"

    /// Current-conditions endpoint for a city.
    public static func url(for city: City) -> URL {
        URL(string: "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(city.latitude)&longitude=\(city.longitude)"
            + "&current=precipitation,weather_code,wind_speed_10m"
            + "&wind_speed_unit=ms&timezone=auto")!
    }

    private let cache: SkyCache
    private let session: URLSession
    private let defaults: UserDefaults

    /// The picked city; persisted. Seoul until the player chooses.
    /// Switching cities clears the weather cache — another city's cached
    /// rain under this sky would be a faked sky (pillar 1).
    public var city: City {
        get {
            defaults.data(forKey: Self.cityKey)
                .flatMap { try? JSONDecoder().decode(City.self, from: $0) } ?? .seoul
        }
        set {
            if newValue != city { cache.clear() }
            defaults.set(try? JSONEncoder().encode(newValue), forKey: Self.cityKey)
        }
    }

    public init(defaults: UserDefaults = .standard, session: URLSession = .shared) {
        self.cache = SkyCache(defaults: defaults)
        self.session = session
        self.defaults = defaults
    }

    /// The fallback ladder. Pure; the reason a sky always exists.
    /// Cached entries keep their weather but re-derive the sun (time-of-day,
    /// darkness) and season from the clock — a cache saved at night must not
    /// render night at noon.
    public static func resolve(
        fetched: WorldConditions?,
        cached: WorldConditions?,
        now: Date,
        timeZone: TimeZone,
        city: City = .seoul
    ) -> WorldConditions {
        if let fetched { return fetched }
        guard var conditions = cached else {
            return clearDefault(now: now, timeZone: timeZone, city: city)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        conditions.timeOfDay = Solar.timeOfDay(
            date: now, latitude: city.latitude, longitude: city.longitude)
        conditions.darkness = Solar.darkness(
            date: now, latitude: city.latitude, longitude: city.longitude)
        conditions.season = OpenMeteo.season(
            month: calendar.component(.month, from: now), latitude: city.latitude)
        return conditions
    }

    /// Cold-start default: clear sky under the real sun.
    public static func clearDefault(
        now: Date, timeZone: TimeZone, city: City = .seoul
    ) -> WorldConditions {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return WorldConditions(
            weather: .clear,
            precipitation: 0,
            windSpeed: 0,
            timeOfDay: Solar.timeOfDay(
                date: now, latitude: city.latitude, longitude: city.longitude),
            season: OpenMeteo.season(
                month: calendar.component(.month, from: now), latitude: city.latitude),
            darkness: Solar.darkness(
                date: now, latitude: city.latitude, longitude: city.longitude)
        )
    }

    /// Current best-known conditions without touching the network.
    public func current(now: Date = .now, timeZone: TimeZone = .current) -> WorldConditions {
        Self.resolve(fetched: nil, cached: cache.load(), now: now, timeZone: timeZone, city: city)
    }

    /// Fetches live conditions for the picked city; on any failure falls
    /// back down the ladder.
    public func refresh(now: Date = .now, timeZone: TimeZone = .current) async -> WorldConditions {
        let fetched: WorldConditions?
        if let (data, _) = try? await session.data(from: Self.url(for: city)) {
            fetched = try? OpenMeteo.conditions(fromJSON: data, now: now)
        } else {
            fetched = nil
        }
        if let fetched { cache.save(fetched) }
        return Self.resolve(
            fetched: fetched, cached: cache.load(), now: now, timeZone: timeZone, city: city)
    }
}
