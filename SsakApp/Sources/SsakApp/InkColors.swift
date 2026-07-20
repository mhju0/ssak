import SwiftUI

// Adaptive color primitives (spec §3.4). Implemented as ViewModifiers that read
// @Environment(\.colorScheme) — not bare `Color`s — so they respond to the scheme
// the render harness sets explicitly, staying deterministic on macOS as well as iOS.

/// Primary ink text: warm brown in light, warm cream in dark.
struct InkText: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.foregroundStyle(scheme == .dark
            ? Color(red: 0.925, green: 0.894, blue: 0.835)    // #ECE4D5
            : Color(red: 0.278, green: 0.220, blue: 0.157))   // #473828
    }
}

/// The screen ground behind a scene: cream in light, warm-dark gradient in dark.
struct SsakGround: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.background(scheme == .dark
            ? AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.165, green: 0.141, blue: 0.110),    // #2A241C
                         Color(red: 0.090, green: 0.075, blue: 0.059)],   // #17130F
                startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(Color(red: 0.99, green: 0.97, blue: 0.92)))    // cream
    }
}

public extension View {
    /// Primary ink text color, adaptive to light/dark (spec §3.4).
    func inkText() -> some View { modifier(InkText()) }
    /// Scene ground fill, adaptive to light/dark (spec §3.4).
    func ssakGround() -> some View { modifier(SsakGround()) }
}
