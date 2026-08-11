import UIKit

/// App entry point. Bootstrap-only: presents a blank placeholder root view
/// (`GameViewController`, hosting an empty `SKScene`) -- no game logic, no
/// menu/state machine yet (those land in later PRs).
///
/// Uses the legacy (non-scene) `UIApplicationDelegate.window` lifecycle so
/// the whole entry point is a single file -- no `SceneDelegate`, and no
/// SwiftUI (per docs/bootstrap.md's "no SwiftUI game layer" decision: all
/// rendering, including future menus/HUD, stays SpriteKit-in-UIKit). Info.plist
/// deliberately omits `UIApplicationSceneManifest`, which is what opts an app
/// into the scene-based lifecycle; without it, iOS falls back to this
/// `window`-property based lifecycle.
@main
final class CyberpunkMonsterCrawlApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = GameViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
