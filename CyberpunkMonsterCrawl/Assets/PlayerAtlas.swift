import CoreGraphics

/// `sprite_player_walk.png` -- measured 144x320, sliced on a 36x40 cell
/// grid: 4 columns of animation frames (contact / pass-L / contact /
/// pass-R) x 8 rows, one per compass direction.
struct PlayerAtlas: AtlasFamily {
    static let sheetName = "sprite_player_walk"
    static let sheetSize = CGSize(width: 144, height: 320)
    static let cellSize = CGSize(width: 36, height: 40)
    static let columns = 4
    static let rows = 8

    /// Walk-cycle frame within a direction row.
    enum Frame: Int, CaseIterable {
        case contactA = 0
        case passLeft = 1
        case contactB = 2
        case passRight = 3
    }

    /// The 8 compass directions mapped to sheet rows. The story's table
    /// only specifies "8 directions"; this clockwise-from-south ordering
    /// is this codebase's chosen convention -- every consumer must read
    /// directions through this enum rather than a raw row index.
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

    /// The pixel sub-rect for a given direction/frame pair.
    static func cellRect(direction: Direction, frame: Frame) -> CGRect {
        cellRect(row: direction.rawValue, col: frame.rawValue)
    }
}
