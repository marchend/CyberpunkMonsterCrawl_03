import UIKit

/// A building sprite's footprint on the world grid.
enum BuildingFootprint {
    case oneByOne
    case twoByTwo
}

/// A coarse height classification used for depth-sorting / visual variety,
/// taken from the story's table (not measured -- it's a design label, not a
/// pixel fact).
enum BuildingHeightClass {
    case lowest
    case low
    case mid
    case tall
    case largeTower
}

/// A single loaded `building_00`...`building_11` sprite. `measuredSize` and
/// `hasAlphaChannel` are measured from the loaded catalog image at init
/// time -- never inferred from the filename -- while `footprint` and
/// `heightClass` are looked up from the story's table by asset name.
struct BuildingSprite {
    let assetName: String
    let measuredSize: CGSize
    let hasAlphaChannel: Bool
    let footprint: BuildingFootprint
    let heightClass: BuildingHeightClass
}

/// Loads and measures the 12 whole-sprite (never sliced) building images.
enum BuildingSet {
    /// Footprint / height-class table, from the story:
    /// building_00-03: 1x1, low (~2 storey); building_04: 1x1, mid
    /// (~3 storey); building_05: 1x1, tall (~4 storey); building_06-07:
    /// 1x1, mid (~2-3 storey); building_08-09: 2x2, wide/mid;
    /// building_10: 1x1, lowest (~1 storey); building_11: 2x2, large tower.
    static let definitions: [(assetName: String, footprint: BuildingFootprint, heightClass: BuildingHeightClass)] = [
        ("building_00", .oneByOne, .low),
        ("building_01", .oneByOne, .low),
        ("building_02", .oneByOne, .low),
        ("building_03", .oneByOne, .low),
        ("building_04", .oneByOne, .mid),
        ("building_05", .oneByOne, .tall),
        ("building_06", .oneByOne, .mid),
        ("building_07", .oneByOne, .mid),
        ("building_08", .twoByTwo, .mid),
        ("building_09", .twoByTwo, .mid),
        ("building_10", .oneByOne, .lowest),
        ("building_11", .twoByTwo, .largeTower),
    ]

    /// Loads and measures a single building sprite. Throws
    /// `AtlasLoadError.missingAsset` if `assetName` doesn't resolve to a
    /// catalog image (checked via `UIImage(named:)`, never inferred from
    /// SpriteKit's silent-placeholder texture behavior).
    static func load(assetName: String, footprint: BuildingFootprint, heightClass: BuildingHeightClass) throws -> BuildingSprite {
        guard let image = UIImage(named: assetName), let cgImage = image.cgImage else {
            throw AtlasLoadError.missingAsset(name: assetName)
        }
        let measuredSize = CGSize(width: cgImage.width, height: cgImage.height)
        let hasAlphaChannel = Self.cgImageHasAlphaChannel(cgImage)
        return BuildingSprite(
            assetName: assetName,
            measuredSize: measuredSize,
            hasAlphaChannel: hasAlphaChannel,
            footprint: footprint,
            heightClass: heightClass
        )
    }

    /// Loads and measures every entry in `definitions`, in table order.
    static func loadAll() throws -> [BuildingSprite] {
        try definitions.map { try load(assetName: $0.assetName, footprint: $0.footprint, heightClass: $0.heightClass) }
    }

    /// Whether the loaded image's underlying `CGImage` carries an alpha
    /// channel at all (a necessary, though not sufficient, condition for
    /// "transparency was preserved" -- the story's stronger "non-opaque"
    /// pixel check is asserted by the PR 4 test suite against these
    /// measurements).
    private static func cgImageHasAlphaChannel(_ cgImage: CGImage) -> Bool {
        switch cgImage.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        default:
            return true
        }
    }
}
