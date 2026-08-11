import CoreGraphics

/// `sprite_bullets.png` -- measured 48x16, sliced on a 16x16 cell grid: 3
/// columns, one row. 0 = slug, 1 = SMG tracer, 2 = rifle round (cyan).
struct BulletAtlas: AtlasFamily {
    static let sheetName = "sprite_bullets"
    static let sheetSize = CGSize(width: 48, height: 16)
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
