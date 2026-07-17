import Foundation

/// A place whose sky the scroll can live under. Manual picker cities until
/// real location arrives with the M7 permission choreography.
public struct City: Codable, Equatable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public let latitude: Double
    public let longitude: Double

    public init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

extension City {
    public static let seoul = City(name: "Seoul", latitude: 37.5665, longitude: 126.978)

    /// A deliberate climate spread: monsoon, oceanic, mediterranean,
    /// tropical, arid, subpolar — and the southern hemisphere.
    public static let presets: [City] = [
        seoul,
        City(name: "Busan", latitude: 35.1796, longitude: 129.0756),
        City(name: "Tokyo", latitude: 35.6762, longitude: 139.6503),
        City(name: "Singapore", latitude: 1.3521, longitude: 103.8198),
        City(name: "Sydney", latitude: -33.8688, longitude: 151.2093),
        City(name: "Cairo", latitude: 30.0444, longitude: 31.2357),
        City(name: "London", latitude: 51.5074, longitude: -0.1278),
        City(name: "Reykjavík", latitude: 64.1466, longitude: -21.9426),
        City(name: "New York", latitude: 40.7128, longitude: -74.0060),
        City(name: "San Francisco", latitude: 37.7749, longitude: -122.4194),
    ]
}
