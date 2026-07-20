import SwiftUI

public struct Sill: View {
    let wall: Bool
    /// `wall: true` (default) draws the static cream wall + board — byte-identical to the
    /// original for every existing caller. `wall: false` draws only the board/ledge, so a
    /// caller (WindowsillView) can layer its own live `SkyBackdrop` behind (spec §3.3).
    public init(wall: Bool = true) { self.wall = wall }
    public var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                Color.clear    // keeps the sill filling its frame even when wall:false (else the
                               // board-only ZStack collapses to the top); occluded by the opaque
                               // gradient when wall:true, so that path stays byte-identical.
                // soft warm wall, faint vertical light gradient
                if wall {
                    LinearGradient(colors: [Color(red: 0.99, green: 0.97, blue: 0.91),
                                            Color(red: 0.97, green: 0.93, blue: 0.85)],
                                   startPoint: .top, endPoint: .bottom)
                }
                // sill board the pot rests on
                Rectangle()
                    .fill(Color(red: 0.91, green: 0.85, blue: 0.73))
                    .frame(height: h * 0.14)
                    .overlay(alignment: .top) {                    // thin front lip shadow
                        Rectangle().fill(Color.black.opacity(0.05)).frame(height: h * 0.012)
                    }
            }
        }
    }
}

/// The pot's outer silhouette: a tapered body with a gentle convex belly.
struct PotBody: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        let tl = CGPoint(x: w * 0.15, y: h * 0.20)
        let tr = CGPoint(x: w * 0.85, y: h * 0.20)
        let br = CGPoint(x: w * 0.71, y: h * 0.99)
        let bl = CGPoint(x: w * 0.29, y: h * 0.99)
        var p = Path()
        p.move(to: tl)
        p.addLine(to: tr)
        // right wall bows out (belly) then tapers in
        p.addQuadCurve(to: br, control: CGPoint(x: w * 0.90, y: h * 0.58))
        p.addLine(to: bl)
        // left wall bows out symmetrically
        p.addQuadCurve(to: tl, control: CGPoint(x: w * 0.10, y: h * 0.58))
        return p
    }
}

/// Terracotta pot with a curved belly, a rim with depth, a soft cylindrical
/// highlight, and a visible soil surface. Soil-surface center sits at
/// `soilFraction` of the pot's own height — the anchor a plant grows from.
public struct Pot: View {
    public init() {}
    /// Pot-local y (fraction of height) of the soil-surface center — PlantView
    /// uses this to align the plant's base with the soil.
    public static let soilFraction: CGFloat = 0.15

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let terracotta = LinearGradient(
                colors: [Color(red: 0.85, green: 0.49, blue: 0.35),
                         Color(red: 0.62, green: 0.32, blue: 0.23)],
                startPoint: .top, endPoint: .bottom)
            ZStack {
                // body
                PotBody().fill(terracotta)
                // cylindrical shading: light on the left, shadow on the right
                PotBody().fill(LinearGradient(
                    colors: [.white.opacity(0.16), .clear, .clear, .black.opacity(0.14)],
                    startPoint: .leading, endPoint: .trailing))
                // rim: outer lip, inner-wall shadow, then soil in the opening
                Ellipse()
                    .fill(Color(red: 0.80, green: 0.45, blue: 0.32))
                    .frame(width: w * 0.94, height: h * 0.22)
                    .position(x: w * 0.5, y: h * 0.15)
                Ellipse()
                    .fill(Color(red: 0.62, green: 0.33, blue: 0.24))
                    .frame(width: w * 0.80, height: h * 0.175)
                    .position(x: w * 0.5, y: h * 0.155)
                Ellipse()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.31, green: 0.22, blue: 0.15),
                                 Color(red: 0.21, green: 0.14, blue: 0.09)],
                        center: .init(x: 0.5, y: 0.35), startRadius: 0, endRadius: w * 0.4))
                    .frame(width: w * 0.72, height: h * 0.145)
                    .position(x: w * 0.5, y: h * Pot.soilFraction)
            }
        }
    }
}
