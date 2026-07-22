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

/// The floating Water control — round 2: a small circular glass drop (62pt) that floats
/// free of all other chrome, gently bobbing. Never disabled (forgiving realism — over-full
/// shows the nudge, not a lock). iOS 26: water-blue `.glassProminent` circle; fallback: a
/// hand-drawn blue circle (deterministic on the macOS render path).
public struct WaterButton: View {
    let action: () -> Void
    public init(action: @escaping () -> Void) { self.action = action }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    private let waterBlue = Color(red: 0.36, green: 0.62, blue: 0.86)   // water action / gauge blue

    public var body: some View {
        button
            .offset(y: bob ? -6 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { bob = true }
            }
            .accessibilityLabel("Water")
            .accessibilityHint("Waters your plant")
    }

    @ViewBuilder private var button: some View {
        let icon = Image(systemName: "drop.fill")
            .font(.title2.weight(.medium))
            .foregroundStyle(.white)
            .frame(width: 62, height: 62)                               // ≥44pt target
        #if os(iOS)
        if #available(iOS 26.0, *) {
            Button(action: action) { icon }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .tint(waterBlue)
        } else {
            fallback(icon)
        }
        #else
        fallback(icon)
        #endif
    }

    private func fallback(_ icon: some View) -> some View {
        Button(action: action) {
            icon.background(
                Circle().fill(waterBlue)
                    .overlay(Circle().strokeBorder(.white.opacity(0.35)))
                    .shadow(color: waterBlue.opacity(0.5), radius: 10, y: 6))
        }
        .buttonStyle(.plain)
    }
}

/// The top glass pill nav — Windowsill / Shelf. Round 2 moved the nav up top and retired
/// the bottom `TabView`; this is the only screen switcher. Segments keep a ≥44pt height.
public struct TopNavPill: View {
    @Binding var tab: Int
    public init(tab: Binding<Int>) { _tab = tab }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        HStack(spacing: 2) {
            segment("Windowsill", 0)
            segment("Shelf", 1)
        }
        .padding(.horizontal, 4)
        .ssakGlass(Capsule())
        .accessibilityElement(children: .contain)
    }

    private func segment(_ label: String, _ i: Int) -> some View {
        Button { tab = i } label: {
            Text(label)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if tab == i {
                        Capsule().fill(scheme == .dark ? Color.white.opacity(0.16)
                                                       : Color.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    }
                }
                .opacity(tab == i ? 1 : 0.62)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .inkText()
        .accessibilityLabel(label)
        .accessibilityAddTraits(tab == i ? [.isButton, .isSelected] : .isButton)
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

    private let bloomGreen = Color(red: 0.36, green: 0.60, blue: 0.34)

    public var body: some View {
        let content = Image(systemName: systemImage)
            .font(.system(size: 18, weight: prominent ? .semibold : .regular))
            .frame(minWidth: 44, minHeight: 44)                        // ≥44pt tap target (spec §1.6)

        // `prominent` promotes with a quiet green tint, never width: the top row is shared
        // with the centered nav pill (round 2), so a labeled CTA can't fit — and on-device
        // round 1 already showed a loud Share competes with the blue Water control.
        // VoiceOver still gets the full label ("Share your bloom").
        #if os(iOS)
        if #available(iOS 26.0, *) {
            return AnyView(Button(action: action) { content }.buttonStyle(.glass)
                .tint(prominent ? bloomGreen : nil).accessibilityLabel(label))
        }
        #endif
        return AnyView(Button(action: action) { content }.buttonStyle(.bordered)
            .tint(prominent ? bloomGreen : nil).accessibilityLabel(label))
    }
}
