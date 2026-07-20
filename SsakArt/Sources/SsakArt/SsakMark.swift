import SwiftUI

// The Bloom-Point sprout mark (spec §2.6, Appendix A): two cotyledons framing a furled
// gold bud. One SwiftUI source reused as app-icon proof, hero watermark, and shelf glyph.
// Geometry is authored in Appendix A's 220×220 space and scaled to the view's rect.

/// The Appendix A mark parts, scaled into `rect` (220-space → rect).
private func markParts(in rect: CGRect) -> (left: Path, right: Path, bud: Path, stem: Path) {
    func p(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: rect.minX + x / 220 * rect.width, y: rect.minY + y / 220 * rect.height)
    }
    var left = Path()
    left.move(to: p(108, 147))
    left.addCurve(to: p(54, 122), control1: p(88, 151), control2: p(64, 145))
    left.addCurve(to: p(108, 147), control1: p(66, 112), control2: p(90, 128))
    left.closeSubpath()

    var right = Path()
    right.move(to: p(112, 147))
    right.addCurve(to: p(166, 124), control1: p(132, 151), control2: p(156, 145))
    right.addCurve(to: p(112, 147), control1: p(154, 114), control2: p(130, 130))
    right.closeSubpath()

    var bud = Path()
    bud.move(to: p(110, 146))
    bud.addCurve(to: p(106, 60), control1: p(94, 120), control2: p(96, 88))
    bud.addCurve(to: p(114, 60), control1: p(107, 55), control2: p(113, 55))
    bud.addCurve(to: p(110, 146), control1: p(124, 88), control2: p(126, 120))
    bud.closeSubpath()

    var stem = Path()
    stem.move(to: p(110, 146))
    stem.addCurve(to: p(110, 166), control1: p(110, 154), control2: p(110, 160))
    return (left, right, bud, stem)
}

/// The pure filled silhouette of the mark — reused cross-module by `SpeciesWatermark`
/// (species-tinted, faint) and `BloomCard` (ghosted watermark), and by the `.mono`/`.glass`
/// variants. **Public** because those consumers live in the SsakApp module.
public struct SsakMarkPath: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        let m = markParts(in: rect)
        var p = Path()
        p.addPath(m.left); p.addPath(m.right); p.addPath(m.bud)
        // stem as a slim rounded bar (a stroke can't be part of a fill silhouette)
        let w = 8 / 220 * rect.width
        p.addRoundedRect(in: CGRect(x: rect.minX + 110 / 220 * rect.width - w / 2,
                                    y: rect.minY + 146 / 220 * rect.height,
                                    width: w, height: 20 / 220 * rect.height),
                         cornerSize: CGSize(width: w / 2, height: w / 2))
        return p
    }
}

/// The sprout mark in one of five appearances (spec §3.2). `light`/`dark`/`tinted` are the
/// full-color styled marks (Appendix A recipes); `mono` is a single-color silhouette (shelf
/// glyph, watermark base); `glass` is a translucent relief for glass composition.
public struct SsakMark: View {
    public enum Variant { case light, dark, tinted, mono, glass }
    let variant: Variant
    public init(_ variant: Variant = .light) { self.variant = variant }

    public var body: some View {
        switch variant {
        case .mono:
            SsakMarkPath().fill(Color(red: 0.43, green: 0.55, blue: 0.38).opacity(0.9))   // muted sage
        case .glass:
            SsakMarkPath().fill(.white.opacity(0.55))
                .overlay(SsakMarkPath().stroke(.white.opacity(0.35), lineWidth: 1))
        case .light:  styled(leafL: (0x7EBA61, 0x4C8642), leafR: (0x6BA956, 0x47823E),
                             bud: (0xF7CE78, 0xE1962C), stem: 0x4C8642)
        case .dark:   styled(leafL: (0x8AC86C, 0x4F9145), leafR: (0x8AC86C, 0x4F9145),
                             bud: (0xFAD583, 0xE89B32), stem: 0x4F9145)
        case .tinted: styled(leafL: (0xA9B49A, 0x6E7A66), leafR: (0xA9B49A, 0x6E7A66),
                             bud: (0xDCE7C8, 0xB9C4A8), stem: 0x6E7A66)   // grayscale, bud lightest
        }
    }

    /// Canvas-drawn styled mark (matches SsakArt's existing Canvas-path idiom).
    private func styled(leafL: (UInt, UInt), leafR: (UInt, UInt),
                        bud: (UInt, UInt), stem: UInt) -> some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            let m = markParts(in: rect)
            let top = CGPoint(x: size.width / 2, y: 0), bot = CGPoint(x: size.width / 2, y: size.height)
            ctx.stroke(m.stem, with: .color(c(stem)),
                       style: StrokeStyle(lineWidth: 8 / 220 * size.width, lineCap: .round))
            ctx.fill(m.left,  with: .linearGradient(Gradient(colors: [c(leafL.0), c(leafL.1)]), startPoint: top, endPoint: bot))
            ctx.fill(m.right, with: .linearGradient(Gradient(colors: [c(leafR.0), c(leafR.1)]), startPoint: top, endPoint: bot))
            ctx.fill(m.bud,   with: .linearGradient(Gradient(colors: [c(bud.0), c(bud.1)]), startPoint: top, endPoint: bot))
        }
    }

    private func c(_ hex: UInt) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }
}
