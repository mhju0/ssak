import SwiftUI

/// The quiet, gauge-only moisture read-out (spec §2.2 zone 4, §3.2). Deliberately separate from
/// and de-duplicated against the streak/tick (which live only in the top status bar) — this is
/// the fix for "the gauge is mixed in with the buttons": the read-out is its own quiet cluster.
public struct StatusCluster: View {
    let fraction: Double
    let band: ClosedRange<Double>
    public init(fraction: Double, band: ClosedRange<Double>) {
        self.fraction = fraction; self.band = band
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ripple: CGFloat = 0

    public var body: some View {
        HStack(spacing: 8) {
            DropGauge(fraction: fraction, band: band)
                .frame(width: 30, height: 44)
                .overlay(surfaceRipple)                 // spec §1.5 gauge ripple (static under Reduce Motion)
            Text(moistureLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Soil moisture, \(Int((min(1, max(0, fraction)) * 100).rounded())) percent")
    }

    private var moistureLabel: String {
        let f = min(1, max(0, fraction))
        if f < band.lowerBound { return "dry" }
        if f > band.upperBound { return "over-full" }
        return "moist"
    }

    /// A faint highlight at the waterline that gently bobs — the "surface" of the water.
    /// A repeatForever animation, so ImageRenderer captures its resting frame (deterministic);
    /// off entirely under Reduce Motion.
    private var surfaceRipple: some View {
        GeometryReader { geo in
            let f = CGFloat(min(1, max(0, fraction)))
            Capsule()
                .fill(.white.opacity(0.30))
                .frame(height: 1.5)
                .padding(.horizontal, geo.size.width * 0.22)
                .offset(y: geo.size.height * (1 - f) + ripple)
                .opacity(f > 0.03 ? 1 : 0)
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { ripple = 1.5 }
        }
    }
}
