import CoreGraphics

/// `sprite_player_walk.png` -- 144x320, sliced on a 36x40 cell grid: 4
/// columns of animation frames (contact / pass-L / contact / pass-R) x 8
/// rows, one per compass direction.
///
/// PROVENANCE: `declared`, not measured. `docs/asset_manifest.json` records
/// 144x320 / 36x40 / 4x8 for `sprite_player_walk` with `provenance:
/// "declared"` -- i.e. copied from `docs/bootstrap.md` prose and never
/// reconciled with the bytes (`_verification.status` is still
/// `PENDING-MEASUREMENT`). See `AssetProvenance`; the declared-vs-actual
/// sweep in `AtlasTextureLoaderTests` is what fails if the prose is wrong.
struct PlayerAtlas: AtlasFamily {
    static let sheetName = "sprite_player_walk"
    static let sheetSize = CGSize(width: 144, height: 320)
    static let sheetSizeProvenance = AssetProvenance.declared
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

    /// The 8 compass directions mapped to sheet rows. Every consumer must
    /// read directions through this enum rather than a raw row index.
    ///
    /// This ordering is NOT a free convention -- it is constrained by the
    /// art. `docs/asset_manifest.json` records for `sprite_player_walk`:
    /// *"rows 0-4 authored, rows 5-7 are MIRRORS of rows 3/2/1 (per prose --
    /// must be confirmed against pixels, not assumed)"*. If that mirror
    /// structure holds, the row->direction mapping is forced: row 5 must be
    /// the mirror of row 3, row 6 of row 2, row 7 of row 1. This
    /// clockwise-from-south ordering satisfies exactly that pairing
    /// (nw=3 <-> ne=5, w=2 <-> e=6, sw=1 <-> se=7). Do NOT "tidy" it into
    /// e.g. counter-clockwise: the numbers would still look reasonable while
    /// silently breaking the mirror pairing.
    ///
    /// UNCONFIRMED: whether rows 5-7 contain pre-mirrored pixels at all. The
    /// manifest flags the mirror claim as prose that must be checked against
    /// pixels, and `_verification.status` is still `PENDING-MEASUREMENT`. Two
    /// outcomes the constants alone cannot distinguish:
    /// - rows 5-7 hold pre-mirrored pixels -> consumers draw them as-is and
    ///   this enum is correct;
    /// - rows 5-7 are BLANK (only 5 rows authored, mirroring intended at
    ///   runtime via `xScale = -1`) -> `cellRect` still returns in-bounds
    ///   rects over empty pixels, `isInBounds` still passes, and the player
    ///   renders invisible for three of eight facings.
    ///
    /// `SheetRowContentTests` settles it against the bytes: it asserts every
    /// one of the 8 rows has a non-empty alpha bounding box, and that rows
    /// 5/6/7's alpha silhouettes are the horizontal mirrors of rows 3/2/1's.
    /// The same blank-row question applies to `RaccoonWalkAtlas` /
    /// `RaccoonAttackAtlas`, whose 8 rows carry no mirror note either way, so
    /// that suite sweeps their rows for content too.
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

    /// The mirror pairing `docs/asset_manifest.json` claims for this sheet:
    /// rows 5/6/7 are mirrors of rows 3/2/1. Recorded here (rather than
    /// retyped as row numbers inside a test) so `SheetRowContentTests` checks
    /// the claim the manifest actually makes, and so any future reordering of
    /// `Direction` has to reckon with this list. Still UNCONFIRMED against
    /// pixels -- see `Direction`.
    static let claimedMirroredRowPairs: [(authored: Direction, mirrored: Direction)] = [
        (authored: .northwest, mirrored: .northeast),  // row 3 -> row 5
        (authored: .west, mirrored: .east),            // row 2 -> row 6
        (authored: .southwest, mirrored: .southeast),  // row 1 -> row 7
    ]
}
