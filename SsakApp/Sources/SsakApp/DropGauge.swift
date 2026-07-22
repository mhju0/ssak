import SwiftUI
import SsakCore

/// An upward-pointing water-drop silhouette.
struct DropShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: h * 0.66), control: CGPoint(x: w * 0.98, y: h * 0.30))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w, y: h * 0.96))
        p.addQuadCurve(to: CGPoint(x: 0, y: h * 0.66), control: CGPoint(x: 0, y: h * 0.96))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 0.02, y: h * 0.30))
        return p
    }
}

/// A water-drop gauge that fills bottom-up to `fraction` (0…1). Amber when the soil
/// is `.dry`, calm blue when `.moist`/`.overfull`, with an extra sheen when `.overfull`.
/// Classification is decided by the caller (`SoilState`); the gauge only draws it.
public struct DropGauge: View {
    let fraction: Double
    let soil: SoilState
    public init(fraction: Double, soil: SoilState) {
        self.fraction = fraction; self.soil = soil
    }
    public var body: some View {
        let f = min(1, max(0, fraction))
        let water: Color = soil == .dry
            ? Color(red: 0.92, green: 0.62, blue: 0.22)          // too dry → amber
            : Color(red: 0.36, green: 0.62, blue: 0.86)          // healthy / full → blue
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                Rectangle().fill(water).frame(height: h * f)
                if soil == .overfull {                            // over-full sheen
                    Rectangle().fill(.white.opacity(0.18)).frame(height: h * f)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .clipShape(DropShape())
            .background(DropShape().fill(Color(red: 0.82, green: 0.89, blue: 0.95)))
            .overlay(DropShape().stroke(water.opacity(0.55), lineWidth: geo.size.width * 0.04))
        }
    }
}

/// A soft "watered today" seal.
public struct WateredTodayTick: View {
    public init() {}
    public var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .foregroundStyle(Color(red: 0.36, green: 0.60, blue: 0.34))
    }
}

/// A small streak badge — a sprout leaf + count in a corner glass chip (round-2 restyle),
/// muted when the streak is broken.
public struct StreakBadge: View {
    let count: Int
    let alive: Bool
    public init(count: Int, alive: Bool) { self.count = count; self.alive = alive }
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(alive ? Color(red: 0.34, green: 0.56, blue: 0.30) : Color.secondary)
            Text("\(count)").inkText()
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .ssakGlass(Capsule())
        .opacity(alive ? 1 : 0.7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak, \(count) \(count == 1 ? "day" : "days")")
    }
}

/// The quiet moisture read-out (round 2): a glass pill holding a *miniature* DropGauge plus
/// the soil word — the mockup's "moist" chip, but keeping the fill-level signal the gauge
/// carries ("watch the drop" stays a real mechanic, not just a label). Also carries the
/// watered-today seal: the shared top row (nav pill + corner chips) has no room for it.
public struct MoistChip: View {
    let fraction: Double
    let soil: SoilState
    let watered: Bool
    public init(fraction: Double, soil: SoilState, watered: Bool = false) {
        self.fraction = fraction; self.soil = soil; self.watered = watered
    }

    public var body: some View {
        HStack(spacing: 8) {
            DropGauge(fraction: fraction, soil: soil).frame(width: 13, height: 18)
            Text(word).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            if watered { WateredTodayTick().font(.footnote) }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 28)
        .ssakGlass(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Soil moisture, \(Int((min(1, max(0, fraction)) * 100).rounded())) percent, \(word)"
                            + (watered ? ", watered today" : ""))
    }

    private var word: String {
        switch soil {
        case .dry:      return "dry"
        case .overfull: return "over-full"
        case .moist:    return "moist"
        }
    }
}
