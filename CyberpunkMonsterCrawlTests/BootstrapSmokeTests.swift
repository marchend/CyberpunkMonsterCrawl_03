import XCTest
import SpriteKit
@testable import CyberpunkMonsterCrawl

/// SCAFFOLDING(CYBERPUN-16-1) -- delete this whole file when the real suites
/// land (state machine, asset contract, IsoGrid round-trip, depth model).
/// It is bootstrap-only: it proves the test target builds, links against the
/// host app target (`TEST_HOST`/`BUNDLE_LOADER` wiring in project.yml), and
/// runs. It asserts nothing about gameplay because there is no gameplay yet,
/// so a green run here is NOT evidence of any product gate -- see AGENT.md ->
/// "Open gates". Grep `SCAFFOLDING(` before closing CYBERPUN-16-1.
final class BootstrapSmokeTests: XCTestCase {
    func test_bootstrapTargetLinksAgainstHostApp() throws {
        // Instantiating a real app-module type proves `@testable import
        // CyberpunkMonsterCrawl` resolves and the test bundle is correctly
        // hosted by the app target. The assertions below are deliberately
        // observable (rather than a tautological `XCTAssertTrue(true)`) so
        // this test can actually fail if the SpriteKit host stops wiring
        // itself up.
        let sut = GameViewController()
        sut.loadViewIfNeeded()

        let skView = try XCTUnwrap(
            sut.view.subviews.compactMap { $0 as? SKView }.first,
            "GameViewController should host an SKView after loading its view"
        )
        XCTAssertNotNil(
            skView.scene,
            "GameViewController should present a scene in its SKView"
        )
    }
}
