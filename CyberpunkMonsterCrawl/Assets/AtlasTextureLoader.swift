import CoreGraphics
import SpriteKit
import UIKit

/// Errors thrown by `AtlasTextureLoader` and `BuildingSet` when the asset
/// contract is violated.
enum AtlasLoadError: Error, Equatable {
    /// `name` does not resolve to an image in the asset catalog
    /// (`UIImage(named:)` returned `nil`). Deliberately checked this way,
    /// not inferred from `SKTexture(imageNamed:)`, which silently returns a
    /// magenta placeholder texture instead of failing on a missing asset.
    case missingAsset(name: String)

    /// `(row, col)` is out of bounds for the named family's cell grid.
    case indexOutOfBounds(name: String, row: Int, col: Int)
}

/// Caches parent sheet `SKTexture`s by asset-catalog name and vends sliced
/// cell textures for any `AtlasFamily`, plus arbitrary pixel sub-rects (for
/// `GroundTileset`'s hand-measured diamonds). Every texture this loader
/// returns -- whole sheet or sliced sub-texture -- has `.filteringMode =
/// .nearest` and `.usesMipmaps = false` applied uniformly, so pixel art is
/// never smoothed by SpriteKit's default linear filtering / mipmapping.
final class AtlasTextureLoader {
    /// Shared instance for production call sites. Tests construct their own
    /// instance so cache state never leaks between tests.
    static let shared = AtlasTextureLoader()

    private var sheetCache: [String: SKTexture] = [:]

    init() {}

    /// Returns the whole backing sheet texture for `name`, from cache if
    /// already loaded. Throws `AtlasLoadError.missingAsset` if the image
    /// does not exist in the asset catalog.
    func sheetTexture(named name: String) throws -> SKTexture {
        if let cached = sheetCache[name] {
            return cached
        }
        guard UIImage(named: name) != nil else {
            throw AtlasLoadError.missingAsset(name: name)
        }
        let texture = SKTexture(imageNamed: name)
        Self.applyPixelArtFiltering(to: texture)
        sheetCache[name] = texture
        return texture
    }

    /// Returns the sliced cell texture for `(row, col)` of `family`. The
    /// parent sheet texture is cached (see `sheetTexture`); the sliced
    /// sub-texture itself is a cheap view and is not separately cached.
    func cellTexture<Family: AtlasFamily>(for family: Family.Type, row: Int, col: Int) throws -> SKTexture {
        guard Family.isInBounds(row: row, col: col) else {
            throw AtlasLoadError.indexOutOfBounds(name: Family.sheetName, row: row, col: col)
        }
        let sheet = try sheetTexture(named: Family.sheetName)
        let pixelRect = Family.cellRect(row: row, col: col)
        return Self.slicedTexture(from: sheet, pixelRect: pixelRect, sheetSize: Family.sheetSize)
    }

    /// Returns a texture for an arbitrary pixel sub-rect of a named sheet.
    /// Used by callers slicing a non-uniform grid (e.g. `GroundTileset`'s
    /// hand-measured diamonds) where `AtlasFamily`'s row/col addressing
    /// doesn't apply.
    func texture(named name: String, pixelRect: CGRect, sheetSize: CGSize) throws -> SKTexture {
        let sheet = try sheetTexture(named: name)
        return Self.slicedTexture(from: sheet, pixelRect: pixelRect, sheetSize: sheetSize)
    }

    /// Slices `pixelRect` (top-left origin, y-down, in pixels of
    /// `sheetSize`) out of `sheet`, converting to the unit coordinate space
    /// `SKTexture(rect:in:)` expects (origin bottom-left, y-up), and applies
    /// the shared pixel-art filtering settings to the result.
    private static func slicedTexture(from sheet: SKTexture, pixelRect: CGRect, sheetSize: CGSize) -> SKTexture {
        let normalizedRect = CGRect(
            x: pixelRect.origin.x / sheetSize.width,
            y: 1 - (pixelRect.origin.y + pixelRect.height) / sheetSize.height,
            width: pixelRect.width / sheetSize.width,
            height: pixelRect.height / sheetSize.height
        )
        let texture = SKTexture(rect: normalizedRect, in: sheet)
        applyPixelArtFiltering(to: texture)
        return texture
    }

    private static func applyPixelArtFiltering(to texture: SKTexture) {
        texture.filteringMode = .nearest
        texture.usesMipmaps = false
    }
}
