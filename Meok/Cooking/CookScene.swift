import SpriteKit
import StrokeEngine

/// The kitchen canvas: paper, and the dish you just cooked painting itself in
/// (bowl or skewer) above the menu.
final class CookScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private var dishNode: RecipeNode?
    private var pendingArchetype: String?

    override init() {
        super.init(size: .zero)
        scaleMode = .resizeFill
        backgroundColor = .white
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
        if let archetype = pendingArchetype { showDish(archetype: archetype) }
    }

    func showDish(archetype: String) {
        pendingArchetype = archetype
        guard size.width > 0, size.height > 0 else { return }
        dishNode?.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        guard let recipe = Recipes.dishArt[archetype] else { return }
        let scale = size.width * 0.5
        let node = RecipeNode(recipe: recipe, scale: scale)
        // Upper area — the menu sits below.
        node.position = CGPoint(x: size.width / 2 - scale / 2, y: size.height * 0.66 - scale / 2)
        node.zPosition = 3
        addChild(node)
        node.reveal()
        dishNode = node
    }
}
