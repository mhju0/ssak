import SwiftUI

public struct Sill: View {
    public init() {}
    public var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                // soft warm wall, faint vertical light gradient
                LinearGradient(colors: [Color(red: 0.99, green: 0.97, blue: 0.91),
                                        Color(red: 0.97, green: 0.93, blue: 0.85)],
                               startPoint: .top, endPoint: .bottom)
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

/// Terracotta pot with a connected rim and a visible soil surface.
/// Soil-surface center sits at `soilFraction` of the pot's own height — the
/// anchor a plant grows from. Drawn back-to-front: body → rim → soil.
public struct Pot: View {
    public init() {}
    /// Pot-local y (fraction of height) of the soil-surface center — PlantView
    /// uses this to align the plant's base with the soil.
    public static let soilFraction: CGFloat = 0.16

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let terracotta = LinearGradient(
                colors: [Color(red: 0.84, green: 0.47, blue: 0.34),
                         Color(red: 0.64, green: 0.33, blue: 0.24)],
                startPoint: .top, endPoint: .bottom)
            ZStack {
                // body — gently tapered walls
                Path { p in
                    p.move(to: CGPoint(x: w * 0.16, y: h * 0.22))
                    p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.22))
                    p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.99))
                    p.addLine(to: CGPoint(x: w * 0.28, y: h * 0.99))
                    p.closeSubpath()
                }
                .fill(terracotta)
                // rim — a lip band overlapping the body top (connected, not floating)
                Ellipse()
                    .fill(Color(red: 0.78, green: 0.43, blue: 0.31))
                    .frame(width: w * 0.92, height: h * 0.21)
                    .position(x: w * 0.5, y: h * 0.15)
                // soil surface set into the rim opening
                Ellipse()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.30, green: 0.21, blue: 0.14),
                                 Color(red: 0.22, green: 0.15, blue: 0.10)],
                        center: .center, startRadius: 0, endRadius: w * 0.4))
                    .frame(width: w * 0.74, height: h * 0.155)
                    .position(x: w * 0.5, y: h * Pot.soilFraction)
            }
        }
    }
}
