import CoreGraphics
import Foundation
import SpriteKit
import XCTest
@testable import CyberpunkMonsterCrawl

/// Product gate: "a negative test proves the suite fails when a referenced
/// image id is removed/renamed."
///
/// This file proves the MECHANISM is real -- that `AtlasTextureLoader` (and
/// `BuildingSet`) actually THROW `AtlasLoadError.missingAsset`, with the
/// right associated data, against a deliberately synthetic, guaranteed-absent
/// id, rather than silently substituting SpriteKit's magenta placeholder
/// texture (`SKTexture(imageNamed:)`'s default behavior for an unresolved
/// name -- see `AtlasLoadError`'s doc comment for why `UIImage(named:)` is
/// checked explicitly instead). A synthetic id is used here on purpose: this
/// file is NOT where "delete/rename a REAL asset -> a test fails" gets
/// proved, because that would make the suite's gate depend on the fixture
/// staying in sync with whichever id someone chooses to delete next.
///
/// That composition is deliberate and cross-referenced:
/// - `AtlasSheetDimensionTests` and `AtlasTextureLoaderTests`'
///   `test_everyAtlasFamilySheetName_resolvesInTheCatalog` /
///   `test_theSweepCoversAllTwentyTwoCommittedImagesetIds` are what actually
///   fail if a REAL sheet id is deleted or renamed -- they call
///   `PixelProbe.init` / `loader.sheetTexture(named:)` against the real,
///   named ids from the catalog, so removing one flips those specific
///   assertions red.
/// - `BuildingSetTests.test_loadAll_resolvesEveryBuildingIdInTheCatalog` /
///   `test_everyBuildingDefinition_resolvesInTheCatalog` (in
///   `AtlasTextureLoaderTests`) are the same proof for the 12 building ids.
///
/// Together: this file proves the THROWING PATH works at all; the
/// dimension/building sweeps are what turn "an id went missing" into an
/// actual failure. Neither alone is the whole gate.
final class MissingAssetNegativeTests: XCTestCase {
    /// A UUID suffix makes collision with any real (or future) catalog id
    /// astronomically unlikely, so this can never accidentally start
    /// resolving.
    private let bogusName = "does_not_exist_in_this_catalog_\(UUID().uuidString)"

    private var loader: AtlasTextureLoader!

    override func setUp() {
        super.setUp()
        loader = AtlasTextureLoader()
    }

    override func tearDown() {
        loader = nil
        super.tearDown()
    }

    func test_sheetTexture_bogusId_throwsMissingAssetCarryingTheRequestedName() {
        XCTAssertThrowsError(try loader.sheetTexture(named: bogusName)) { error in
            guard case AtlasLoadError.missingAsset(let name) = error else {
                XCTFail("Expected AtlasLoadError.missingAsset, got \(error)")
                return
            }
            XCTAssertEqual(name, bogusName)
        }
    }

    /// The mechanism must reject a bogus id even through the
    /// arbitrary-pixel-rect entry point `GroundTileset` uses -- asserted
    /// directly, not merely assumed to share the sheet-texture path above.
    func test_texture_namedPixelRect_bogusId_throwsMissingAsset() {
        XCTAssertThrowsError(
            try loader.texture(
                named: bogusName,
                pixelRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                sheetSize: CGSize(width: 1, height: 1)
            )
        ) { error in
            guard case AtlasLoadError.missingAsset(let name) = error else {
                XCTFail("Expected AtlasLoadError.missingAsset, got \(error)")
                return
            }
            XCTAssertEqual(name, bogusName)
        }
    }

    func test_cellTexture_bogusFamilySheet_throwsMissingAsset() {
        XCTAssertThrowsError(try loader.cellTexture(for: BogusFamilyFixture.self, row: 0, col: 0)) { error in
            guard case AtlasLoadError.missingAsset(let name) = error else {
                XCTFail("Expected AtlasLoadError.missingAsset, got \(error)")
                return
            }
            XCTAssertEqual(name, BogusFamilyFixture.sheetName)
        }
    }

    func test_buildingSet_bogusId_throwsMissingAssetCarryingTheRequestedName() {
        XCTAssertThrowsError(
            try BuildingSet.load(assetName: bogusName, footprint: .oneByOne, heightClass: .low)
        ) { error in
            guard case AtlasLoadError.missingAsset(let name) = error else {
                XCTFail("Expected AtlasLoadError.missingAsset, got \(error)")
                return
            }
            XCTAssertEqual(name, bogusName)
        }
    }

    /// `PixelProbe` (used by `AtlasSheetDimensionTests` / `BuildingSetTests`)
    /// throws its own, independent error on the same kind of bogus id --
    /// checked here too, since it is the OTHER mechanism this gate depends
    /// on to catch a real id going missing.
    func test_pixelProbe_bogusId_throwsMissingAsset() {
        XCTAssertThrowsError(try PixelProbe(assetName: bogusName)) { error in
            guard let probeError = error as? PixelProbe.ProbeError,
                  case .missingAsset(let name) = probeError
            else {
                XCTFail("Expected PixelProbe.ProbeError.missingAsset, got \(error)")
                return
            }
            XCTAssertEqual(name, bogusName)
        }
    }

    /// A fixture family whose sheet name is guaranteed absent from the
    /// catalog. Deliberately distinct from
    /// `AtlasTextureLoaderTests.BrokenAtlasFixture` (that one is `private`
    /// to its own file) so this file has no cross-file dependency.
    private struct BogusFamilyFixture: AtlasFamily {
        static let sheetName = "does_not_exist_bogus_family_fixture"
        static let sheetSize = CGSize(width: 10, height: 10)
        static let cellSize = CGSize(width: 10, height: 10)
        static let columns = 1
        static let rows = 1
    }
}
