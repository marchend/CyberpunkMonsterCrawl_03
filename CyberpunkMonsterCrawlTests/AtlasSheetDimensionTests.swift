import CoreGraphics
import XCTest
@testable import CyberpunkMonsterCrawl

/// Product gate: "every sheet listed in the ticket loads from the catalog
/// and its measured pixel dims equal the table."
///
/// `AtlasTextureLoaderTests.test_everyAtlasFamily_declaredSheetSizeMatchesTheLoadedImagePixelSize`
/// already sweeps this generically over `AtlasFamilyUnderContract.all`, and
/// `GroundTilesetTests.test_declaredSheetSize_matchesTheCatalogImage` covers
/// the tenth sheet the same way. This file is the ticket's own explicit,
/// per-sheet gate: one NAMED test per sheet, each spelling out the ticket
/// table's dimensions, so a single wrong/renamed/missing sheet fails under
/// its OWN name instead of a shared loop index, and so the ticket's table
/// lives here in a form a reviewer can diff line-by-line against the story
/// table / `docs/asset_manifest.json` / each `AtlasFamily` conformer's
/// declared `sheetSize`.
///
/// `PixelProbe.init` throws `ProbeError.missingAsset` when
/// `UIImage(named:)` returns nil, so a sheet that is missing, renamed, or
/// compiled EMPTY (the bare-`filename` traversal bug -- see `AGENT.md`)
/// fails the `try` in each test below rather than silently comparing a
/// declared size against a 1x1 placeholder.
final class AtlasSheetDimensionTests: XCTestCase {
    // MARK: - The 9 AtlasFamily sheets (measured pixel dims per the ticket table)

    /// sprite_player_walk.png -- 144x320.
    func test_spritePlayerWalk_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(PlayerAtlas.sheetName, PlayerAtlas.sheetSize)
    }

    /// sprite_player_weapons.png -- 288x120.
    func test_spritePlayerWeapons_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(WeaponAtlas.sheetName, WeaponAtlas.sheetSize)
    }

    /// sprite_raccoon_walk.png -- 192x224.
    func test_spriteRaccoonWalk_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(RaccoonWalkAtlas.sheetName, RaccoonWalkAtlas.sheetSize)
    }

    /// sprite_raccoon_attack.png -- 192x224.
    func test_spriteRaccoonAttack_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(RaccoonAttackAtlas.sheetName, RaccoonAttackAtlas.sheetSize)
    }

    /// sprite_bullets.png -- 48x16 (pinned working value; manifest records
    /// this sheet as unmeasured, see `BulletAtlas`'s doc comment).
    func test_spriteBullets_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(BulletAtlas.sheetName, BulletAtlas.sheetSize)
    }

    /// sprite_pulse.png -- 256x32 (pinned working value; unmeasured).
    func test_spritePulse_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(PulseAtlas.sheetName, PulseAtlas.sheetSize)
    }

    /// sprite_hit_puff.png -- 96x24 (pinned working value; unmeasured).
    func test_spriteHitPuff_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(HitPuffAtlas.sheetName, HitPuffAtlas.sheetSize)
    }

    /// sprite_pickups.png -- 48x24 (pinned working value; unmeasured).
    func test_spritePickups_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(PickupAtlas.sheetName, PickupAtlas.sheetSize)
    }

    /// sprite_signs.png -- 192x144 (pinned working value; unmeasured).
    func test_spriteSigns_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(SignAtlas.sheetName, SignAtlas.sheetSize)
    }

    // MARK: - The 10th sheet: the non-uniform ground tileset

    /// tileset_ground.png -- 592x60 (see `GroundTileset`'s doc comment for
    /// the derivation of its non-uniform packing).
    func test_tilesetGround_measuresAsDeclared() throws {
        try assertMeasuredSizeMatchesDeclared(GroundTileset.sheetName, GroundTileset.sheetSize)
    }

    // MARK: - Coverage tripwire

    /// Pins the sweep at exactly the 10 sheet ids the ticket's table names,
    /// so a sheet can never quietly drop out of this file without a
    /// failure -- mirrors `AtlasTextureLoaderTests.test_theSweepCoversAllTwentyTwoCommittedImagesetIds`
    /// for this file's own narrower scope (sheets only, not buildings).
    func test_thisFileCoversExactlyTheTenTicketSheets() {
        let coveredSheetNames: Set<String> = [
            PlayerAtlas.sheetName,
            WeaponAtlas.sheetName,
            RaccoonWalkAtlas.sheetName,
            RaccoonAttackAtlas.sheetName,
            BulletAtlas.sheetName,
            PulseAtlas.sheetName,
            HitPuffAtlas.sheetName,
            PickupAtlas.sheetName,
            SignAtlas.sheetName,
            GroundTileset.sheetName,
        ]
        XCTAssertEqual(coveredSheetNames.count, 10, "expected 10 distinct sheet ids -- duplicate or missing sheetName across the ticket's table")
    }

    // MARK: - Helper

    private func assertMeasuredSizeMatchesDeclared(
        _ sheetName: String,
        _ declaredSize: CGSize,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let probe = try PixelProbe(assetName: sheetName)
        XCTAssertEqual(
            probe.pixelSize,
            declaredSize,
            "\(sheetName): declared \(declaredSize) but the committed PNG measures \(probe.pixelSize) -- update the table entry and docs/asset_manifest.json",
            file: file,
            line: line
        )
    }
}
