import SwiftUI
import SsakCore
import SsakArt

// Round 3 (spec 2026-07-23): the album's ink components — everything that used to be
// glass on the windowsill becomes ink on paper. All read the environment color scheme
// through the existing night flip (`inkText()` and the seal/gauge tones below), so the
// dark-paper night band lights the chrome without any new machinery.

/// Seal red, adaptive: dojang red on light paper, lifted brick on dark.
struct SealRed: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.foregroundStyle(SealRed.color(scheme))
    }
    static func color(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.827, green: 0.478, blue: 0.396)   // #D37A65
                        : Color(red: 0.682, green: 0.231, blue: 0.165)   // #AE3B2A
    }
}

/// The dojang: a rotated red square carrying the streak (spec D3). Muted when broken.
public struct SealBadge: View {
    let count: Int
    let alive: Bool
    public init(count: Int, alive: Bool) { self.count = count; self.alive = alive }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        let red = SealRed.color(scheme)
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.myeongjoDisplay(24, relativeTo: .title3))
            Text("연속")
                .font(.myeongjo(9, relativeTo: .caption2)).tracking(3)
        }
        .foregroundStyle(red)
        .frame(width: 58, height: 58)
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(red, lineWidth: 2.5))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(red.opacity(0.35))
            .padding(3.5))
        .rotationEffect(.degrees(4))
        .saturation(alive ? 1 : 0)
        .opacity(alive ? 1 : 0.55)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak, \(count) \(count == 1 ? "day" : "days")")
    }
}

/// The ink hairline moisture gauge (spec D4): soil-state colored fill over a faint
/// track, soil word left, watered seal-word right (hidden while over-full).
public struct InkGauge: View {
    let fraction: Double
    let soil: SoilState
    let watered: Bool
    public init(fraction: Double, soil: SoilState, watered: Bool) {
        self.fraction = fraction; self.soil = soil; self.watered = watered
    }

    @Environment(\.colorScheme) private var scheme

    private var fill: Color {
        switch soil {
        case .dry:      return Color(red: 0.804, green: 0.518, blue: 0.153)   // amber
        case .moist:    return Color(red: 0.424, green: 0.471, blue: 0.322)   // moss
        case .overfull: return Color(red: 0.302, green: 0.451, blue: 0.620)   // murky slate
        }
    }
    private var word: String {
        switch soil {
        case .dry:      return "흙이 말랐어요"
        case .moist:    return "흙이 촉촉해요"
        case .overfull: return "물이 너무 많아요"
        }
    }
    private var wordEN: String {   // VoiceOver stays English this round (spec D1)
        switch soil {
        case .dry: return "dry"; case .moist: return "moist"; case .overfull: return "over-full"
        }
    }

    public var body: some View {
        let f = min(1, max(0, fraction))
        VStack(spacing: 9) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill((scheme == .dark ? Color.white : Design.shadow).opacity(0.18))
                    Capsule().fill(fill).frame(width: geo.size.width * f)
                }
            }
            .frame(height: 3)
            HStack {
                Text(word)
                Spacer()
                if watered && soil != .overfull { Text("오늘 물 줌 ✓") }
            }
            .font(.myeongjo(12, relativeTo: .footnote)).tracking(1)
            .inkText().opacity(0.85)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Soil moisture, \(Int((f * 100).rounded())) percent, \(wordEN)"
                            + (watered ? ", watered today" : ""))
    }
}

/// Text-tab nav — 창가 / 압화집, active tab underlined seal-red (spec D6).
public struct InkNavTabs: View {
    @Binding var tab: Int
    public init(tab: Binding<Int>) { _tab = tab }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        HStack(spacing: 22) {
            segment("창가", "Windowsill", 0)
            segment("압화집", "Shelf", 1).guideTarget("shelf")
        }
        .accessibilityElement(children: .contain)
    }

    private func segment(_ label: String, _ en: String, _ i: Int) -> some View {
        Button { tab = i } label: {
            Text(label)
                .font(.myeongjo(14, relativeTo: .subheadline)).tracking(2)
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    if tab == i {
                        Rectangle().fill(SealRed.color(scheme)).frame(height: 1.5)
                    }
                }
                .opacity(tab == i ? 1 : 0.55)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .inkText()
        .accessibilityLabel(en)
        .accessibilityAddTraits(tab == i ? [.isButton, .isSelected] : .isButton)
    }
}

/// The ink-outline water button (spec D5): 56pt circle, drop glyph, gentle bob.
/// Never disabled — forgiving realism keeps the nudge, not a lock.
public struct InkWaterButton: View {
    let action: () -> Void
    public init(action: @escaping () -> Void) { self.action = action }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var bob = false

    public var body: some View {
        Button(action: action) {
            Image(systemName: "drop")
                .font(.system(size: 21, weight: .medium))
                .frame(width: 56, height: 56)
                .background(Circle().fill(scheme == .dark
                    ? Color.white.opacity(0.06) : Color.white.opacity(0.42)))
                .overlay(Circle().strokeBorder(.primary.opacity(0.85), lineWidth: 1.5))
        }
        .buttonStyle(.pressable)
        .inkText()
        .offset(y: bob ? -5 : 0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { bob = true }
        }
        .accessibilityLabel("Water")
        .accessibilityHint("Waters your plant")
    }
}

/// Quiet ink share glyph; seal-red at the bloom moment (spec D9).
public struct InkShareButton: View {
    let label: String
    let prominent: Bool
    let action: () -> Void
    public init(label: String, prominent: Bool, action: @escaping () -> Void) {
        self.label = label; self.prominent = prominent; self.action = action
    }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 17, weight: prominent ? .semibold : .regular))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .modifier(ShareTint(prominent: prominent))
        .accessibilityLabel(label)
    }
}
private struct ShareTint: ViewModifier {
    let prominent: Bool
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        if prominent { content.foregroundStyle(SealRed.color(scheme)) }
        else { content.inkText().opacity(0.75) }
    }
}

/// The band clock (spec D7): names why the paper changed — 아침 · 7:38.
public struct BandClock: View {
    let now: Date
    let calendar: Calendar
    public init(now: Date, calendar: Calendar) { self.now = now; self.calendar = calendar }

    public var body: some View {
        let c = calendar.dateComponents([.hour, .minute], from: now)
        let h24 = c.hour ?? 12, m = c.minute ?? 0
        let h12 = h24 % 12 == 0 ? 12 : h24 % 12
        let word: String
        switch TimeBand(now: now, calendar: calendar) {
        case .dawn: word = "아침"; case .day: word = "낮"
        case .dusk: word = "저녁"; case .night: word = "밤"
        }
        return Text("\(word) · \(h12):\(String(format: "%02d", m))")
            .font(.myeongjo(12, relativeTo: .footnote)).tracking(2)
            .inkText().opacity(0.75)
            .accessibilityHidden(true)                 // decorative; the OS clock is right there
    }
}
