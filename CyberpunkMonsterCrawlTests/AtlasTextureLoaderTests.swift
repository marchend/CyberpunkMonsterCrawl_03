import XCTest
import SpriteKit
@testable import CyberpunkMonsterCrawl

/// A type-erased snapshot of one `AtlasFamily`'s recorded contract, so the
/// catalog sweeps below can iterate every family instead of naming a couple
/// of them by hand. Internal (not private) because
/// `SheetRowContentTests` and `GroundTilesetTests` read the same list.
struct AtlasFamilyUnderContract {
    let sheetName: String
    let sheetSize: CGSize
    let cellSize: CGSize
    let columns: Int
    let rows: Int
    let provenance: AssetProvenance
    let cellGridDividesEvenlyIntoSheet: Bool

    init<Family: AtlasFamily>(_ family: Family.Type) {
        sheetName = Family.sheetName
        sheetSize = Family.sheetSize
        cellSize = Family.cellSize
        columns = Family.columns
        rows = Family.rows
        provenance = Family.sheetSizeProvenance
        cellGridDividesEvenlyIntoSheet = Family.cellGridDividesEvenlyIntoSheet
    }

    /// Every `AtlasFamily` conformer in the app target. `GroundTileset` and
    /// `BuildingSet` are deliberately absent (they are not `AtlasFamily`
    /// conformers) and are swept separately by name below, so all 10 sheet
    /// ids plus all 12 building ids are covered.
    static let all: [AtlasFamilyUnderContract] = [
        AtlasFamilyUnderContract(PlayerAtlas.self),
        AtlasFamilyUnderContract(WeaponAtlas.self),
        AtlasFamilyUnderContract(RaccoonWalkAtlas.self),
        AtlasFamilyUnderContract(RaccoonAttackAtlas.self),
        AtlasFamilyUnderContract(BulletAtlas.self),
        AtlasFamilyUnderContract(PulseAtlas.self),
        AtlasFamilyUnderContract(HitPuffAtlas.self),
        AtlasFamilyUnderContract(PickupAtlas.self),
        AtlasFamilyUnderContract(SignAtlas.self),
    ]
}

