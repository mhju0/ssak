import SwiftUI

public struct Droop: ViewModifier {
    public var amount: Double
    public init(amount: Double) { self.amount = amount }
    public func body(content: Content) -> some View {
        let a = max(0, min(1, amount))
        content
            .rotationEffect(.degrees(6 * a), anchor: .bottom)            // gentle sag
            .scaleEffect(x: 1, y: 1 - 0.08 * a, anchor: .bottom)        // slight wilt-down
            .overlay(
                Color(red: 0.85, green: 0.80, blue: 0.30)               // yellowing
                    .opacity(0.35 * a)
                    .blendMode(.multiply)
            )
            .saturation(1 - 0.5 * a)                                    // desaturate
    }
}

public extension View {
    func droop(_ amount: Double) -> some View { modifier(Droop(amount: amount)) }
}
