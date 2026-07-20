import SwiftUI

// Liquid Glass, macOS-safe (spec §1.4). All iOS-26-only glass API lives inside
// `#if os(iOS)` so the macOS render/test build always compiles the material/opaque
// fallback — the deterministic path all headless verification runs on. A11y-aware:
// Reduce Transparency → opaque, Increased Contrast → hairline border.

/// Glass-or-fallback background clipped to `shape`. Use via `.ssakGlass(_:tint:interactive:)`.
struct SsakGlass<S: InsettableShape>: ViewModifier {
    let shape: S
    let tint: Color?
    let interactive: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        #if os(iOS)                                    // macOS build always takes the fallback → deterministic
        if #available(iOS 26.0, *), !reduceTransparency {
            var glass = Glass.regular
            if let tint { glass = glass.tint(tint) }   // Glass.tint takes a non-optional Color → apply only when set
            glass = glass.interactive(interactive)
            return AnyView(content.glassEffect(glass, in: shape)
                .overlay(contrast == .increased ? shape.strokeBorder(.primary.opacity(0.3)) : nil))
        }
        #endif
        let fill: AnyShapeStyle = reduceTransparency
            ? AnyShapeStyle(tint?.opacity(0.16) ?? Color(white: 0.96))   // opaque
            : AnyShapeStyle(.ultraThinMaterial)
        return AnyView(content.background(fill, in: shape)
            .overlay(shape.strokeBorder(.white.opacity(0.25))))
    }
}

public extension View {
    /// Glass-or-fallback background clipped to `shape`, a11y-aware and macOS-safe (spec §1.4).
    func ssakGlass<S: InsettableShape>(_ shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(SsakGlass(shape: shape, tint: tint, interactive: interactive))
    }
}

/// The floating primary Water control — a large Liquid Glass capsule (spec §2.2, §1.6).
/// iOS 26: a water-blue `.glassProminent` interactive pill; fallback: a `.borderedProminent`
/// capsule. Never disabled (forgiving realism — over-full shows the nudge, not a lock).
public struct WaterButton: View {
    let isOverfull: Bool
    let action: () -> Void
    public init(isOverfull: Bool, action: @escaping () -> Void) {
        self.isOverfull = isOverfull; self.action = action
    }

    private let waterBlue = Color(red: 0.36, green: 0.62, blue: 0.86)   // water action / gauge blue

    public var body: some View {
        let label = Label("Water", systemImage: "drop.fill")
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 64)                  // ≥64pt tall (spec §1.6)
        #if os(iOS)
        if #available(iOS 26.0, *) {
            return AnyView(Button(action: action) { label }
                .buttonStyle(.glassProminent)
                .tint(waterBlue)
                .accessibilityHint("Waters your plant"))
        }
        #endif
        return AnyView(Button(action: action) { label }
            .buttonStyle(.borderedProminent)
            .tint(waterBlue)
            .clipShape(Capsule())
            .accessibilityHint("Waters your plant"))
    }
}

/// A top-corner glass icon button — the quiet Share (spec §2.2). `prominent` promotes it to
/// a labeled CTA (the bloom-moment "Share your bloom", Task 9). iOS 26: `.glass`/`.glassProminent`;
/// fallback: `.bordered`/`.borderedProminent`. The caller supplies any `GlassEffectContainer`.
public struct GlassIconButton: View {
    let systemImage: String
    let label: String
    let prominent: Bool
    let action: () -> Void
    public init(systemImage: String, label: String, prominent: Bool = false, action: @escaping () -> Void) {
        self.systemImage = systemImage; self.label = label; self.prominent = prominent; self.action = action
    }

    public var body: some View {
        let content = Group {
            if prominent {
                Label(label, systemImage: systemImage).font(.subheadline.weight(.semibold))
            } else {
                Image(systemName: systemImage).font(.system(size: 18))
            }
        }
        .frame(minWidth: 44, minHeight: 44)                            // ≥44pt tap target (spec §1.6)

        #if os(iOS)
        if #available(iOS 26.0, *) {
            if prominent {
                return AnyView(Button(action: action) { content }.buttonStyle(.glassProminent).accessibilityLabel(label))
            }
            return AnyView(Button(action: action) { content }.buttonStyle(.glass).accessibilityLabel(label))
        }
        #endif
        if prominent {
            return AnyView(Button(action: action) { content }.buttonStyle(.borderedProminent).accessibilityLabel(label))
        }
        return AnyView(Button(action: action) { content }.buttonStyle(.bordered).accessibilityLabel(label))
    }
}
