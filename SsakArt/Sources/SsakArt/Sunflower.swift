import SwiftUI

enum SunflowerArt {

    @ViewBuilder static func sprout(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.62), bow: w * 0.01),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
            let lb = CGPoint(x: w * 0.5, y: h * 0.72)
            ctx.fill(leafPath(base: lb, angleDeg: -48, length: h * 0.13, width: w * 0.12), with: .color(p.foliage))
            ctx.fill(leafPath(base: lb, angleDeg: 48, length: h * 0.13, width: w * 0.12), with: .color(p.foliageDeep))
        }
    }

    @ViewBuilder static func leaves(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let tip = CGPoint(x: w * 0.5, y: h * 0.36)
            ctx.stroke(stemPath(base: base, tip: tip, bow: w * 0.02),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.038, lineCap: .round))
            // large broad heart-ish leaves
            for (i, y) in [CGFloat(0.78), 0.58].enumerated() {
                let s = CGPoint(x: w * 0.5, y: h * y)
                ctx.fill(leafPath(base: s, angleDeg: -58, length: h * (0.22 - CGFloat(i) * 0.03), width: w * 0.16),
                         with: .color(i.isMultiple(of: 2) ? p.foliage : p.foliageDeep))
                ctx.fill(leafPath(base: s, angleDeg: 58, length: h * (0.22 - CGFloat(i) * 0.03), width: w * 0.16),
                         with: .color(i.isMultiple(of: 2) ? p.foliageDeep : p.foliage))
            }
            ctx.fill(leafPath(base: tip, angleDeg: 0, length: h * 0.12, width: w * 0.10), with: .color(p.foliage))
        }
    }

    @ViewBuilder static func bud(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let head = CGPoint(x: w * 0.5, y: h * 0.36)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.46), bow: w * 0.015),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.038, lineCap: .round))
            let s = CGPoint(x: w * 0.5, y: h * 0.70)
            ctx.fill(leafPath(base: s, angleDeg: -56, length: h * 0.18, width: w * 0.15), with: .color(p.foliage))
            ctx.fill(leafPath(base: s, angleDeg: 56, length: h * 0.18, width: w * 0.15), with: .color(p.foliageDeep))
            // big green bud: pointed sepals radiating around a dome, hint of yellow
            for ang in stride(from: -70.0, through: 70.0, by: 20.0) {
                ctx.fill(leafPath(base: head, angleDeg: ang, length: h * 0.13, width: w * 0.07),
                         with: .color(Int(ang) % 40 == 0 ? p.foliage : p.foliageDeep))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5 - w * 0.11, y: h * 0.30, width: w * 0.22, height: h * 0.14)),
                     with: .color(p.foliage))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5 - w * 0.05, y: h * 0.315, width: w * 0.10, height: h * 0.06)),
                     with: .color(p.bloom))
        }
    }

    @ViewBuilder static func bloom(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let center = CGPoint(x: w * 0.5, y: h * 0.33)
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.50), bow: w * 0.012),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.038, lineCap: .round))
            let s = CGPoint(x: w * 0.5, y: h * 0.72)
            ctx.fill(leafPath(base: s, angleDeg: -56, length: h * 0.16, width: w * 0.14), with: .color(p.foliage))
            ctx.fill(leafPath(base: s, angleDeg: 56, length: h * 0.16, width: w * 0.14), with: .color(p.foliageDeep))
            // long golden ray petals: back ring (amber) + front ring (gold)
            let R = w * 0.32
            petalRing(ctx, center: center, count: 22, baseRadius: R * 0.44, length: R * 0.52, width: w * 0.05, color: p.bloomDeep, phaseDeg: 8)
            petalRing(ctx, center: center, count: 22, baseRadius: R * 0.42, length: R * 0.50, width: w * 0.052, color: p.bloom, phaseDeg: 0)
            // large seed disk
            let dr = R * 0.46
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - dr, y: center.y - dr, width: dr * 2, height: dr * 2)),
                     with: .color(p.center))
            // stippled seeds: concentric rings of tiny dots (deterministic)
            for ring in 1...3 {
                let rr = dr * CGFloat(ring) / 3.4
                let count = ring * 8
                for i in 0..<count {
                    let t = Double(i) / Double(count) * 2 * .pi + Double(ring)
                    let pt = CGPoint(x: center.x + CGFloat(sin(t)) * rr, y: center.y - CGFloat(cos(t)) * rr)
                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x - dr * 0.05, y: pt.y - dr * 0.05, width: dr * 0.10, height: dr * 0.10)),
                             with: .color(p.bloomDeep.opacity(0.55)))
                }
            }
        }
    }
}
