import UIKit
import SpriteKit

/// Hosts the SpriteKit view. Bootstrap-only: presents a single scene with a
/// centered label. Future PRs replace `GameScene` with the real
/// menu -> gameplay -> death -> highScores state machine.
final class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)

        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
}
