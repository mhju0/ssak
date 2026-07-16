import Foundation

/// A brush stamp along a stroke — what the renderer actually draws.
public struct Dab: Equatable, Sendable {
    public var position: Point
    /// Stamp radius in recipe units (width/2 × pressure at this point).
    public var radius: Double
    /// Normalized arc position 0…1 — drives reveal timing and ink depletion.
    public var t: Double

    public struct Point: Equatable, Sendable {
        public var x: Double
        public var y: Double

        public func distance(to other: Point) -> Double {
            ((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)).squareRoot()
        }
    }
}

extension Stroke {
    /// Samples the stroke into arc-length–uniform dabs. Catmull-Rom through
    /// all control points (endpoints doubled), pressure lerped per segment.
    public func dabs(spacing: Double) -> [Dab] {
        guard points.count >= 2, spacing > 0 else { return [] }

        // 1. Flatten the spline to a fine polyline with pressure per vertex.
        var vertices: [(x: Double, y: Double, pressure: Double)] = []
        let stepsPerSegment = 24
        for segment in 0 ..< points.count - 1 {
            let p0 = points[max(segment - 1, 0)]
            let p1 = points[segment]
            let p2 = points[segment + 1]
            let p3 = points[min(segment + 2, points.count - 1)]
            let last = segment == points.count - 2
            let steps = last ? stepsPerSegment : stepsPerSegment - 1
            for i in 0 ... steps {
                let t = Double(i) / Double(stepsPerSegment)
                guard t <= 1 else { break }
                vertices.append((
                    x: catmullRom(p0.x, p1.x, p2.x, p3.x, t),
                    y: catmullRom(p0.y, p1.y, p2.y, p3.y, t),
                    pressure: p1.pressure + (p2.pressure - p1.pressure) * t
                ))
            }
        }

        // 2. Cumulative arc length.
        var arc: [Double] = [0]
        for i in 1 ..< vertices.count {
            let dx = vertices[i].x - vertices[i - 1].x
            let dy = vertices[i].y - vertices[i - 1].y
            arc.append(arc[i - 1] + (dx * dx + dy * dy).squareRoot())
        }
        let total = arc.last!
        guard total > 0 else { return [] }

        // 3. Walk the polyline dropping dabs every `spacing` units.
        var dabs: [Dab] = []
        var target = 0.0
        var i = 1
        while target <= total + spacing * 0.01 {
            let clamped = min(target, total)
            while i < vertices.count - 1, arc[i] < clamped { i += 1 }
            let span = arc[i] - arc[i - 1]
            let f = span > 0 ? (clamped - arc[i - 1]) / span : 0
            let a = vertices[i - 1]
            let b = vertices[i]
            let pressure = a.pressure + (b.pressure - a.pressure) * f
            dabs.append(Dab(
                position: .init(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f),
                radius: width / 2 * pressure,
                t: clamped / total
            ))
            target += spacing
        }
        return dabs
    }
}

/// Uniform Catmull-Rom basis.
private func catmullRom(_ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double, _ t: Double) -> Double {
    let t2 = t * t
    let t3 = t2 * t
    return 0.5 * ((2 * p1)
        + (-p0 + p2) * t
        + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
        + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
}
