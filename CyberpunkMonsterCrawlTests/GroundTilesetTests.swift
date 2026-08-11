import XCTest
@testable import CyberpunkMonsterCrawl

/// Converts `GroundTileset`'s derivation from prose into assertions.
///
/// The type's six sub-rects are reconciled from a SINGLE aggregate alpha
/// bounding box plus `docs/bootstrap.md`'s 96px tile width -- not measured per
/// diamond -- and that reconciliation has two soft spots the doc comment now
/// names: the bounding box's maxima could be read inclusively (587x49 instead
/// of 586x48, under which the arithmetic stops closing and `.lotVariantC`
/// clips by a pixel), and the fit is not unique. Both are decidable from the
/// pixels, which is what these tests do: the five 2px gutters must be genuinely
/// transparent columns, and each 96px slot must genuinely carry art. That
/// confirms all six rects independently instead of inferring five gaps from one
/// aggregate width.
final class GroundTilesetTests: XCTestCase {
    // MARK: - Pure math over the declared constants

    func test_rects_coverEveryDiamondCase() {
        XCTAssertEqual(GroundTileset.rects.count, GroundTileset.Diamond.allCases.count)
        for diamond in GroundTileset.Diamond.allCases {
            XCTAssertNotNil(GroundTileset.rects[diamond], "no rect recorded for \(diamond)")
        }
    }

    func test_everyRect_isOneDiamondSizedCellInsideTheDeclaredSheet() {
        for diamond in GroundTileset.Diamond.allCases {
            let rect = GroundTileset.rect(for: diamond)
            XCTAssertEqual(rect.width, CGFloat(GroundTileset.diamondWidth), "\(diamond) width")
            XCTAssertEqual(rect.height, CGFloat(GroundTileset.diamondHeight), "\(diamond) height")
            XCTAssertGreaterThanOrEqual(rect.minX, 0, "\(diamond) starts left of the sheet")
            XCTAssertGreaterThanOrEqual(rect.minY, 0, "\(diamond) starts above the sheet")
            XCTAssertLessThanOrEqual(
                rect.maxX, GroundTileset.sheetSize.width,
                "\(diamond) at \(rect) overruns the 592px sheet width -- this is exactly what the INCLUSIVE reading of the bounding box would cause"
            )
            XCTAssertLessThanOrEqual(rect.maxY, GroundTileset.sheetSize.height, "\(diamond) at \(rect) overruns the sheet height")
        }
    }

    /// The six rects must be evenly spaced by exactly one gutter, with no
    /// overlap -- the packing model stated in the doc comment.
    func test_rects_areSpacedByExactlyOneGutter() {
        let ordered = GroundTileset.Diamond.allCases.map { GroundTileset.rect(for: $0) }
        for (previous, next) in zip(ordered, ordered.dropFirst()) {
            XCTAssertEqual(
                next.minX - previous.maxX, CGFloat(GroundTileset.gutterWidth),
                "diamonds at \(previous) and \(next) are not separated by exactly \(GroundTileset.gutterWidth)px"
            )
            XCTAssertEqual(previous.minY, next.minY, "all six diamonds sit on the same content band")
        }
    }

    /// The derived content box must reproduce the numbers the doc comment
    /// quotes (586x48 at y = 6) under the exclusive reading.
    func test_derivedContentBoundingBox_reconcilesWithTheSixRects() {
        XCTAssertEqual(GroundTileset.derivedContentBoundingBox, CGRect(x: 0, y: 6, width: 586, height: 48))

        let first = GroundTileset.rect(for: GroundTileset.Diamond.allCases.first!)
        let last = GroundTileset.rect(for: GroundTileset.Diamond.allCases.last!)
        XCTAssertEqual(first.minX, GroundTileset.derivedContentBoundingBox.minX)
        XCTAssertEqual(last.maxX, GroundTileset.derivedContentBoundingBox.maxX)
    }

