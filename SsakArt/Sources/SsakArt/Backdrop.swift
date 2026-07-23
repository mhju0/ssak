import SwiftUI

public struct Sill: View {
    let wall: Bool
    let board: Bool
    /// `wall: true` (default) draws the static cream wall + board — byte-identical to the
    /// original for every existing caller. `wall: false` draws only the board/ledge, so a
    /// caller can layer its own live backdrop behind (spec §3.3). `board: false` (round 2)
    /// drops the ledge too — the pot sits directly on `RoomScene`'s own sill.
    public init(wall: Bool = true, board: Bool = true) { self.wall = wall; self.board = board }
    @Environment(\.colorScheme) private var scheme   // board dims in dark mode (light path unchanged → byte-stable)
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
                // sill board the pot rests on — dim in dark mode so it recedes into the night sky
                if board {
                    Rectangle()
                        .fill(scheme == .dark ? Color(red: 0.32, green: 0.27, blue: 0.20)
                                              : Color(red: 0.91, green: 0.85, blue: 0.73))
                        .frame(height: h * 0.14)
                        .overlay(alignment: .top) {                    // thin front lip shadow
                            Rectangle().fill(Color.black.opacity(0.05)).frame(height: h * 0.012)
                        }
                }
            }
        }
    }
}

/// The pot's outer silhouette (round 3 "P3 사발"): a low bowl — near-straight lip,
/// sides rolling into one soft continuous bottom curve. No flared rim.
struct PotBody: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        let tl = CGPoint(x: w * 0.05, y: h * 0.08)
        let tr = CGPoint(x: w * 0.95, y: h * 0.08)
        var p = Path()
        p.move(to: tl)
        p.addLine(to: tr)
        // right side rolls into the bottom bowl curve…
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.99),
                   control1: CGPoint(x: w * 0.97, y: h * 0.62),
                   control2: CGPoint(x: w * 0.80, y: h * 0.99))
        // …and back up the left, symmetrically
        p.addCurve(to: tl,
                   control1: CGPoint(x: w * 0.20, y: h * 0.99),
                   control2: CGPoint(x: w * 0.03, y: h * 0.62))
        return p
    }
}

/// The 사발 (round 3): a flat, modern low bowl — single matte terracotta, a thin
/// inner-lip shade, and the soil surface. Soil-surface center sits at
/// `soilFraction` of the pot's own height — the anchor a plant grows from.
public struct Pot: View {
    public init() {}
    /// Pot-local y (fraction of height) of the soil-surface center — PlantView
    /// uses this to align the plant's base with the soil.
    public static let soilFraction: CGFloat = 0.12

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // body — flat matte terracotta, one whisper of bottom shade for roundness
                PotBody().fill(Color(red: 0.769, green: 0.463, blue: 0.353))
                PotBody().fill(LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.10)],
                    startPoint: .top, endPoint: .bottom))
                // thin inner lip
                Ellipse()
                    .fill(Color(red: 0.62, green: 0.33, blue: 0.24))
                    .frame(width: w * 0.90, height: h * 0.16)
                    .position(x: w * 0.5, y: h * 0.115)
                // soil surface
                Ellipse()
                    .fill(Color(red: 0.27, green: 0.19, blue: 0.13))
                    .frame(width: w * 0.84, height: h * 0.13)
                    .position(x: w * 0.5, y: h * Pot.soilFraction)
            }
        }
    }
}
