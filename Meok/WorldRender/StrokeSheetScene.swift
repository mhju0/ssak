#if DEBUG
import SpriteKit
import StrokeEngine

/// Dev-only eyeball-review sheet: a grid of strokes exercising each ink
/// dynamic. Tap anywhere to replay the reveal.
final class StrokeSheetScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private var recipes: [RecipeNode] = []

    override init() {
        super.init(size: .zero)
        scaleMode = .resizeFill
        paper.shader = PaperShader.make()
        addChild(paper)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }
        paper.position = CGPoint(x: size.width / 2, y: size.height / 2)
        paper.size = size
        paper.shader?.uniformNamed("u_size")?.vectorFloat2Value =
            vector_float2(Float(size.width), Float(size.height))
        layoutCells()
    }

    private func layoutCells() {
        recipes.forEach { $0.removeFromParent() }
        children.filter { $0 is SKLabelNode }.forEach { $0.removeFromParent() }
        recipes = []

        // An S-curve used by several cells, for like-for-like comparison.
        let sCurve = [
            StrokePoint(0.05, 0.25, pressure: 0.25),
            StrokePoint(0.35, 0.55, pressure: 0.9),
            StrokePoint(0.68, 0.35, pressure: 0.55),
            StrokePoint(0.95, 0.72, pressure: 0.2),
        ]
        let shortBar = [
            StrokePoint(0.1, 0.5, pressure: 0.85),
            StrokePoint(0.9, 0.55, pressure: 0.7),
        ]
        // An ensō-like circle: charm smoke-test for curved strokes.
        let circle: [StrokePoint] = (0 ... 9).map { i in
            let a = Double(i) / 9 * 2 * .pi * 0.96 + .pi / 2
            let wobble = 1 + 0.03 * sin(Double(i) * 2.4)
            return StrokePoint(
                0.5 + cos(a) * 0.38 * wobble,
                0.5 + sin(a) * 0.38 * wobble,
                pressure: 0.75 - 0.45 * Double(i) / 9
            )
        }

        let cells: [(String, StrokeRecipe, RenderStyle)] = [
            ("pressure taper", recipe(points: [
                StrokePoint(0.05, 0.5, pressure: 1.0),
                StrokePoint(0.95, 0.55, pressure: 0.08),
            ], width: 0.16), RenderStyle()),
            ("pressure swell", recipe(points: sCurve, width: 0.13), RenderStyle()),
            ("dry 0.35", recipe(points: sCurve, width: 0.13, dryness: 0.35), RenderStyle()),
            ("dry 0.75", recipe(points: sCurve, width: 0.13, dryness: 0.75), RenderStyle()),
            ("pool 0", recipe(points: shortBar, width: 0.15, pooling: 0), RenderStyle()),
            ("pool 0.9", recipe(points: shortBar, width: 0.15, pooling: 0.9), RenderStyle()),
            ("wet 0.75", recipe(points: sCurve, width: 0.13), RenderStyle(wetness: 0.75)),
            ("ensō · dry finish", StrokeRecipe(strokes: [
                Stroke(points: circle, width: 0.11, dryness: 0.45, pooling: 0.6, duration: 1.1)
            ]), RenderStyle()),
        ]

        let columns = 2
        let cellW = size.width / CGFloat(columns)
        let topInset = 0.08 * size.height
        let cellH = (size.height - topInset * 1.5) / CGFloat((cells.count + 1) / columns)
        let inkScale = cellW * 0.82

        for (index, cell) in cells.enumerated() {
            let column = index % columns
            let row = index / columns
            let origin = CGPoint(
                x: (CGFloat(column) + 0.09) * cellW,
                y: size.height - topInset - (CGFloat(row) + 0.92) * cellH
            )

            let node = RecipeNode(recipe: cell.1, style: cell.2, scale: inkScale * 0.8)
            node.position = origin
            node.zPosition = 2
            addChild(node)
            recipes.append(node)

            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = cell.0
            label.fontSize = 11
            label.fontColor = UIColor(white: 0.35, alpha: 0.8)
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: origin.x, y: origin.y - 14)
            label.zPosition = 2
            addChild(label)
        }
        replay()
    }

    private func recipe(
        points: [StrokePoint], width: Double,
        dryness: Double = 0.15, pooling: Double = 0.5
    ) -> StrokeRecipe {
        StrokeRecipe(strokes: [
            Stroke(points: points, width: width, dryness: dryness, pooling: pooling, duration: 0.7)
        ])
    }

    func replay() {
        for (index, node) in recipes.enumerated() {
            node.reveal(after: Double(index) * 0.15)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        replay()
    }
}
#endif
