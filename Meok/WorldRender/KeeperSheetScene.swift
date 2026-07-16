#if DEBUG
import SpriteKit
import StrokeEngine

/// Dev-only: the keeper's two poses — large for inspection, and at true
/// staffage scale, tiny against the vast page. Tap to replay.
final class KeeperSheetScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private var figures: [RecipeNode] = []

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
        figures.forEach { $0.removeFromParent() }
        children.filter { $0 is SKLabelNode }.forEach { $0.removeFromParent() }
        figures = []

        // Large, for stroke inspection.
        add(Recipes.keeperStanding, at: CGPoint(x: size.width * 0.06, y: size.height * 0.55),
            scale: size.width * 0.42, label: "standing")
        add(Recipes.keeperSeated, at: CGPoint(x: size.width * 0.54, y: size.height * 0.55),
            scale: size.width * 0.42, label: "seated")

        // Staffage scale: ~4% of the page, the classical 산수화 proportion.
        let tiny = size.height * 0.055
        add(Recipes.keeperStanding, at: CGPoint(x: size.width * 0.30, y: size.height * 0.24),
            scale: tiny, label: nil)
        add(Recipes.keeperSeated, at: CGPoint(x: size.width * 0.62, y: size.height * 0.24),
            scale: tiny, label: nil)

        let caption = SKLabelNode(fontNamed: "Menlo")
        caption.text = "staffage scale"
        caption.fontSize = 11
        caption.fontColor = UIColor(white: 0.35, alpha: 0.8)
        caption.horizontalAlignmentMode = .left
        caption.position = CGPoint(x: size.width * 0.06, y: size.height * 0.20)
        caption.zPosition = 2
        addChild(caption)

        replay()
    }

    private func add(_ recipe: StrokeRecipe, at position: CGPoint, scale: CGFloat, label: String?) {
        let node = RecipeNode(recipe: recipe, scale: scale)
        node.position = position
        node.zPosition = 2
        addChild(node)
        figures.append(node)

        if let label {
            let text = SKLabelNode(fontNamed: "Menlo")
            text.text = label
            text.fontSize = 11
            text.fontColor = UIColor(white: 0.35, alpha: 0.8)
            text.horizontalAlignmentMode = .left
            text.position = CGPoint(x: position.x + scale * 0.1, y: position.y - 16)
            text.zPosition = 2
            addChild(text)
        }
    }

    func replay() {
        for (index, node) in figures.enumerated() {
            node.reveal(after: Double(index) * 0.3)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        replay()
    }
}
#endif