    func test_gutterColumns_areTheFivePredictedTwoPixelGaps() {
        XCTAssertEqual(GroundTileset.gutterColumns, [96, 97, 194, 195, 292, 293, 390, 391, 488, 489])
    }

    // MARK: - Against the real pixels

    func test_declaredSheetSize_matchesTheCatalogImage() throws {
        let probe = try PixelProbe(assetName: GroundTileset.sheetName)
        XCTAssertEqual(
            probe.pixelSize, GroundTileset.sheetSize,
            "tileset_ground declares \(GroundTileset.sheetSize) but measures \(probe.pixelSize) -- record \(probe.width)x\(probe.height) in docs/asset_manifest.json, whose pixel_width/pixel_height for this sheet are null"
        )
    }

    /// The direct proof the aggregate-width arithmetic cannot give: if the 2px
    /// gutters are real, these columns are fully transparent over the whole
    /// sheet height. Failing here means the packing model (and therefore all
    /// six rects) is wrong, even though every rect would still slice and render.
    func test_gutterColumns_areFullyTransparent() throws {
        let probe = try PixelProbe(assetName: GroundTileset.sheetName)
        for column in GroundTileset.gutterColumns {
            XCTAssertTrue(
                probe.columnIsFullyTransparent(column),
                "column x=\(column) should be an inter-tile gutter but carries \(probe.nonTransparentPixelCount(in: CGRect(x: CGFloat(column), y: 0, width: 1, height: CGFloat(probe.height)))) painted pixels -- the six diamonds are not laid out as derived (a diamond may overhang its cell, or the gap is not 2px)"
            )
        }
    }

    /// Each 96px slot must actually carry art, so a rect cannot point at empty
    /// canvas.
    func test_everyDiamondRect_containsPaintedPixels() throws {
        let probe = try PixelProbe(assetName: GroundTileset.sheetName)
        for diamond in GroundTileset.Diamond.allCases {
            let rect = GroundTileset.rect(for: diamond)
            XCTAssertTrue(
                probe.hasNonTransparentPixel(in: rect),
                "\(diamond) at \(rect) is entirely transparent"
            )
        }
    }

    /// Pins the inclusive/exclusive convention the whole gap model rests on:
    /// recomputed from the bytes with EXCLUSIVE maxima, the content box must be
    /// x 0..<586, y 6..<54. The failure message prints both readings so the
    /// disagreement is unambiguous.
    func test_contentBoundingBox_matchesTheDerivedRegionUnderTheExclusiveReading() throws {
        let probe = try PixelProbe(assetName: GroundTileset.sheetName)
        let measured = try XCTUnwrap(probe.alphaBoundingBox(), "tileset_ground is entirely transparent")
        XCTAssertEqual(
            measured, GroundTileset.derivedContentBoundingBox,
            """
            tileset_ground content box disagrees with the derivation. \
            Measured (exclusive maxima): \(measured). \
            Same box read inclusively: x:[\(Int(measured.minX)), \(Int(measured.maxX) - 1)], y:[\(Int(measured.minY)), \(Int(measured.maxY) - 1)]. \
            Derived: \(GroundTileset.derivedContentBoundingBox). \
            Record the measured numbers in docs/asset_manifest.json and re-derive the six rects from them.
            """
        )
    }

    /// Not an assertion -- prints the per-column painted-pixel profile so the
    /// real gutter positions can be read off directly and recorded in
    /// `docs/asset_manifest.json` (`tileset_ground` has null width/height/
    /// columns today).
    func test_printColumnAlphaProfileForManifestRecording() throws {
        let probe = try PixelProbe(assetName: GroundTileset.sheetName)
        let profile = probe.columnAlphaProfile()
        let emptyColumns = profile.enumerated().filter { $0.element == 0 }.map { $0.offset }
        print("""
        tileset_ground measures \(probe.width)x\(probe.height)
        fully transparent columns: \(emptyColumns)
        derived gutter columns:    \(GroundTileset.gutterColumns)
        column alpha profile:      \(profile)
        """)
        XCTAssertEqual(profile.count, probe.width)
    }
}
