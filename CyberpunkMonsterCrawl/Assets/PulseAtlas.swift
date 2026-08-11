import CoreGraphics

/// `sprite_pulse.png` -- measured 256x32, sliced on a 32x32 cell grid: 8
/// animation frames of the pulse shockwave, one row.
struct PulseAtlas: AtlasFamily {
    static let sheetName = "sprite_pulse"
    static let sheetSize = CGSize(width: 256, height: 32)
    static let cellSize = CGSize(width: 32, height: 32)
    static let columns = 8
    static let rows = 1

    static func cellRect(frame: Int) -> CGRect {
        cellRect(row: 0, col: frame)
    }
}
