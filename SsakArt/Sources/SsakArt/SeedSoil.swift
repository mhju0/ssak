import SwiftUI

/// The seed stage's plant content: a small tinted seed half-set into the soil,
/// drawn at the bottom-center of the plant region (the soil line). The soil
/// itself lives in `Pot`; this is only the seed.
public struct SeedSoil: View {
    let tint: Color
    public init(tint: Color) { self.tint = tint }
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // seed: a small almond shape resting on the soil
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.055, height: w * 0.085)
                    .rotationEffect(.degrees(18))
                    .position(x: w * 0.5, y: h * 0.965)
            }
        }
    }
}
