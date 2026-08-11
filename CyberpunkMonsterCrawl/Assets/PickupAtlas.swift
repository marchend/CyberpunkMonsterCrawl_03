import CoreGraphics

/// `sprite_pickups.png` -- measured 48x24, sliced on a 24x24 cell grid: 2
/// columns, one row. 0 = med kit, 1 = garbage can.
struct PickupAtlas: AtlasFamily {
    static let sheetName = "sprite_pickups"
    static let sheetSize = CGSize(width: 48, height: 24)
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
