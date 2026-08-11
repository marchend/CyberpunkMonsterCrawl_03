import CoreGraphics

/// `sprite_signs.png` -- 192x144, sliced on a 48x48 cell grid: 4 columns x 3
/// rows = 12 rooftop neon-sign cells.
///
/// PROVENANCE: `unmeasured` -- `docs/asset_manifest.json` records
/// `sprite_signs` with null dimensions ("no dimensions stated anywhere - must
/// be measured"), so 192x144 and the 4x3 grid are pinned working values, not
/// measurements; see `AssetProvenance` and the declared-vs-actual sweep in
/// `AtlasTextureLoaderTests`.
struct SignAtlas: AtlasFamily {
    static let sheetName = "sprite_signs"
    static let sheetSize = CGSize(width: 192, height: 144)
    static let sheetSizeProvenance = AssetProvenance.unmeasured
    static let cellSize = CGSize(width: 48, height: 48)
    static let columns = 4
    static let rows = 3

    /// Flat 0..<12 index across the 4x3 grid, row-major (matches the
    /// story's "12 cells" framing rather than exposing row/col directly).
    static func cellRect(index: Int) -> CGRect {
        precondition((0..<(columns * rows)).contains(index), "SignAtlas index out of range: \(index)")
        return cellRect(row: index / columns, col: index % columns)
    }
}
