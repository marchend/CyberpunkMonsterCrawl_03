import CoreGraphics

/// `sprite_pulse.png` -- 256x32, sliced on a 32x32 cell grid: 8 animation
/// frames of the pulse shockwave, one row.
///
/// PROVENANCE: `unmeasured` -- `docs/asset_manifest.json` records
/// `sprite_pulse` with null dimensions and notes that "the authored radius in
/// pixels must be measured before any scaling math" (the pulse grows +25% at
/// levels 3 and 6). 256x32 is a pinned working value, not a measurement; see
/// `AssetProvenance` and the declared-vs-actual sweep in
/// `AtlasTextureLoaderTests`.
struct PulseAtlas: AtlasFamily {
    static let sheetName = "sprite_pulse"
    static let sheetSize = CGSize(width: 256, height: 32)
    static let sheetSizeProvenance = AssetProvenance.unmeasured
    static let cellSize = CGSize(width: 32, height: 32)
    static let columns = 8
    static let rows = 1

    static func cellRect(frame: Int) -> CGRect {
        cellRect(row: 0, col: frame)
    }
}
