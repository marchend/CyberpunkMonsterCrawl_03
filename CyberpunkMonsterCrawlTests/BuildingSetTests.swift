import Foundation
import XCTest
@testable import CyberpunkMonsterCrawl

/// Covers `BuildingSet.load` / `loadAll` / `cgImageHasAlphaChannel`, which had
/// no tests at all when this PR was first pushed even though the doc comment on
/// `cgImageHasAlphaChannel` claimed the stronger non-opaque check was
/// "asserted by the PR 4 test suite".
///
/// Three things are checked against the real bytes rather than against
/// `CGImage` metadata:
/// 1. all 12 ids resolve (`building_00`...`building_11`) -- gate #2 for the
///    `Buildings/` group, mirroring the sheet sweep in
///    `AtlasTextureLoaderTests`;
/// 2. every `measuredSize` is non-zero, so an imageset that compiled EMPTY
///    (the bare-`filename` traversal failure in `AGENT.md`) cannot pass as a
///    1x1 placeholder;
/// 3. real corner alpha is sampled, because `alphaInfo != .none` says an alpha
///    channel exists, not that any pixel is translucent -- without this,
///    `hasAlphaChannel: true` on all 12 buildings is indistinguishable from
///    transparency having been flattened during import, i.e. the "buildings
///    render with opaque boxes around them" bug.
final class BuildingSetTests: XCTestCase {
    func test_definitions_coverTheTwelveCommittedBuildingIds() {
        XCTAssertEqual(BuildingSet.definitions.count, 12)
        XCTAssertEqual(
            BuildingSet.definitions.map(\.assetName),
            (0...11).map { String(format: "building_%02d", $0) },
            "definitions must name building_00...building_11 in table order"
        )
    }

    func test_loadAll_resolvesEveryBuildingIdInTheCatalog() throws {
        let sprites = try BuildingSet.loadAll()
        XCTAssertEqual(sprites.count, 12)
        XCTAssertEqual(
            sprites.map(\.assetName),
            BuildingSet.definitions.map(\.assetName),
            "loadAll must preserve table order -- consumers index footprint/heightClass by position"
        )
    }

    func test_loadAll_preservesTheFootprintAndHeightClassTable() throws {
        let sprites = try BuildingSet.loadAll()
        for (sprite, definition) in zip(sprites, BuildingSet.definitions) {
            XCTAssertEqual(sprite.footprint, definition.footprint, "\(sprite.assetName) footprint")
            XCTAssertEqual(sprite.heightClass, definition.heightClass, "\(sprite.assetName) height class")
        }
    }

    func test_load_missingAsset_throwsMissingAssetWithTheRequestedName() {
        XCTAssertThrowsError(
            try BuildingSet.load(assetName: "building_99_does_not_exist", footprint: .oneByOne, heightClass: .low)
        ) { error in
            guard case AtlasLoadError.missingAsset(let name) = error else {
                XCTFail("Expected AtlasLoadError.missingAsset, got \(error)")
                return
            }
            XCTAssertEqual(name, "building_99_does_not_exist")
        }
    }

    /// A 1x1 (or 0-sized) result is what an imageset that compiled EMPTY looks
    /// like at runtime, so "non-zero" alone is too weak -- require something
    /// plausibly building-sized on the 96x48 diamond grid.
    func test_everyBuilding_hasAPlausibleNonPlaceholderMeasuredSize() throws {
        for sprite in try BuildingSet.loadAll() {
            XCTAssertGreaterThan(sprite.measuredSize.width, 1, "\(sprite.assetName) measured \(sprite.measuredSize) -- a 1x1 image is SpriteKit's empty-imageset placeholder, not art")
            XCTAssertGreaterThan(sprite.measuredSize.height, 1, "\(sprite.assetName) measured \(sprite.measuredSize)")
            XCTAssertEqual(
                sprite.measuredSize, try PixelProbe(assetName: sprite.assetName).pixelSize,
                "\(sprite.assetName): BuildingSprite.measuredSize disagrees with the rasterized pixel size"
            )
        }
    }

    func test_everyBuilding_reportsAnAlphaChannel() throws {
        for sprite in try BuildingSet.loadAll() {
            XCTAssertTrue(
                sprite.hasAlphaChannel,
                "\(sprite.assetName) has no alpha channel at all -- it cannot composite over the ground plane"
            )
        }
    }

    /// The real "transparency was preserved" check the doc comment on
    /// `cgImageHasAlphaChannel` used to defer: sample the four corner pixels'
    /// alpha out of the rasterized bytes. A pre-rendered building sprite is a
    /// silhouette on a transparent canvas, so its corners must NOT be opaque.
    /// This fails on a flattened import that `alphaInfo` would happily call
    /// `true`.
    func test_everyBuilding_hasNonOpaqueCornerPixels() throws {
        for definition in BuildingSet.definitions {
            let probe = try PixelProbe(assetName: definition.assetName)
            let corners = [
                CGRect(x: 0, y: 0, width: 1, height: 1),
                CGRect(x: CGFloat(probe.width - 1), y: 0, width: 1, height: 1),
                CGRect(x: 0, y: CGFloat(probe.height - 1), width: 1, height: 1),
                CGRect(x: CGFloat(probe.width - 1), y: CGFloat(probe.height - 1), width: 1, height: 1),
            ]
            let opaqueCorners = corners.filter { !probe.hasNonOpaquePixel(in: $0) }
            XCTAssertTrue(
                opaqueCorners.isEmpty,
                "\(definition.assetName): \(opaqueCorners.count) of 4 corner pixels are fully opaque -- transparency looks flattened, which renders as an opaque box around the sprite"
            )
        }
    }

    /// Belt-and-braces on the same point: the sprite must contain BOTH
    /// transparent and non-transparent pixels. All-transparent means an empty
    /// imageset; no transparency at all means a flattened one.
    func test_everyBuilding_hasBothTransparentAndPaintedPixels() throws {
        for definition in BuildingSet.definitions {
            let probe = try PixelProbe(assetName: definition.assetName)
            let whole = CGRect(x: 0, y: 0, width: CGFloat(probe.width), height: CGFloat(probe.height))
            XCTAssertTrue(probe.hasNonTransparentPixel(in: whole), "\(definition.assetName) is entirely transparent")
            XCTAssertTrue(probe.hasNonOpaquePixel(in: whole), "\(definition.assetName) has no transparent pixel anywhere")
        }
    }

    /// Not an assertion -- prints the measured dimensions in the shape
    /// `docs/asset_manifest.json` wants, since all 12 building entries are
    /// `provenance: "unmeasured"` with null dims today. Run this on a macOS
    /// checkout alongside `bash ./verify_assets.sh` and paste the result in.
    func test_printMeasuredBuildingDimensionsForManifestRecording() throws {
        var lines: [String] = []
        for sprite in try BuildingSet.loadAll() {
            lines.append("\(sprite.assetName): pixel_width \(Int(sprite.measuredSize.width)), pixel_height \(Int(sprite.measuredSize.height)), alpha channel \(sprite.hasAlphaChannel)")
        }
        print("MEASURED BUILDING DIMENSIONS (record in docs/asset_manifest.json):\n" + lines.joined(separator: "\n"))
        XCTAssertEqual(lines.count, 12)
    }
}
