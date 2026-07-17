import Foundation

/// The five zones of the scroll, stacked by altitude (spec §3):
/// forage high, fish low. Order is bottom → top.
public enum Zone: Int, CaseIterable, Sendable {
    case valleyPond, gardenTerrace, hermitage, forest, peak

    public var name: String {
        switch self {
        case .valleyPond: "valley pond"
        case .gardenTerrace: "garden terrace"
        case .hermitage: "hermitage"
        case .forest: "forest"
        case .peak: "peak path"
        }
    }

    /// Each zone is one screen tall; the camera's altitude picks the zone.
    public static func at(cameraY: Double, screenHeight: Double) -> Zone {
        guard screenHeight > 0 else { return .valleyPond }
        let index = Int(floor(cameraY / screenHeight))
        let clamped = min(max(index, 0), allCases.count - 1)
        return Zone(rawValue: clamped)!
    }
}

/// Pure scroll math for the vertical hanging scroll — deterministic and
/// tested here so the scene code stays a thin shell.
public enum ScrollGeometry {
    /// How far a flick carries, in seconds of retained velocity.
    public static let flickCarry = 0.35

    /// Camera center stays half a screen inside the world at both edges.
    public static func clampedCameraY(_ y: Double, screenHeight: Double, worldHeight: Double) -> Double {
        let half = screenHeight / 2
        guard worldHeight > screenHeight else { return worldHeight / 2 }
        return min(max(y, half), worldHeight - half)
    }

    /// Where a flick with the given velocity (pt/s, positive = camera up)
    /// should decelerate to.
    public static func flickTarget(
        from y: Double, velocity: Double, screenHeight: Double, worldHeight: Double
    ) -> Double {
        clampedCameraY(y + velocity * flickCarry, screenHeight: screenHeight, worldHeight: worldHeight)
    }
}
