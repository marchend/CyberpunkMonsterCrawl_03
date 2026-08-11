import CoreGraphics

/// `tileset_ground.png` -- 592x60. Unlike the other atlases, this sheet is
/// NOT a clean N-column grid: it packs six 2:1 isometric ground diamonds on
/// the 96x48 world grid, plus a few pixels of padding/overhang, into a
/// non-multiple-of-96 canvas. Its six sub-rects are therefore hand-measured
/// constants rather than formula-derived from `columns`/`rows`, and it
/// deliberately does NOT conform to `AtlasFamily` (there is no uniform
/// cell grid to slice by row/col).
///
/// Measurement method: `inspect_artifact`'s alpha-channel report for this
/// PNG gave a non-transparent bounding box of x:[0, 586], y:[6, 54] within
/// the 592x60 canvas (a 586x48 non-transparent region). Six diamonds at the
/// story's documented 96px tile width sum to 576px; the remaining 10px of
/// the 586px bounding-box width matches exactly five 2px inter-tile gaps
/// (576 + 5*2 = 586), and the bounding box starts flush at x = 0. The
/// content height of 48px (54 - 6) matches the 96x48 diamond height
/// exactly, symmetrically padded by 6px above and below within the 60px
/// canvas. That fully accounts for both the 592px width (576 + 10 gaps +
/// 6px right margin = 592) and the 60px height (48 + 6 + 6), so the six
/// diamonds are laid out left-to-right as 96-wide, 48-tall cells starting
/// at x = 0, 98, 196, 294, 392, 490, all at y = 6 -- derived from the
/// measured bounding box, not assumed from a formula.
enum GroundTileset {
    static let sheetName = "tileset_ground"
    static let sheetSize = CGSize(width: 592, height: 60)

    enum Diamond: String, CaseIterable {
        case asphalt
        case junctionStopLineDash
        case kerbSidewalk
        case lotVariantA
        case lotVariantB
        case lotVariantC
    }

    /// Hand-measured pixel sub-rects (top-left origin, y-down), one per
    /// named diamond. See the type-level doc comment for how these were
    /// derived.
    static let rects: [Diamond: CGRect] = [
        .asphalt:              CGRect(x: 0,   y: 6, width: 96, height: 48),
        .junctionStopLineDash: CGRect(x: 98,  y: 6, width: 96, height: 48),
        .kerbSidewalk:         CGRect(x: 196, y: 6, width: 96, height: 48),
        .lotVariantA:          CGRect(x: 294, y: 6, width: 96, height: 48),
        .lotVariantB:          CGRect(x: 392, y: 6, width: 96, height: 48),
        .lotVariantC:          CGRect(x: 490, y: 6, width: 96, height: 48),
    ]

    /// The measured pixel sub-rect for a named diamond.
    static func rect(for diamond: Diamond) -> CGRect {
        // Force-unwrap is safe: `rects` is a static literal covering every
        // case of `Diamond`, enforced by the exhaustiveness test in
        // `CellRectMathTests`-adjacent coverage; there is no way to
        // construct a `Diamond` case this dictionary doesn't have.
        guard let rect = rects[diamond] else {
            preconditionFailure("GroundTileset.rects is missing an entry for \(diamond)")
        }
        return rect
    }
}
