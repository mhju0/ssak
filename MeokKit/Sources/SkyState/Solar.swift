import Foundation
import GameKernel

/// Local solar computation — no network (spec §4). Standard low-precision
/// almanac (declination + hour angle via sidereal time), good to ~0.2°,
/// which is minutes-level for sunrise/sunset: plenty for ink.
public enum Solar {
    /// Solar elevation above the horizon, in degrees.
    public static func elevation(date: Date, latitude: Double, longitude: Double) -> Double {
        // Days since J2000.0 (2000-01-01T12:00Z).
        let d = date.timeIntervalSince1970 / 86400 - 10957.5

        let meanAnomaly = (357.529 + 0.98560028 * d).radians
        let meanLongitude = 280.459 + 0.98564736 * d
        let eclipticLongitude = (meanLongitude
            + 1.915 * sin(meanAnomaly)
            + 0.020 * sin(2 * meanAnomaly)).radians

        let obliquity = 23.439.radians
        let rightAscension = atan2(cos(obliquity) * sin(eclipticLongitude), cos(eclipticLongitude))
        let declination = asin(sin(obliquity) * sin(eclipticLongitude))

        // Greenwich mean sidereal time, degrees.
        let gmst = (18.697374558 + 24.06570982441908 * d)
            .truncatingRemainder(dividingBy: 24) * 15
        let hourAngle = (gmst + longitude).radians - rightAscension

        let lat = latitude.radians
        let sinElevation = sin(lat) * sin(declination)
            + cos(lat) * cos(declination) * cos(hourAngle)
        return asin(min(max(sinElevation, -1), 1)).degrees
    }

    /// Continuous 0…1 darkness: 0 above +8° elevation, 1 below −12°
    /// (nautical twilight), smoothstepped between — drives the ink curve.
    public static func darkness(date: Date, latitude: Double, longitude: Double) -> Double {
        let el = elevation(date: date, latitude: latitude, longitude: longitude)
        let t = min(max((8 - el) / 20, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Dawn and dusk are the ±6° twilight band around the real sunrise and
    /// sunset, not fixed clock hours.
    public static func timeOfDay(
        date: Date, latitude: Double, longitude: Double
    ) -> WorldConditions.TimeOfDay {
        let el = elevation(date: date, latitude: latitude, longitude: longitude)
        if el >= 6 { return .day }
        if el <= -6 { return .night }
        let soon = elevation(
            date: date.addingTimeInterval(600), latitude: latitude, longitude: longitude)
        return soon > el ? .dawn : .dusk
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
