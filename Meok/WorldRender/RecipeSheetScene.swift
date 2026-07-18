#if DEBUG
import SpriteKit
import GameKernel
import StrokeEngine

/// Dev-only: a grid of stroke recipes with KO labels in unlock order — backs
/// the fish / forage / garden art sheets. Tap to replay the reveals. `kind`
/// lets the host tell one table's sheet from another when switching scenes.
final class RecipeSheetScene: SKScene {
    struct Entry {
        let recipe: StrokeRecipe
        let label: String
    }

    let kind: String
    private let entries: [Entry]
    private let paper = SKSpriteNode(texture: .flatWhite)
    private var nodes: [RecipeNode] = []

    init(kind: String, entries: [Entry]) {
        self.kind = kind
        self.entries = entries
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
        nodes.forEach { $0.removeFromParent() }
        children.filter { $0 is SKLabelNode }.forEach { $0.removeFromParent() }
        nodes = []

        let columns = 2
        let rows = (entries.count + columns - 1) / columns
        let cellW = size.width / CGFloat(columns)
        let cellH = size.height * 0.96 / CGFloat(rows)
        let inkScale = cellW * 0.92

        for (index, entry) in entries.enumerated() {
            let column = index % columns
            let row = index / columns
            let originX = CGFloat(column) * cellW + cellW * 0.04
            let originY = size.height * 0.98 - CGFloat(row + 1) * cellH

            let node = RecipeNode(recipe: entry.recipe, scale: inkScale)
            node.position = CGPoint(x: originX, y: originY - inkScale * 0.5 + cellH * 0.5)
            node.zPosition = 2
            addChild(node)
            nodes.append(node)

            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = entry.label
            label.fontSize = 10
            label.fontColor = UIColor(white: 0.35, alpha: 0.8)
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: originX + inkScale * 0.06, y: originY + cellH * 0.06)
            label.zPosition = 2
            addChild(label)
        }
        replay()
    }

    func replay() {
        for (index, node) in nodes.enumerated() {
            node.reveal(after: Double(index) * 0.22)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        replay()
    }

    // MARK: Tables (unlock order)

    static func fish() -> RecipeSheetScene {
        sheet(kind: "fish", FishingTable.all.map { ($0.id, $0.nameKO, $0.unlockLevel) }, Recipes.fish)
    }

    static func forage() -> RecipeSheetScene {
        sheet(kind: "forage", ForagingTable.all.map { ($0.id, $0.nameKO, $0.unlockLevel) }, Recipes.forage)
    }

    static func garden() -> RecipeSheetScene {
        sheet(kind: "garden", GardenTable.all.map { ($0.id, $0.nameKO, $0.unlockLevel) }, Recipes.garden)
    }

    static func composition() -> RecipeSheetScene {
        sheet(kind: "composition", Artistry.compositions.map { ($0.id, $0.nameKO, $0.unlockLevel) }, Recipes.composition)
    }

    private static func sheet(
        kind: String, _ rows: [(id: String, nameKO: String, level: Int)],
        _ recipes: [String: StrokeRecipe]
    ) -> RecipeSheetScene {
        let entries = rows
            .sorted { ($0.level, $0.id) < ($1.level, $1.id) }
            .compactMap { row in
                recipes[row.id].map { Entry(recipe: $0, label: "\(row.nameKO) L\(row.level)") }
            }
        return RecipeSheetScene(kind: kind, entries: entries)
    }
}
#endif
