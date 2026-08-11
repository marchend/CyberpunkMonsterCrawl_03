import CoreGraphics

/// `sprite_bullets.png` -- 48x16, sliced on a 16x16 cell grid: 3 columns,
/// one row. 0 = slug, 1 = SMG tracer, 2 = rifle round (cyan).
///
/// PROVENANCE: `unmeasured`. `docs/asset_manifest.json` records
/// `sprite_bullets` with `pixel_width`/`pixel_height` null ("no dimensions
/// stated anywhere in the ticket or docs/bootstrap.md - must be measured"),
/// so 48x16 is a working value pinned here to make the contract reviewable
/// -- NOT a measurement. See `AssetProvenance` for why nothing in this PR may
/// claim `.measured` and how to promote it; the guard against a wrong value
/// is the declared-vs-actual sweep in `AtlasTextureLoaderTests`, since a
/// wrong `sheetSize` fails silently (a valid normalized rect over the real
/// sheet, just of the wrong region).
struct BulletAtlas: AtlasFamily {
    static let sheetName = "sprite_bullets"
    static let sheetSize = CGSize(width: 48, height: 16)
    static let sheetSizeProvenance = AssetProvenance.unmeasured
    static let cellSize = CGSize(width: 16, height: 16)
    static let columns = 3
    static let rows = 1

    enum BulletKind: Int, CaseIterable {
        case slug = 0
        case smgTracer = 1
        case rifleRound = 2
    }

    static func cellRect(kind: BulletKind) -> CGRect {
        cellRect(row: 0, col: kind.rawValue)
    }
}
