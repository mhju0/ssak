import SwiftUI

public struct Sill: View {
    public init() {}
    public var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                Color(red: 0.98, green: 0.95, blue: 0.88)                 // warm wall
                Rectangle()                                              // sill board
                    .fill(Color(red: 0.90, green: 0.84, blue: 0.72))
                    .frame(height: h * 0.16)
            }
        }
    }
}

public struct Pot: View {
    public init() {}
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in                                                  // tapered pot
                p.move(to: CGPoint(x: w * 0.22, y: h * 0.02))
                p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.02))
                p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.98))
                p.addLine(to: CGPoint(x: w * 0.30, y: h * 0.98))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(red: 0.82, green: 0.45, blue: 0.32),
                                          Color(red: 0.66, green: 0.34, blue: 0.24)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                Capsule().fill(Color(red: 0.74, green: 0.40, blue: 0.29))
                    .frame(height: h * 0.14)                              // rim
            }
        }
    }
}
