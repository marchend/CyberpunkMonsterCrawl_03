import XCTest
import SpriteKit
@testable import CyberpunkMonsterCrawl

/// Verifies `AtlasTextureLoader`'s own mechanics -- caching, the pixel-art
/// filtering it applies to every vended texture, and its throwing
/// existence/bounds checks -- against `PickupAtlas`, a real, small catalog
/// entry landed by PR 2. A fresh `AtlasTextureLoader` instance is used per
/// test so cache state never leaks between tests.
final class AtlasTextureLoaderTests: XCTestCase {
    private var loader: AtlasTextureLoader!

    override func setUp() {
        super.setUp()
        loader = AtlasTextureLoader()
    }

    override func tearDown() {
        loader = nil
        super.tearDown()
    }

    func test_sheetTexture_isCachedAcrossRepeatedLookups() throws {
        let first = try loader.sheetTexture(named: PickupAtlas.sheetName)
        let second = try loader.sheetTexture(named: PickupAtlas.sheetName)

        XCTAssertTrue(first === second, "Repeated lookups of the same sheet name should return the cached instance, not reload it")
    }

    func test_sheetTexture_differentNames_areNotCachedTogether() throws {
        let pickup = try loader.sheetTexture(named: PickupAtlas.sheetName)
        let hitPuff = try loader.sheetTexture(named: HitPuffAtlas.sheetName)

        XCTAssertFalse(pickup === hitPuff)
    }

    func test_sheetTexture_missingAsset_throwsMissingAssetWithTheRequestedName() {
        XCTAssertThrowsError(try loader.sheetTexture(named: "does_not_exist_in_catalog")) { error in
            guard case AtlasLoadError.missingAsset(let name) = error else {
                XCTFail("Expected AtlasLoadError.missingAsset, got \(error)")
                return
            }
            XCTAssertEqual(name, "does_not_exist_in_catalog")
        }
    }

    func test_sheetTexture_appliesNearestFilteringAndDisablesMipmaps() throws {
        let texture = try loader.sheetTexture(named: PickupAtlas.sheetName)

        XCTAssertEqual(texture.filteringMode, .nearest)
        XCTAssertFalse(texture.usesMipmaps)
    }

    func test_cellTexture_appliesNearestFilteringAndDisablesMipmaps() throws {
        let texture = try loader.cellTexture(for: PickupAtlas.self, row: 0, col: 0)

        XCTAssertEqual(texture.filteringMode, .nearest)
        XCTAssertFalse(texture.usesMipmaps)
    }

    func test_cellTexture_outOfBounds_throwsIndexOutOfBounds() {
        XCTAssertThrowsError(try loader.cellTexture(for: PickupAtlas.self, row: 99, col: 0)) { error in
            guard case AtlasLoadError.indexOutOfBounds(let name, let row, let col) = error else {
                XCTFail("Expected AtlasLoadError.indexOutOfBounds, got \(error)")
                return
            }
            XCTAssertEqual(name, PickupAtlas.sheetName)
            XCTAssertEqual(row, 99)
            XCTAssertEqual(col, 0)
        }
    }

    func test_cellTexture_negativeColumn_throwsIndexOutOfBounds() {
        XCTAssertThrowsError(try loader.cellTexture(for: PickupAtlas.self, row: 0, col: -1)) { error in
            guard case AtlasLoadError.indexOutOfBounds = error else {
                XCTFail("Expected AtlasLoadError.indexOutOfBounds, got \(error)")
                return
            }
        }
    }

    func test_cellTexture_unknownFamilySheet_throwsMissingAsset() {
        XCTAssertThrowsError(try loader.cellTexture(for: BrokenAtlasFixture.self, row: 0, col: 0)) { error in
            guard case AtlasLoadError.missingAsset(let name) = error else {
                XCTFail("Expected AtlasLoadError.missingAsset, got \(error)")
                return
            }
            XCTAssertEqual(name, BrokenAtlasFixture.sheetName)
        }
    }

    func test_texture_namedPixelRect_appliesNearestFilteringAndDisablesMipmaps() throws {
        // Exercises the arbitrary-pixel-rect entry point used by
        // GroundTileset's non-uniform-grid diamonds.
        let texture = try loader.texture(
            named: PickupAtlas.sheetName,
            pixelRect: PickupAtlas.cellRect(kind: .medKit),
            sheetSize: PickupAtlas.sheetSize
        )

        XCTAssertEqual(texture.filteringMode, .nearest)
        XCTAssertFalse(texture.usesMipmaps)
    }

    /// A fixture family whose sheet doesn't exist in the catalog, used to
    /// exercise the missing-asset path through `cellTexture(for:row:col:)`.
    private struct BrokenAtlasFixture: AtlasFamily {
        static let sheetName = "does_not_exist_in_catalog"
        static let sheetSize = CGSize(width: 10, height: 10)
        static let cellSize = CGSize(width: 10, height: 10)
        static let columns = 1
        static let rows = 1
    }
}
