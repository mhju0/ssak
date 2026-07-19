import SwiftUI

// MARK: - Shared drawing helpers (absolute-coordinate paths, hand-authored)

/// An almond leaf from `base` to a tip `length` away at `angleDeg` from vertical
/// (0 = straight up, positive = lean right), bulging by `width` across the middle.
func leafPath(base: CGPoint, angleDeg: Double, length: CGFloat, width: CGFloat) -> Path {
    let a = angleDeg * .pi / 180
    let dir = CGVector(dx: sin(a), dy: -cos(a))
    let perp = CGVector(dx: cos(a), dy: sin(a))
    let tip = CGPoint(x: base.x + dir.dx * length, y: base.y + dir.dy * length)
    let mid = CGPoint(x: base.x + dir.dx * length * 0.48, y: base.y + dir.dy * length * 0.48)
    let left = CGPoint(x: mid.x - perp.dx * width / 2, y: mid.y - perp.dy * width / 2)
    let right = CGPoint(x: mid.x + perp.dx * width / 2, y: mid.y + perp.dy * width / 2)
    var p = Path()
    p.move(to: base)
    p.addQuadCurve(to: tip, control: left)
    p.addQuadCurve(to: base, control: right)
    return p
}

/// A curved stem from `base` up to `tip`, bowing sideways by `bow` (points).
func stemPath(base: CGPoint, tip: CGPoint, bow: CGFloat = 0) -> Path {
    let ctrl = CGPoint(x: (base.x + tip.x) / 2 + bow, y: (base.y + tip.y) / 2)
    var p = Path()
    p.move(to: base)
    p.addQuadCurve(to: tip, control: ctrl)
    return p
}

/// A ferny marigold frond at `base`: a central leaflet along `angleDeg` plus two
/// side pairs, giving the pinnate look. Returns the combined Path.
func frondPath(base: CGPoint, angleDeg: Double, length: CGFloat, width: CGFloat) -> Path {
    var p = Path()
    p.addPath(leafPath(base: base, angleDeg: angleDeg, length: length, width: width))
    // inner side pair, partway along the rachis
    let a = angleDeg * .pi / 180
    let mid = CGPoint(x: base.x + sin(a) * length * 0.42,
                      y: base.y - cos(a) * length * 0.42)
    p.addPath(leafPath(base: mid, angleDeg: angleDeg - 34, length: length * 0.6, width: width * 0.72))
    p.addPath(leafPath(base: mid, angleDeg: angleDeg + 34, length: length * 0.6, width: width * 0.72))
    return p
}

// MARK: - Marigold stages
// Each stage draws in a Canvas with the SOIL LINE at the bottom (y = height) and
// the plant centered on x = width/2, growing upward. Detail ramps: sprout/leaves
// restrained, bud/bloom lavish.

enum MarigoldArt {

    @ViewBuilder static func sprout(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            // slim stem with a whisper of bow
            ctx.stroke(stemPath(base: base, tip: CGPoint(x: w * 0.5, y: h * 0.60), bow: w * 0.015),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
            // one pair of small cotyledon leaves, attached at the stem
            let lbase = CGPoint(x: w * 0.5, y: h * 0.72)
            ctx.fill(leafPath(base: lbase, angleDeg: -54, length: h * 0.15, width: w * 0.14),
                     with: .color(p.foliage))
            ctx.fill(leafPath(base: lbase, angleDeg: 54, length: h * 0.15, width: w * 0.14),
                     with: .color(p.foliageDeep))
        }
    }

    @ViewBuilder static func leaves(_ p: SpeciesPalette) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = CGPoint(x: w * 0.5, y: h * 0.99)
            let tip = CGPoint(x: w * 0.5, y: h * 0.40)
            ctx.stroke(stemPath(base: base, tip: tip, bow: w * 0.02),
                       with: .color(p.foliageDeep),
                       style: StrokeStyle(lineWidth: w * 0.024, lineCap: .round))
            // fronds up the stem: lower = larger, alternating shade for depth
            let pairs: [(y: CGFloat, len: CGFloat)] = [(0.80, 0.20), (0.66, 0.17), (0.53, 0.13)]
            for (i, f) in pairs.enumerated() {
                let sy = h * f.y
                let sx = w * 0.5
                let backC = p.foliageDeep, frontC = p.foliage
                ctx.fill(frondPath(base: CGPoint(x: sx, y: sy), angleDeg: -58 + Double(i) * 4,
                                   length: h * f.len, width: w * 0.11),
                         with: .color(i.isMultiple(of: 2) ? frontC : backC))
                ctx.fill(frondPath(base: CGPoint(x: sx, y: sy), angleDeg: 58 - Double(i) * 4,
                                   length: h * f.len, width: w * 0.11),
                         with: .color(i.isMultiple(of: 2) ? backC : frontC))
            }
            // a small terminal frond
            ctx.fill(frondPath(base: tip, angleDeg: 0, length: h * 0.11, width: w * 0.10),
                     with: .color(p.foliage))
        }
    }
    @ViewBuilder static func bud(_ p: SpeciesPalette)    -> some View { Placeholder(text: "bud") }
    @ViewBuilder static func bloom(_ p: SpeciesPalette)  -> some View { Placeholder(text: "bloom") }
}

struct Placeholder: View {
    let text: String
    var body: some View {
        Text(text).font(.caption2).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.15))
    }
}
