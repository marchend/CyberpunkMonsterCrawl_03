import CoreGraphics

/// `sprite_player_weapons.png` -- measured 288x120, sliced on a 36x40 cell
/// grid: 8 columns, one per compass direction, x 3 rows for handgun / SMG /
/// AR. Weapon overlay cells are drawn on top of the matching `PlayerAtlas`
/// body cell.
///
/// This type is deliberately self-contained: it defines its own
/// `Direction` enum rather than reusing `PlayerAtlas.Direction`, even
/// though both use the same clockwise-from-south ordering convention by
/// design (so a weapon overlay lines up with its body cell) -- no family
/// reads another family's constants.
struct WeaponAtlas: AtlasFamily {
    static let sheetName = "sprite_player_weapons"
    static let sheetSize = CGSize(width: 288, height: 120)
    static let cellSize = CGSize(width: 36, height: 40)
    static let columns = 8
    static let rows = 3

    /// The 8 compass directions mapped to sheet columns. Matches
    /// `PlayerAtlas.Direction`'s clockwise-from-south ordering by
    /// convention (so index N here overlays index N there), but is its
    /// own independent enum.
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

    /// Weapon kind mapped to sheet rows.
    enum WeaponKind: Int, CaseIterable {
        case handgun = 0
        case smg = 1
        case assaultRifle = 2
    }

    /// The pixel sub-rect for a given direction/weapon pair. Directions are
    /// columns here (unlike `PlayerAtlas`, where they are rows).
    static func cellRect(direction: Direction, weapon: WeaponKind) -> CGRect {
        cellRect(row: weapon.rawValue, col: direction.rawValue)
    }
}
