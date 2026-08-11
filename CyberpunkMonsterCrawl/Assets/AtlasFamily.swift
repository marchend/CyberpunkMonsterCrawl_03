import CoreGraphics

/// Where a recorded number actually came from. Mirrors the `provenance`
/// field of the matching entry in `docs/asset_manifest.json`, which the repo
/// designates as "the ONE record of measured facts", so a reader can tell
/// measured-from-bytes from copied-from-prose without leaving the code.
///
/// `docs/asset_manifest.json`'s `hard_rule` is: *"A consumer may only use a
/// value whose provenance is 'measured'. Do not copy numbers out of the
/// ticket table or bootstrap prose into slicing code."* Its
/// `_verification.status` is still `PENDING-MEASUREMENT` (`measured_on:
/// null`) because this workspace has no macOS/`sips`/Xcode, so **no family
/// in this PR may claim `.measured`**. The values pinned here are therefore
/// explicitly labelled `.declared` or `.unmeasured`, and they are *enforced*
/// rather than asserted: `AtlasTextureLoaderTests`'
/// declared-vs-actual sweep loads every sheet and fails when a declared
/// `sheetSize` disagrees with the real pixel size, printing the measured
/// value to record. That test -- not a doc comment -- is what keeps the
/// manifest and this code from drifting apart.
///
/// Promotion procedure: run `bash ./verify_assets.sh` on a macOS checkout,
/// record the measured dimensions + `measured_on` in
/// `docs/asset_manifest.json`, flip that entry's `provenance` to `measured`,
/// and only then flip the family's `sheetSizeProvenance` to `.measured` in
/// the same change.
enum AssetProvenance: String, Equatable {
    /// Read out of the committed PNG's bytes by `bash ./verify_assets.sh`
    /// and recorded in `docs/asset_manifest.json` with a `measured_on` date.
    case measured

    /// Stated in `docs/bootstrap.md` prose and copied into the manifest, but
    /// never reconciled with the bytes. A working value, not a measurement.
    case declared

    /// The manifest carries no dimensions for this sheet at all (null
    /// width/height). Anything pinned here is a working assumption whose
    /// only guard is the declared-vs-actual test.
    case unmeasured
}

/// Shared shape for every sprite-sheet-backed family under `Assets/`.
///
/// Each concrete family (`PlayerAtlas`, `WeaponAtlas`, `BulletAtlas`, ...) is
/// a small, self-contained value type that records the facts about its
/// backing PNG -- sheet name, sheet size, cell size, the column/row counts
/// of its cell grid, and **where those numbers came from**
/// (`sheetSizeProvenance`) -- exactly once. Consumers read cell
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

    /// Full sheet dimensions in pixels. Read `sheetSizeProvenance` before
    /// trusting this: it is only a measurement when that says `.measured`.
    static var sheetSize: CGSize { get }

    /// Where `sheetSize` / `cellSize` / `columns` / `rows` came from, per
    /// the matching entry in `docs/asset_manifest.json`. Defaults to
    /// `.unmeasured` -- the weakest claim -- so a family that forgets to
    /// state it never accidentally asserts that its numbers were measured.
    static var sheetSizeProvenance: AssetProvenance { get }

    /// Size of a single cell in pixels.
    static var cellSize: CGSize { get }

    /// Number of columns in the cell grid.
    static var columns: Int { get }

    /// Number of rows in the cell grid.
    static var rows: Int { get }
}

extension AtlasFamily {
    /// Weakest-claim default: a family that does not state its provenance is
    /// treated as unmeasured rather than as measured.
    static var sheetSizeProvenance: AssetProvenance { .unmeasured }

    /// Whether this family's cell grid divides evenly into its declared
    /// sheet size. Pure arithmetic over the declared numbers -- it says
    /// nothing about the real PNG (that is the declared-vs-actual test's
    /// job), only that the numbers recorded here are self-consistent.
    static var cellGridDividesEvenlyIntoSheet: Bool {
        CGFloat(columns) * cellSize.width == sheetSize.width
            && CGFloat(rows) * cellSize.height == sheetSize.height
    }

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
