import SwiftUI
import SsakArt

// The first-run start guide (round 2, mockup in `docs/design/`): an Apple-style welcome
// sheet, then three Duolingo-style spotlight coach marks over the live windowsill —
// the plant, the water drop, the Shelf tab. Replaces the round-1 full-screen onboarding.

/// Views under the guide tag their bounds with `.guideTarget(id)`; RootView resolves the
/// anchors and hands concrete rects to `StartGuide`.
public struct GuideTargetKey: PreferenceKey {
    public static var defaultValue: [String: Anchor<CGRect>] = [:]
    public static func reduce(value: inout [String: Anchor<CGRect>],
                              nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

public extension View {
    /// Marks this view as a start-guide spotlight target.
    func guideTarget(_ id: String) -> some View {
        anchorPreference(key: GuideTargetKey.self, value: .bounds) { [id: $0] }
    }
}

public struct StartGuide: View {
    let anchors: [String: CGRect]
    let speciesName: String
    let onDone: () -> Void

    /// `startAt` exists for the render harness (−1 = welcome sheet, 0… = spotlight step).
    public init(anchors: [String: CGRect], speciesName: String,
                startAt: Int = -1, onDone: @escaping () -> Void) {
        self.anchors = anchors; self.speciesName = speciesName; self.onDone = onDone
        _step = State(initialValue: startAt)
    }

    @State private var step: Int
    @State private var bubbleHeight: CGFloat = 120
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var steps: [(id: String, title: String, body: String, pad: CGFloat)] {
        [("plant", "Your \(speciesName.lowercased())",
          "It grows on the real clock — a little every day. No tapping to rush it.", 6),
         ("water", "A drop of water",
          "Tap the floating drop to water. Just a little — don\u{2019}t drown it.", 10),
         ("shelf", "Press to your shelf",
          "When it blooms, press it here. Six flowers to collect.", 6)]
    }

    // Fixed warm-cream card colors (the mockup keeps the guide light on every band/scheme;
    // the dim layer guarantees contrast behind it).
    private let cardInk = Color(red: 0.29, green: 0.23, blue: 0.16)      // #4A3B2A
    private let cardSoft = Color(red: 0.49, green: 0.42, blue: 0.33)
    private let accent = Color(red: 0.37, green: 0.56, blue: 0.27)       // sprout green

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                if step >= 0, let rect = spotRect(step) {
                    spotlight(rect: rect, in: geo.size)
                    bubble(for: steps[step], near: rect, in: geo.size)
                } else {
                    Color(red: 0.08, green: 0.05, blue: 0.02).opacity(0.4)
                        .ignoresSafeArea()
                    welcomeSheet
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom))
                }
                skip
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, Design.pad)
                    .padding(.top, 56)                     // clears the top-right ink nav (round 3)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: step)
        .accessibilityAddTraits(.isModal)
    }

    private func spotRect(_ n: Int) -> CGRect? {
        anchors[steps[n].id].map { $0.insetBy(dx: -steps[n].pad, dy: -steps[n].pad) }
    }

    private func advance() {
        if step < steps.count - 1 { step += 1 } else { onDone() }
    }

    // MARK: spotlight + bubble

    // NOTE: no .ignoresSafeArea() here — the cutout rect is measured in the safe-area
    // space the anchors resolve in, and ignoring it shifts the drawing origin to the
    // physical screen top, landing the ring a status-bar-height too high on device.
    // SpotlightDim already paints 200pt past its bounds, so the dim still covers the
    // bleed. contentShape + the empty tap keep taps from leaking through the cutout.
    private func spotlight(rect: CGRect, in size: CGSize) -> some View {
        SpotlightDim(cutout: rect)
            .fill(Color(red: 0.08, green: 0.05, blue: 0.02).opacity(0.55),
                  style: FillStyle(eoFill: true))
            .overlay(
                RoundedRectangle(cornerRadius: Design.rLG)
                    .stroke(.white.opacity(0.9), lineWidth: 3)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY))
            .contentShape(Rectangle())
            .onTapGesture {}
    }

    private func bubble(for s: (id: String, title: String, body: String, pad: CGFloat),
                        near rect: CGRect, in size: CGSize) -> some View {
        let below = rect.midY < size.height * 0.5
        let y = below ? rect.maxY + 14 : rect.minY - 14 - bubbleHeight
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SsakMark(.light).frame(width: 26, height: 26)
                Text(s.title).font(.system(.subheadline, design: .serif).weight(.semibold))
            }
            Text(s.body).font(.subheadline).foregroundStyle(cardSoft)
            HStack {
                dots(current: step + 1)
                Spacer()
                Button(action: advance) {
                    Text(step == steps.count - 1 ? "Let\u{2019}s grow 🌱" : "Next")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: Design.rSM).fill(accent))
                }
                .buttonStyle(.pressable)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Design.rMD)
            .fill(Color(red: 1, green: 0.99, blue: 0.97))
            .overlay(RoundedRectangle(cornerRadius: Design.rMD).strokeBorder(.white.opacity(0.65)))
            .shadow(color: Design.shadow.opacity(0.5), radius: 14, y: 8))
        .foregroundStyle(cardInk)
        .background(GeometryReader { g in
            Color.clear.onAppear { bubbleHeight = g.size.height }
                .onChange(of: g.size.height) { bubbleHeight = $0 }
        })
        .padding(.horizontal, Design.pad)
        .offset(y: max(8, y))
        .accessibilityElement(children: .contain)
    }

    // MARK: welcome sheet

    private var welcomeSheet: some View {
        VStack(spacing: 0) {
            SsakMark(.light).frame(width: 52, height: 52).padding(.bottom, 12)
            Text("Raise one flower")
                .font(.system(.title, design: .serif).weight(.semibold))
                .tracking(-0.3)
                .padding(.bottom, 8)
            Text("From a single seed to full bloom — on the real clock, at your own pace.")
                .font(.subheadline).foregroundStyle(cardSoft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
                .padding(.bottom, 16)
            VStack(alignment: .leading, spacing: 12) {
                row("clock", tint: Color(red: 0.92, green: 0.95, blue: 0.87),
                    icon: accent, "Grows on the real clock, not taps")
                row("drop.fill", tint: Color(red: 0.98, green: 0.92, blue: 0.81),
                    icon: Color(red: 0.89, green: 0.60, blue: 0.24), "A little water each day — gently")
                row("square.grid.2x2", tint: Color(red: 0.92, green: 0.87, blue: 0.94),
                    icon: Color(red: 0.56, green: 0.44, blue: 0.69), "Collect all six species")
            }
            .padding(.bottom, 24)
            Button(action: advance) {
                Text("Plant a seed")
                    .font(.headline)                                   // the Toss 17/600 CTA slot
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)         // TDS BottomCTA: 52pt, r16
                    .background(RoundedRectangle(cornerRadius: Design.rMD).fill(accent))
            }
            .buttonStyle(.pressable)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: Design.rLG)
            .fill(LinearGradient(colors: [Color(red: 1, green: 0.99, blue: 0.97),
                                          Color(red: 0.98, green: 0.95, blue: 0.88)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: Design.rLG).strokeBorder(.white.opacity(0.65)))
            .shadow(color: Design.shadow.opacity(0.4), radius: 20, y: -4))
        .foregroundStyle(cardInk)
        .padding(.horizontal, Design.pad)
        .padding(.bottom, Design.pad)
        .accessibilityElement(children: .contain)
    }

    private func row(_ symbol: String, tint: Color, icon: Color, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(icon)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: Design.rSM).fill(tint))
            Text(text).font(.subheadline.weight(.medium))
        }
    }

    private func dots(current: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == current ? accent : Color(red: 0.85, green: 0.80, blue: 0.70))
                    .frame(width: i == current ? 18 : 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of 4")
    }

    private var skip: some View {
        Button(action: onDone) {
            Text("Skip")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(cardInk)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)                                  // ≥44pt target
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .background(Capsule().fill(.white.opacity(0.5)).frame(height: 32))
        .accessibilityLabel("Skip the start guide")
    }
}

/// Full-screen dim with a rounded-rect cutout (even-odd fill).
struct SpotlightDim: Shape {
    let cutout: CGRect
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addRect(r.insetBy(dx: -200, dy: -200))     // covers the safe-area bleed
        p.addRoundedRect(in: cutout, cornerSize: CGSize(width: Design.rLG, height: Design.rLG))
        return p
    }
}
