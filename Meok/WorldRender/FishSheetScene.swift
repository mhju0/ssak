#if DEBUG
import SpriteKit
import GameKernel
import StrokeEngine

/// Dev-only: the whole species art table on one sheet, ledger order.
/// Tap to replay the reveals.
final class FishSheetScene: SKScene {
    private let paper = SKSpriteNode(texture: .flatWhite)
    private var fish: [RecipeNode] = []

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
        fish.forEach { $0.removeFromParent() }
        children.filter { $0 is SKLabelNode }.forEach { $0.removeFromParent() }
        fish = []

        // Unlock order, two columns.
        let species = FishingTable.all.sorted {
            ($0.unlockLevel, $0.id) < ($1.unlockLevel, $1.id)
        }
        let columns = 2
        let rows = (species.count + columns - 1) / columns
        let cellW = size.width / CGFloat(columns)
        let cellH = size.height * 0.96 / CGFloat(rows)
        let inkScale = cellW * 0.92

        for (index, entry) in species.enumerated() {
            guard let recipe = Recipes.fish[entry.id] else { continue }
            let column = index % columns
            let row = index / columns
            let originX = CGFloat(column) * cellW + cellW * 0.04
            // Recipes occupy roughly the middle half of their unit square;
            // shift so each sits centered in its cell.
            let originY = size.height * 0.98 - CGFloat(row + 1) * cellH

            let node = RecipeNode(recipe: recipe, scale: inkScale)
            node.position = CGPoint(x: originX, y: originY - inkScale * 0.5 + cellH * 0.5)
            node.zPosition = 2
            addChild(node)
            fish.append(node)

            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = "\(entry.nameKO) L\(entry.unlockLevel)"
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
        for (index, node) in fish.enumerated() {
            node.reveal(after: Double(index) * 0.25)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        replay()
    }
}
#endif
