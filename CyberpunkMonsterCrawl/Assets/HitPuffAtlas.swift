import CoreGraphics

/// `sprite_hit_puff.png` -- 96x24, sliced on a 24x24 cell grid: 4 animation
/// frames of the impact puff, one row. Frame 0 doubles as the muzzle flash.
///
/// PROVENANCE: `unmeasured` -- `docs/asset_manifest.json` records
/// `sprite_hit_puff` with null dimensions and notes that "frame count must
/// come from the measured sheet, not from a guessed cell size". 96x24 (and
/// therefore the 4-frame count) is a pinned working value, not a measurement;
/// see `AssetProvenance` and the declared-vs-actual sweep in
/// `AtlasTextureLoaderTests`.
struct HitPuffAtlas: AtlasFamily {
    static let sheetName = "sprite_hit_puff"
    static let sheetSize = CGSize(width: 96, height: 24)
    static let sheetSizeProvenance = AssetProvenance.unmeasured
    static let cellSize = CGSize(width: 24, height: 24)
    static let columns = 4
    static let rows = 1

    /// Frame 0 (`.impactAndMuzzleFlash`) is shared between the impact-puff
    /// animation and the muzzle-flash effect -- there is no separate
    /// muzzle-flash cell in the sheet.
    enum Frame: Int, CaseIterable {
        case impactAndMuzzleFlash = 0
        case frame1 = 1
        case frame2 = 2
        case frame3 = 3
    }

    static func cellRect(frame: Frame) -> CGRect {
        cellRect(row: 0, col: frame.rawValue)
    }
}
