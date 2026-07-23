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

public extension View {
    /// Primary ink text color, adaptive to light/dark (spec §3.4).
    func inkText() -> some View { modifier(InkText()) }
}

/// Round-2 Toss-pass tokens (mockup in `docs/design/`): one edge inset, one radius scale.
/// Type is deliberately NOT here — the approved 28/20/17/15/13 scale maps 1:1 onto semantic
/// Dynamic Type styles (.title / .title3 / .headline / .subheadline / .footnote), and
/// nothing renders below .footnote (the 13pt floor).
public enum Design {
    /// The one horizontal edge inset — left == right for all screen chrome.
    public static let pad: CGFloat = 20
    public static let rSM: CGFloat = 12
    public static let rMD: CGFloat = 16
    public static let rLG: CGFloat = 24
    /// The one shadow hue: warm brown (rgb 40,25,10), never pure black on the cream world.
    public static let shadow = Color(red: 0.157, green: 0.098, blue: 0.039)
}

/// Shared pressed-state feedback: every tappable visibly responds under the finger
/// (scale dip, spring back). Respects Reduce Motion.
struct Pressable: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.15, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == Pressable {
    static var pressable: Pressable { Pressable() }
}
