import SpriteKit

/// Bootstrap Hello-World scene: proves SpriteKit renders. Future PRs
/// replace this with the real menu / gameplay / death / highScores states,
/// the IsoGrid world, and the three-layer node stack.
final class GameScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)

        let label = SKLabelNode(text: "CyberpunkMonsterCrawl_03")
        label.fontName = "Menlo-Bold"
        label.fontSize = 24
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)
    }
}
