import SwiftUI

public struct SeedSoil: View {
    let tint: Color
    public init(tint: Color) { self.tint = tint }
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Ellipse()                                                // soil mound
                    .fill(Color(red: 0.36, green: 0.26, blue: 0.18))
                    .frame(width: w * 0.6, height: h * 0.16)
                    .position(x: w * 0.5, y: h * 0.72)
                Circle()                                                 // tinted seed nub
                    .fill(tint)
                    .frame(width: w * 0.06, height: w * 0.06)
                    .position(x: w * 0.5, y: h * 0.70)
            }
        }
    }
}
