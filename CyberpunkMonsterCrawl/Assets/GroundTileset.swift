import CoreGraphics

/// `tileset_ground.png` -- 592x60. Unlike the other atlases, this sheet is
/// NOT a clean N-column grid: it packs six 2:1 isometric ground diamonds on
/// the 96x48 world grid, plus a few pixels of padding/overhang, into a
/// non-multiple-of-96 canvas. Its six sub-rects are therefore hand-derived
/// constants rather than formula-derived from `columns`/`rows`, and it
/// deliberately does NOT conform to `AtlasFamily` (there is no uniform
/// cell grid to slice by row/col).
///
/// PROVENANCE: `unmeasured`, and the derivation below is a RECONCILIATION,
/// not a per-diamond measurement -- read it as a hypothesis that
/// `GroundTilesetTests` proves or refutes against the pixels, not as a
/// measured fact. `docs/asset_manifest.json` records `tileset_ground` with
/// null `pixel_width`/`pixel_height`/`columns`; only `cell_width`/
/// `cell_height` (96x48) are there, and those come from `docs/bootstrap.md`
/// prose, not from the bytes.
///
/// Derivation (single aggregate bounding box, reconciled with the prose's
/// 96px tile width): `inspect_artifact`'s alpha-channel report for this PNG
/// gave a non-transparent bounding box of x:[0, 586], y:[6, 54] within the
/// 592x60 canvas. Six diamonds at 96px sum to 576px; the remaining 10px
/// matches five 2px inter-tile gaps (576 + 5*2 = 586), the box starts flush
/// at x = 0, and a 48px content height matches the 96x48 diamond height,
/// leaving 6px above and below within the 60px canvas. That accounts for the
/// 592px width (586 content + 6px right margin) and the 60px height
/// (6 + 48 + 6), giving six 96x48 cells at x = 0, 98, 196, 294, 392, 490,
/// all at y = 6.
///
/// Three caveats a consumer must know, all of which `GroundTilesetTests`
/// converts from prose into assertions:
///
/// 1. **The bounding-box maxima are read as EXCLUSIVE.** The whole gap model
///    depends on it: exclusive, x:[0, 586] is a 586px-wide region and
///    `576 + 5*2 = 586` lands exactly. Read INCLUSIVELY the same report means
///    587x49, the arithmetic no longer closes, and `.lotVariantC` (x: 490,
///    width: 96, maxX: 586) would clip the last diamond by a pixel. The
///    convention `inspect_artifact` used was not stated in its output, so
///    `test_contentBoundingBox_matchesTheDerivedRegionUnderTheExclusiveReading`
///    pins it: it recomputes the box from the bytes with exclusive maxima (see
///    `PixelProbe.alphaBoundingBox`) and fails with both readings printed if
///    the exclusive one does not reproduce these numbers.
///
/// 2. **The fit is not unique.** 586 = 6*96 + 5*2 is one solution; a 4px left
///    margin with 96-wide tiles and different gaps also reconciles to 592
///    total. The asymmetry this derivation lands on is itself suspicious --
///    6px vertical padding on both sides, but 0px left and 6px right
///    horizontally -- where real packers usually pad symmetrically or not at
///    all. So the model is not inferred from one aggregate width alone:
///    `test_gutterColumns_areFullyTransparent` and
///    `test_everyDiamondRect_containsPaintedPixels` confirm all six rects
///    independently, by asserting the five 2px gutters really are transparent
///    pixel columns and that each 96px slot really carries art (which also
///    catches a diamond overhanging its cell).
///
/// 3. **`Diamond`'s case order is not measured at all.** Which x-offset is
///    `asphalt` vs `kerbSidewalk` vs `lotVariantA` comes from the story's
///    list, not from the pixels -- the "the table said so" inference the repo
///    bans, and it fails invisibly: every tile resolves, renders, and is
///    simply the wrong ground type. See `diamondOrderProvenance`; the first
///    consumer must confirm the ordering visually, because no pixel assertion
///    can distinguish one 96x48 diamond of asphalt from one of concrete.
enum GroundTileset {
    static let sheetName = "tileset_ground"
    static let sheetSize = CGSize(width: 592, height: 60)

