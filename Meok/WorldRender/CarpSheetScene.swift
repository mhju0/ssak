#if DEBUG
import SpriteKit
import StrokeEngine

/// Dev-only: the carp recipe rendered twice from the same data —
/// dry above, soaked below. Tap to replay the reveal.
final class CarpSheetScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private var carps: [RecipeNode] = []

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
        layout()
    }

    private func layout() {
        carps.forEach { $0.removeFromParent() }
        children.filter { $0 is SKLabelNode }.forEach { $0.removeFromParent() }
        carps = []

        let inkScale = size.width * 0.94
        let variants: [(String, RenderStyle, CGFloat)] = [
            ("dry", RenderStyle(), size.height * 0.52),
            ("wet 0.7 — same recipe", RenderStyle(wetness: 0.7), size.height * 0.10),
        ]

        for (text, style, bottom) in variants {
            let node = RecipeNode(recipe: Recipes.carp, style: style, scale: inkScale)
            node.position = CGPoint(x: size.width * 0.03, y: bottom)
            node.zPosition = 2
            addChild(node)
            carps.append(node)

            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = text
            label.fontSize = 11
            label.fontColor = UIColor(white: 0.35, alpha: 0.8)
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: size.width * 0.06, y: bottom + size.height * 0.015)
            label.zPosition = 2
            addChild(label)
        }
        replay()
    }

    func replay() {
        for (index, node) in carps.enumerated() {
            node.reveal(after: Double(index) * 0.4)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        replay()
    }
}
#endif
