import CoreGraphics

/// `sprite_pickups.png` -- 48x24, sliced on a 24x24 cell grid: 2 columns, one
/// row. 0 = med kit, 1 = garbage can.
///
/// PROVENANCE: `unmeasured` -- `docs/asset_manifest.json` records
/// `sprite_pickups` with null dimensions and warns that the spec's 32x32pt
/// figure "is a render size, not a measured cell size". 48x24 is a pinned
/// working value, not a measurement; see `AssetProvenance` and the
/// declared-vs-actual sweep in `AtlasTextureLoaderTests`.
struct PickupAtlas: AtlasFamily {
    static let sheetName = "sprite_pickups"
    static let sheetSize = CGSize(width: 48, height: 24)
    static let sheetSizeProvenance = AssetProvenance.unmeasured
    static let cellSize = CGSize(width: 24, height: 24)
    static let columns = 2
    static let rows = 1

    enum Kind: Int, CaseIterable {
        case medKit = 0
        case garbageCan = 1
    }

    static func cellRect(kind: Kind) -> CGRect {
        cellRect(row: 0, col: kind.rawValue)
    }
}