    /// See the type-level doc comment: nothing here has been measured against
    /// the bytes, so this may not claim `.measured` until
    /// `bash ./verify_assets.sh` has run and `docs/asset_manifest.json`
    /// records `tileset_ground`'s real dimensions.
    static let sheetSizeProvenance = AssetProvenance.unmeasured

    /// `Diamond`'s case order (which x-offset means which ground type) is
    /// weaker still than the rects themselves: it is copied from the story's
    /// list and cannot be proved by any alpha assertion. Recorded explicitly
    /// so a consumer cannot mistake it for a measured fact.
    static let diamondOrderProvenance = AssetProvenance.unmeasured

    enum Diamond: String, CaseIterable {
        case asphalt
        case junctionStopLineDash
        case kerbSidewalk
        case lotVariantA
        case lotVariantB
        case lotVariantC
    }

    // MARK: - The derived packing model

    /// Width of one diamond, from `docs/bootstrap.md`'s 96x48 world grid.
    static let diamondWidth = 96

    /// Height of one diamond (2:1, so half its width).
    static let diamondHeight = 48

    /// Transparent gutter between adjacent diamonds, derived from the
    /// bounding box (see caveat 2) and proved by
    /// `test_gutterColumns_areFullyTransparent`.
    static let gutterWidth = 2

    /// Vertical padding above (and below) the content band within the 60px
    /// canvas.
    static let contentTopInset = 6

    /// The non-transparent region this derivation predicts, with EXCLUSIVE
    /// maxima (see caveat 1): x 0..<586, y 6..<54.
    static let derivedContentBoundingBox = CGRect(
        x: 0,
        y: CGFloat(GroundTileset.contentTopInset),
        width: CGFloat(6 * GroundTileset.diamondWidth + 5 * GroundTileset.gutterWidth),
        height: CGFloat(GroundTileset.diamondHeight)
    )

    /// The five 2px transparent gutters the model predicts, as pixel column
    /// indices: 96-97, 194-195, 292-293, 390-391, 488-489. If the gutters are
    /// real these columns are fully transparent, which confirms all six rects
    /// independently of the aggregate-width arithmetic.
    static let gutterColumns: [Int] = (1..<6).flatMap { index -> [Int] in
        let start = index * GroundTileset.diamondWidth + (index - 1) * GroundTileset.gutterWidth
        return (0..<GroundTileset.gutterWidth).map { start + $0 }
    }

    /// Derived pixel sub-rects (top-left origin, y-down), one per named
    /// diamond. See the type-level doc comment for how these were derived and
    /// for what is and is not proved about them.
    static let rects: [Diamond: CGRect] = {
        var result: [Diamond: CGRect] = [:]
        for (index, diamond) in GroundTileset.Diamond.allCases.enumerated() {
            result[diamond] = CGRect(
                x: CGFloat(index * (GroundTileset.diamondWidth + GroundTileset.gutterWidth)),
                y: CGFloat(GroundTileset.contentTopInset),
                width: CGFloat(GroundTileset.diamondWidth),
                height: CGFloat(GroundTileset.diamondHeight)
            )
        }
        return result
    }()

    /// The derived pixel sub-rect for a named diamond.
    static func rect(for diamond: Diamond) -> CGRect {
        // Force-unwrap is safe: `rects` is built by iterating
        // `Diamond.allCases`, so it covers every case by construction, and
        // `GroundTilesetTests.test_rects_coverEveryDiamondCase` asserts it.
        guard let rect = rects[diamond] else {
            preconditionFailure("GroundTileset.rects is missing an entry for \(diamond)")
        }
        return rect
    }
}
