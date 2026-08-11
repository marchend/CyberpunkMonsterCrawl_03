import CoreGraphics

/// `sprite_raccoon_attack.png` -- measured 192x224, same 48x28 cell grid as
/// `RaccoonWalkAtlas`: 4 columns of animation frames x 8 rows, one per
/// compass direction.
///
/// This type is deliberately self-contained: it defines its own
/// `Direction` enum rather than reusing `RaccoonWalkAtlas.Direction` or
/// `PlayerAtlas.Direction`, even though all three use the same
/// clockwise-from-south ordering convention by design -- no family reads
/// another family's constants.
struct RaccoonAttackAtlas: AtlasFamily {
    static let sheetName = "sprite_raccoon_attack"
    static let sheetSize = CGSize(width: 192, height: 224)
    static let cellSize = CGSize(width: 48, height: 28)
    static let columns = 4
    static let rows = 8

    enum Direction: Int, CaseIterable {
        case south = 0
        case southwest = 1
        case west = 2
        case northwest = 3
        case north = 4
        case northeast = 5
        case east = 6
        case southeast = 7
    }

    enum Frame: Int, CaseIterable {
        case frame0 = 0
        case frame1 = 1
        case frame2 = 2
        case frame3 = 3
    }

    static func cellRect(direction: Direction, frame: Frame) -> CGRect {
        cellRect(row: direction.rawValue, col: frame.rawValue)
    }
}
