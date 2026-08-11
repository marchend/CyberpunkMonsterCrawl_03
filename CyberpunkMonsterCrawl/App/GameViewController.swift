import UIKit
import SpriteKit

/// Minimal SpriteKit host: presents a single, empty `SKScene` so the app
/// target is a valid, launchable SpriteKit host. Bootstrap-only -- no
/// gameplay content.
///
/// SCAFFOLDING(CYBERPUN-16-1) -- the empty placeholder scene created in
/// `viewDidLoad()` below is removed by CYBERPUN-16-1's remaining work, which
/// replaces it with the real menu -> gameplay -> death -> highScores state
/// machine and the world/HUD/overlay layer stack. Grep `SCAFFOLDING(` before
/// closing that ticket; the paired scaffolding is
/// `CyberpunkMonsterCrawlTests/BootstrapSmokeTests.swift`.
final class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)

        // SCAFFOLDING(CYBERPUN-16-1): placeholder empty black scene.
        let scene = SKScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .black
        skView.presentScene(scene)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
}
