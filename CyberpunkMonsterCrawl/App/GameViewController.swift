import UIKit
import SpriteKit

/// Minimal SpriteKit host: presents a single, empty `SKScene` so the app
/// target is a valid, launchable SpriteKit host. Bootstrap-only -- no
/// gameplay content. Future PRs replace the empty scene with the real
/// menu -> gameplay -> death -> highScores state machine and the
/// world/HUD/overlay layer stack.
final class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)

        let scene = SKScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .black
        skView.presentScene(scene)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
}
