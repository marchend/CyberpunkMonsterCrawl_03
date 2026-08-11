import SpriteKit
import XCTest
@testable import CyberpunkMonsterCrawl

/// What this file gates, stated precisely: **every texture
/// `AtlasTextureLoader` vends, for every id in the catalog, comes back
/// nearest-filtered with mipmaps off.** A catalog-wide sweep of the loader's
/// output, not a spot check.
///
/// `AtlasTextureLoaderTests` already proves nearest-filtering/no-mipmaps as
/// part of testing the loader's OWN mechanics
/// (`test_sheetTexture_appliesNearestFilteringAndDisablesMipmaps` /
/// `test_cellTexture_appliesNearestFilteringAndDisablesMipmaps`), but only
/// against a couple of `PickupAtlas` textures. This file widens that to
/// EVERY sheet texture, EVERY family's cell textures, EVERY ground-tileset
/// diamond, and EVERY building sprite the loader can vend, so
/// `AtlasTextureLoader.applyPixelArtFiltering` is shown to be
/// content-agnostic rather than known-good on one small sheet.
///
/// **What this file does NOT gate -- and cannot, as written.** Every texture
/// here is constructed by the test itself through `loader.sheetTexture` /
/// `cellTexture` / `texture(named:pixelRect:)`. A production call site that
/// bypasses `AtlasTextureLoader` entirely -- e.g. one reaching for
/// `SKTexture(imageNamed:)` directly -- is INVISIBLE to this suite: these
/// tests stay green while that sprite renders linear-filtered on device.
/// The broader "no linear filtering anywhere in the app" property needs a
/// consumer-side check (every node that gets a texture got it from the
/// loader), which cannot be written until there is a rendering consumer to
/// check; it must land with the first such consumer, under its own named
/// ticket. Do not read a green run here as that stronger property.
///
/// Buildings are not sliced, and production code never routes them through
/// `AtlasTextureLoader` today (`BuildingSet.load` reads `UIImage(named:)`
/// directly, see its doc comment) -- but `AtlasTextureLoader.sheetTexture(named:)`
/// accepts ANY catalog name, so this sweep loads each building id through
/// the loader too. That is asserting a HYPOTHETICAL path (hence the `wouldBe`
/// in the building test's name): it proves the loader's filtering logic
/// would apply correctly the moment a building consumer adopts the loader.
/// It proves nothing about how buildings reach the screen today, because
/// nothing renders them yet. Routing `BuildingSet` through the loader (or
/// adding the consumer-side check above) is what would turn this into a real
/// gate for buildings.
final class TextureFilteringGateTests: XCTestCase {
    private var loader: AtlasTextureLoader!

    override func setUp() {
        super.setUp()
        loader = AtlasTextureLoader()
    }

    override func tearDown() {
        loader = nil
        super.tearDown()
    }

    // MARK: - Every AtlasFamily sheet texture

    func test_everyAtlasFamilySheetTexture_isNearestFilteredWithNoMipmaps() throws {
        for family in AtlasFamilyUnderContract.all {
            let texture = try loader.sheetTexture(named: family.sheetName)
            XCTAssertEqual(texture.filteringMode, .nearest, "\(family.sheetName) sheet texture")
            XCTAssertFalse(texture.usesMipmaps, "\(family.sheetName) sheet texture")
        }
        let groundTexture = try loader.sheetTexture(named: GroundTileset.sheetName)
        XCTAssertEqual(groundTexture.filteringMode, .nearest, "\(GroundTileset.sheetName) sheet texture")
        XCTAssertFalse(groundTexture.usesMipmaps, "\(GroundTileset.sheetName) sheet texture")
    }

    // MARK: - Every AtlasFamily's (0,0) cell texture

    func test_everyAtlasFamilyCellTexture_isNearestFilteredWithNoMipmaps() throws {
        try assertCellTextureIsPixelArtFiltered(PlayerAtlas.self)
        try assertCellTextureIsPixelArtFiltered(WeaponAtlas.self)
        try assertCellTextureIsPixelArtFiltered(RaccoonWalkAtlas.self)
        try assertCellTextureIsPixelArtFiltered(RaccoonAttackAtlas.self)
        try assertCellTextureIsPixelArtFiltered(BulletAtlas.self)
        try assertCellTextureIsPixelArtFiltered(PulseAtlas.self)
        try assertCellTextureIsPixelArtFiltered(HitPuffAtlas.self)
        try assertCellTextureIsPixelArtFiltered(PickupAtlas.self)
        try assertCellTextureIsPixelArtFiltered(SignAtlas.self)
    }

    private func assertCellTextureIsPixelArtFiltered<Family: AtlasFamily>(
        _ family: Family.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let texture = try loader.cellTexture(for: family, row: 0, col: 0)
        XCTAssertEqual(texture.filteringMode, .nearest, "\(Family.sheetName) (0,0) cell texture", file: file, line: line)
        XCTAssertFalse(texture.usesMipmaps, "\(Family.sheetName) (0,0) cell texture", file: file, line: line)
    }

    // MARK: - Every ground-tileset diamond

    func test_everyGroundDiamond_isNearestFilteredWithNoMipmaps() throws {
        for diamond in GroundTileset.Diamond.allCases {
            let texture = try loader.texture(
                named: GroundTileset.sheetName,
                pixelRect: GroundTileset.rect(for: diamond),
                sheetSize: GroundTileset.sheetSize
            )
            XCTAssertEqual(texture.filteringMode, .nearest, "\(diamond)")
            XCTAssertFalse(texture.usesMipmaps, "\(diamond)")
        }
    }

    // MARK: - Every building sprite, loaded through the loader

    /// A hypothetical path, deliberately named `wouldBe`: `BuildingSet.load`
    /// never vends an `SKTexture` today, so this asserts what the loader
    /// WOULD return for each building id, not how buildings actually reach
    /// the screen. See this file's header note on the consumer-side check
    /// this cannot replace.
    func test_everyBuildingSprite_wouldBeNearestFilteredWithNoMipmapsThroughTheLoader() throws {
        XCTAssertEqual(BuildingSet.definitions.count, 12)
        for definition in BuildingSet.definitions {
            let texture = try loader.sheetTexture(named: definition.assetName)
            XCTAssertEqual(texture.filteringMode, .nearest, "\(definition.assetName)")
            XCTAssertFalse(texture.usesMipmaps, "\(definition.assetName)")
        }
    }

    // MARK: - Alpha sanity: transparency survives for every building, swept alongside filtering

    /// `ImageAlphaInspector` proves the same "not flattened" fact
    /// `BuildingSetTests.test_everyBuilding_hasNonOpaqueCornerPixels` proves
    /// per-corner via `PixelProbe` -- swept here too, whole-image, over the
    /// same building ids this file already iterates for filtering. The
    /// inspector is a thin façade that composes a `PixelProbe`, so both
    /// sweeps run through the one rasterizer in the test target.
    func test_everyBuildingSprite_hasSomeNonOpaqueAndSomePaintedPixel() throws {
        for definition in BuildingSet.definitions {
            let inspector = try ImageAlphaInspector(assetName: definition.assetName)
            XCTAssertTrue(inspector.hasAnyNonOpaquePixel, "\(definition.assetName) has no non-opaque pixel anywhere -- transparency looks flattened")
            XCTAssertTrue(inspector.hasAnyPaintedPixel, "\(definition.assetName) has no painted pixel at all -- looks like an empty imageset")
        }
    }
}