/// Verifies `AtlasTextureLoader`'s own mechanics -- caching, the pixel-art
/// filtering it applies to every vended texture, and its throwing
/// existence/bounds checks -- against `PickupAtlas`, a real, small catalog
/// entry landed by the asset import in `CYBERPUN-16-1-t2`. A fresh
/// `AtlasTextureLoader` instance is used per test so cache state never leaks
/// between tests.
///
/// It also carries product gate #2's negative test (see `AGENT.md` -> "Open
/// gates"): the "MARK: - Catalog contract" sweeps below resolve EVERY
/// referenced image id -- all 9 `AtlasFamily` sheets, `tileset_ground`, and
/// all 12 `BuildingSet.definitions` -- and reconcile each family's declared
/// `sheetSize` with the loaded image's real pixel size. Before those existed,
/// any one of the 22 ids could have been misspelled or compiled into an empty
/// `Assets.car` entry with this suite still green.
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

    // MARK: - Catalog contract (product gate #2)

    /// The literal gate-#2 negative test: every sheet id an `AtlasFamily`
    /// names must resolve in the compiled catalog. A misspelled id, or an
    /// imageset that compiled EMPTY via the bare-`filename` failure `AGENT.md`
    /// describes, fails here instead of shipping a placeholder texture.
    func test_everyAtlasFamilySheetName_resolvesInTheCatalog() {
        XCTAssertEqual(AtlasFamilyUnderContract.all.count, 9, "The sweep list must cover every AtlasFamily conformer -- add new families to AtlasFamilyUnderContract.all")

        for family in AtlasFamilyUnderContract.all {
            XCTAssertNoThrow(
                try loader.sheetTexture(named: family.sheetName),
                "sheet id '\(family.sheetName)' does not resolve in the catalog"
            )
        }
    }

    /// `GroundTileset` is not an `AtlasFamily` (its diamonds are not on a
    /// uniform grid), so its id needs its own leg of the sweep -- otherwise
    /// `tileset_ground` would be the one sheet nothing checks.
    func test_groundTilesetSheetName_resolvesInTheCatalog() {
        XCTAssertNoThrow(try loader.sheetTexture(named: GroundTileset.sheetName))
    }

    /// All 12 `building_00`...`building_11` ids resolve. `BuildingSet.loadAll()`
    /// throws `AtlasLoadError.missingAsset` on the first one that does not.
    func test_everyBuildingDefinition_resolvesInTheCatalog() {
        XCTAssertEqual(BuildingSet.definitions.count, 12)
        XCTAssertNoThrow(try BuildingSet.loadAll())
    }

    /// Together with the two tests above, this pins the count of ids under
    /// contract at the 22 committed imagesets, so an id can never be dropped
    /// from the sweep without a failure.
    func test_theSweepCoversAllTwentyTwoCommittedImagesetIds() {
        var ids = Set(AtlasFamilyUnderContract.all.map(\.sheetName))
        ids.insert(GroundTileset.sheetName)
        XCTAssertEqual(ids.count, 10, "10 atlas-sheet imagesets are committed under Assets.xcassets/Sprites/; duplicate or missing sheetName?")

        // `definitions` holds tuples, so map with a closure -- Swift key paths
        // cannot address tuple elements.
        let buildingIds = Set(BuildingSet.definitions.map { $0.assetName })
        XCTAssertEqual(buildingIds.count, 12, "12 building imagesets are committed under Assets.xcassets/Buildings/")
        XCTAssertTrue(ids.isDisjoint(with: buildingIds))
    }

    /// The test that turns the `declared` / `unmeasured` numbers in
    /// `docs/asset_manifest.json` into something CI verifies, rather than a
    /// doc comment asserting they were measured: the declared `sheetSize` must
    /// equal the loaded image's real pixel size.
    ///
    /// This is the guard against the silent failure -- a wrong `sheetSize`
    /// still produces a valid normalized rect over the real sheet, just of the
    /// wrong region, so nothing throws and nothing renders magenta. When it
    /// fails, the message prints the measured size to record in
    /// `docs/asset_manifest.json` (then flip that entry's `provenance` to
    /// `measured` and the family's `sheetSizeProvenance` to `.measured`).
    func test_everyAtlasFamily_declaredSheetSizeMatchesTheLoadedImagePixelSize() throws {
        for family in AtlasFamilyUnderContract.all {
            let probe = try PixelProbe(assetName: family.sheetName)
            XCTAssertEqual(
                probe.pixelSize,
                family.sheetSize,
                "\(family.sheetName): declared sheetSize \(family.sheetSize) (provenance: \(family.provenance.rawValue)) but the committed PNG measures \(probe.pixelSize) -- record \(Int(probe.pixelSize.width))x\(Int(probe.pixelSize.height)) in docs/asset_manifest.json"
            )
        }
    }

    /// `columns * cellWidth == sheetWidth` and `rows * cellHeight ==
    /// sheetHeight` for every family: the same even-division rule
    /// `verify_assets.sh` applies to the manifest, applied to the Swift
    /// constants so the two cannot drift apart.
    func test_everyAtlasFamily_cellGridDividesEvenlyIntoTheDeclaredSheetSize() {
        for family in AtlasFamilyUnderContract.all {
            XCTAssertTrue(
                family.cellGridDividesEvenlyIntoSheet,
                "\(family.sheetName): \(family.columns)x\(family.rows) cells of \(family.cellSize) do not tile \(family.sheetSize) exactly"
            )
        }
    }

    /// And the same even-division rule against the MEASURED sheet, which is
    /// the check that catches a cell grid that happens to be self-consistent
    /// with a wrong declared sheet size.
    func test_everyAtlasFamily_cellGridDividesEvenlyIntoTheMeasuredSheet() throws {
        for family in AtlasFamilyUnderContract.all {
            let probe = try PixelProbe(assetName: family.sheetName)
            XCTAssertEqual(
                probe.width % Int(family.cellSize.width), 0,
                "\(family.sheetName): cell width \(Int(family.cellSize.width)) does not divide the measured width \(probe.width)"
            )
            XCTAssertEqual(
                probe.height % Int(family.cellSize.height), 0,
                "\(family.sheetName): cell height \(Int(family.cellSize.height)) does not divide the measured height \(probe.height)"
            )
        }
    }

    /// Tripwire for the provenance rule in `AssetProvenance` /
    /// `docs/asset_manifest.json`: while `_verification.status` is
    /// `PENDING-MEASUREMENT` nothing has been measured, so no family may claim
    /// `.measured`. Update this test in the SAME change that runs
    /// `bash ./verify_assets.sh` and flips the manifest -- that way the claim
    /// and the record can only move together.
    func test_noAtlasFamilyClaimsMeasuredProvenance_whileTheManifestIsPendingMeasurement() {
        for family in AtlasFamilyUnderContract.all {
            XCTAssertNotEqual(
                family.provenance, .measured,
                "\(family.sheetName) claims .measured, but docs/asset_manifest.json is still PENDING-MEASUREMENT (measured_on: null). Run bash ./verify_assets.sh and record the result first."
            )
        }
        XCTAssertNotEqual(GroundTileset.sheetSizeProvenance, .measured)
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
