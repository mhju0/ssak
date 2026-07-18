import SpriteKit
import StrokeEngine

/// The kitchen / workbench canvas: paper, and the thing you just made (a dish
/// or a tool) painting itself in above the menu. `art` is the archetype recipe
/// table — Recipes.dishArt for cooking, Recipes.craftArt for crafting.
final class MakerScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private let art: [String: StrokeRecipe]
    private var madeNode: RecipeNode?
    private var pendingArchetype: String?

    init(art: [String: StrokeRecipe]) {
        self.art = art
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
        if let archetype = pendingArchetype { showItem(archetype: archetype) }
    }

    func showItem(archetype: String) {
        pendingArchetype = archetype
        guard size.width > 0, size.height > 0 else { return }
        madeNode?.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        guard let recipe = art[archetype] else { return }
        let scale = size.width * 0.5
        let node = RecipeNode(recipe: recipe, scale: scale)
        node.position = CGPoint(x: size.width / 2 - scale / 2, y: size.height * 0.66 - scale / 2)
        node.zPosition = 3
        addChild(node)
        node.reveal()
        madeNode = node
    }
}
