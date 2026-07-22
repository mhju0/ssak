import SwiftUI

public struct Droop: ViewModifier {
    public var amount: Double
    public init(amount: Double) { self.amount = amount }
    public func body(content: Content) -> some View {
        let a = max(0, min(1, amount))
        content
            // Yellowing multiplied into the art's own pixels only (masked to the content's
            // alpha) — a bare full-frame multiply was invisible over the round-1 opaque wall
            // but washed the whole cell once callers layer the art over a live RoomScene.
            .overlay {
                if a > 0 {                                              // true no-op at 0 (byte-stable)
                    Color(red: 0.85, green: 0.80, blue: 0.30)           // yellowing
                        .opacity(0.35 * a)
                        .blendMode(.multiply)
                        .mask(content)
                }
            }
            .rotationEffect(.degrees(6 * a), anchor: .bottom)            // gentle sag
            .scaleEffect(x: 1, y: 1 - 0.08 * a, anchor: .bottom)        // slight wilt-down
            .saturation(1 - 0.5 * a)                                    // desaturate
    }
}

public extension View {
    func droop(_ amount: Double) -> some View { modifier(Droop(amount: amount)) }
}
