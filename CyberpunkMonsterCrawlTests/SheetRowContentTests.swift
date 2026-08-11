import XCTest
@testable import CyberpunkMonsterCrawl

/// Settles, against the bytes, what the 8-direction sheets actually contain.
///
/// `docs/asset_manifest.json` claims for `sprite_player_walk` that "rows 0-4
/// authored, rows 5-7 are MIRRORS of rows 3/2/1 (per prose -- must be confirmed
/// against pixels, not assumed)", and says nothing either way about the two
/// raccoon sheets' 8 rows. Constants alone cannot tell a pre-mirrored row from
/// a BLANK one: `cellRect` returns a perfectly in-bounds rect over empty
/// pixels, `isInBounds` passes, and the actor simply renders invisible for
/// those facings. Since this PR's job is locking the contract before any
/// consumer exists, these tests are where that question gets a permanent
/// answer.
///
/// Silhouettes are compared as alpha masks rather than full RGB so a colour
/// touch-up on an otherwise mirrored row does not read as a broken mirror,
/// while a blank or differently-posed row still fails.
final class SheetRowContentTests: XCTestCase {
    // MARK: - No direction row may be blank

    func test_playerWalk_everyDirectionRowHasPaintedPixels() throws {
        let probe = try PixelProbe(assetName: PlayerAtlas.sheetName)
        for direction in PlayerAtlas.Direction.allCases {
            for frame in PlayerAtlas.Frame.allCases {
                let rect = PlayerAtlas.cellRect(direction: direction, frame: frame)
                XCTAssertTrue(
                    probe.hasNonTransparentPixel(in: rect),
                    "sprite_player_walk row \(direction.rawValue) (\(direction)) frame \(frame.rawValue) is entirely transparent at \(rect) -- either the sheet has fewer authored rows than the 8 this atlas declares (mirroring was meant to happen at runtime via xScale = -1), or the cell grid is wrong"
                )
            }
        }
    }

    func test_raccoonWalk_everyDirectionRowHasPaintedPixels() throws {
        let probe = try PixelProbe(assetName: RaccoonWalkAtlas.sheetName)
        for direction in RaccoonWalkAtlas.Direction.allCases {
            for frame in RaccoonWalkAtlas.Frame.allCases {
                let rect = RaccoonWalkAtlas.cellRect(direction: direction, frame: frame)
                XCTAssertTrue(
                    probe.hasNonTransparentPixel(in: rect),
                    "sprite_raccoon_walk row \(direction.rawValue) (\(direction)) frame \(frame.rawValue) is entirely transparent at \(rect)"
                )
            }
        }
    }

    func test_raccoonAttack_everyDirectionRowHasPaintedPixels() throws {
        let probe = try PixelProbe(assetName: RaccoonAttackAtlas.sheetName)
        for direction in RaccoonAttackAtlas.Direction.allCases {
            for frame in RaccoonAttackAtlas.Frame.allCases {
                let rect = RaccoonAttackAtlas.cellRect(direction: direction, frame: frame)
                XCTAssertTrue(
                    probe.hasNonTransparentPixel(in: rect),
                    "sprite_raccoon_attack row \(direction.rawValue) (\(direction)) frame \(frame.rawValue) is entirely transparent at \(rect)"
                )
            }
        }
    }

    // MARK: - The mirrored-rows claim

    /// Pins the manifest's mirror claim: row 5 is the horizontal mirror of row
    /// 3, row 6 of row 2, row 7 of row 1. If this fails, the prose is wrong and
    /// `PlayerAtlas.Direction`'s pairing (and any consumer that relies on it)
    /// has to be re-derived from the art -- which is exactly the answer this
    /// test exists to make permanent.
    func test_playerWalk_rows5to7_areHorizontalMirrorsOfRows3to1() throws {
        let probe = try PixelProbe(assetName: PlayerAtlas.sheetName)
        XCTAssertEqual(PlayerAtlas.claimedMirroredRowPairs.count, 3)

        for pair in PlayerAtlas.claimedMirroredRowPairs {
            for frame in PlayerAtlas.Frame.allCases {
                let authoredRect = PlayerAtlas.cellRect(direction: pair.authored, frame: frame)
                let mirroredRect = PlayerAtlas.cellRect(direction: pair.mirrored, frame: frame)
                XCTAssertEqual(
                    probe.alphaMask(in: mirroredRect),
                    probe.horizontallyMirroredAlphaMask(in: authoredRect),
                    "sprite_player_walk row \(pair.mirrored.rawValue) (\(pair.mirrored)) frame \(frame.rawValue) is not the horizontal mirror of row \(pair.authored.rawValue) (\(pair.authored)) -- docs/asset_manifest.json's mirrored-rows note does not hold, so PlayerAtlas.Direction's row pairing must be re-derived from the pixels"
                )
            }
        }
    }

    /// The mirror pairing must stay consistent with `Direction`'s ordering: a
    /// well-meaning reorder (e.g. to counter-clockwise) would break the pairing
    /// silently, so assert the arithmetic relationship the sheet's layout
    /// implies -- mirrored row == 8 - authored row.
    func test_playerWalk_mirrorPairing_matchesTheDirectionEnumOrdering() {
        for pair in PlayerAtlas.claimedMirroredRowPairs {
            XCTAssertEqual(
                pair.mirrored.rawValue,
                PlayerAtlas.rows - pair.authored.rawValue,
                "\(pair.mirrored) should sit at row \(PlayerAtlas.rows - pair.authored.rawValue) to mirror \(pair.authored) -- Direction's ordering is constrained by the art, not free"
            )
        }
    }

    // MARK: - Recording aid

    /// Not an assertion -- prints per-row painted-pixel counts so a macOS run
    /// can record what each 8-row sheet really contains in
    /// `docs/asset_manifest.json` (whose mirror note is still unconfirmed
    /// prose).
    func test_printPerRowAlphaCoverageForManifestRecording() throws {
        for name in [PlayerAtlas.sheetName, RaccoonWalkAtlas.sheetName, RaccoonAttackAtlas.sheetName] {
            let probe = try PixelProbe(assetName: name)
            let cellHeight = name == PlayerAtlas.sheetName ? 40 : 28
            var lines: [String] = ["\(name) (\(probe.width)x\(probe.height)) painted pixels per row:"]
            var row = 0
            while (row + 1) * cellHeight <= probe.height {
                let rect = CGRect(x: 0, y: CGFloat(row * cellHeight), width: CGFloat(probe.width), height: CGFloat(cellHeight))
                lines.append("  row \(row): \(probe.nonTransparentPixelCount(in: rect))")
                row += 1
            }
            print(lines.joined(separator: "\n"))
        }
    }
}
