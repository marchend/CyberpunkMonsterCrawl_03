import CoreGraphics

/// Shared shape for every sprite-sheet-backed family under `Assets/`.
///
/// Each concrete family (`PlayerAtlas`, `WeaponAtlas`, `BulletAtlas`, ...) is
/// a small, self-contained value type that records the *measured* facts
/// about its backing PNG -- sheet name, sheet size, cell size, and the
/// column/row counts of its cell grid -- exactly once. Consumers read cell
/// indices from the family's own semantic enums (e.g. `PlayerAtlas.Direction`)
/// rather than inline literals, and never reach into another family's
/// constants.
///
/// `GroundTileset` and `BuildingSet` are deliberately NOT `AtlasFamily`
/// conformers: the ground tileset's six diamonds are not on a uniform grid
/// (they were hand-measured, see `GroundTileset.swift`), and building
/// sprites are placed whole, never sliced.
protocol AtlasFamily {
    /// Name of the backing image in the asset catalog (no file extension) --
    /// this is exactly the string passed to `UIImage(named:)` /
    /// `SKTexture(imageNamed:)`.
    static var sheetName: String { get }

    /// Full sheet dimensions in pixels, as measured from the PNG.
    static var sheetSize: CGSize { get }

    /// Size of a single cell in pixels.
    static var cellSize: CGSize { get }

    /// Number of columns in the cell grid.
    static var columns: Int { get }

    /// Number of rows in the cell grid.
    static var rows: Int { get }
}

extension AtlasFamily {
    /// The pixel sub-rect (top-left origin, y-down -- i.e. Core Graphics /
    /// UIKit image-space convention) for a given (row, col) in this
    /// family's cell grid. Does not validate bounds -- see `isInBounds`.
    static func cellRect(row: Int, col: Int) -> CGRect {
        CGRect(
            x: CGFloat(col) * cellSize.width,
            y: CGFloat(row) * cellSize.height,
            width: cellSize.width,
            height: cellSize.height
        )
    }

    /// Whether `(row, col)` is a valid index into this family's cell grid.
    static func isInBounds(row: Int, col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < columns
    }
}
