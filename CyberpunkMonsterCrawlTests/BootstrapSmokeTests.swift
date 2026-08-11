import XCTest
@testable import CyberpunkMonsterCrawl

/// Bootstrap-only smoke test: proves the test target builds, links against
/// the host app target (`TEST_HOST`/`BUNDLE_LOADER` wiring in project.yml),
/// and runs. There is no behavior to test yet -- real tests (state machine,
/// asset contract, IsoGrid round-trip, depth model) land in PR 3/4.
final class BootstrapSmokeTests: XCTestCase {
    func test_bootstrapTargetLinksAgainstHostApp() {
        // Instantiating a real app-module type proves `@testable import
        // CyberpunkMonsterCrawl` resolves and the test bundle is correctly
        // hosted by the app target.
        _ = GameViewController()
        XCTAssertTrue(true)
    }
}
