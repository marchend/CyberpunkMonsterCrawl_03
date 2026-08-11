import XCTest
import SpriteKit
@testable import CyberpunkMonsterCrawl

/// SCAFFOLDING(CYBERPUN-16-1) -- paired with, and removed with, the empty
/// placeholder `SKScene` in `App/GameViewController.swift`.
///
/// The original trigger was "delete when the real suites land"; the asset
/// contract half of that HAS now landed (`AtlasTextureLoaderTests` and the
/// CYBERPUN-16-1-t4 gate suite), so the trigger is restated precisely: this
/// file exists only for as long as `GameViewController` hosts a placeholder
/// scene with nothing to assert about. When that placeholder is replaced by a
/// real scene, this file's link-only check is subsumed by that scene's tests
/// and BOTH markers go at once. The remaining suites the old comment named
/// (state machine, IsoGrid round-trip, depth model) are deferred and are NOT
/// what gates this file's removal.
///
/// It is bootstrap-only: it proves the test target builds, links against the
/// host app target (`TEST_HOST`/`BUNDLE_LOADER` wiring in project.yml), and
/// runs. It asserts nothing about gameplay because there is no gameplay yet,
/// so a green run here is NOT evidence of any product gate -- see AGENT.md ->
/// "Open gates". Grep `SCAFFOLDING(` before closing CYBERPUN-16-1: this
/// marker must be deleted, or re-pointed at a live ticket, in the same PR
/// that closes CYBERPUN-16-1, so it never outlives the ticket that owns it.
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
