import CoreGraphics
import UIKit

/// Test-only, deliberately smaller sibling of `PixelProbe`: rasterizes a
/// catalog image's `CGImage` into 8-bit RGBA and answers exactly one
/// question -- does ANY pixel have alpha < 255? That is the direct,
/// pixel-level proof that transparency was preserved through the asset
/// pipeline rather than flattened to opaque during import, which
/// `CGImage.alphaInfo` cannot tell you: `alphaInfo != .none` only means an
/// alpha channel EXISTS, not that any pixel actually uses it (see
/// `BuildingSet.cgImageHasAlphaChannel`'s doc comment for the same point).
///
/// `PixelProbe` already does a fuller version of this (per-pixel alpha
/// reads at arbitrary coordinates, bounding boxes, mirrored masks, ...) for
/// the ground-tileset and direction-row tests, and `BuildingSetTests`
/// already samples real corner alpha through it. This type is the minimal,
/// single-purpose helper the ticket calls for -- a whole-image yes/no
/// answer -- used by `TextureFilteringGateTests`'s catalog-wide alpha sweep
/// so that sweep does not need to pull in `PixelProbe`'s larger
/// pixel-addressing surface for a question this simple.
struct ImageAlphaInspector {
    enum InspectorError: Error, CustomStringConvertible {
        /// `UIImage(named:)` returned nil -- the id is not in the compiled
        /// catalog, or its imageset compiled EMPTY.
        case missingAsset(String)
        case noBackingCGImage(String)
        case emptyImage(String)
        case couldNotRasterize(String)

        var description: String {
            switch self {
            case .missingAsset(let name):
                return "asset '\(name)' does not resolve via UIImage(named:)"
            case .noBackingCGImage(let name):
                return "asset '\(name)' loaded but has no backing CGImage"
            case .emptyImage(let name):
                return "asset '\(name)' rasterized to a zero-sized image"
            case .couldNotRasterize(let name):
                return "could not rasterize asset '\(name)' into an 8-bit RGBA bitmap"
            }
        }
    }

    let assetName: String

    /// True if at least one pixel anywhere in the image has alpha < 255,
    /// i.e. the image is not entirely opaque -- the "transparency was not
    /// flattened" fact.
    let hasAnyNonOpaquePixel: Bool

    /// True if at least one pixel anywhere in the image has alpha > 0,
    /// i.e. the image is not entirely transparent -- the "this is not an
    /// empty imageset rendered as a blank canvas" fact.
    let hasAnyPaintedPixel: Bool

    init(assetName: String) throws {
        guard let image = UIImage(named: assetName) else {
            throw InspectorError.missingAsset(assetName)
        }
        guard let cgImage = image.cgImage else {
            throw InspectorError.noBackingCGImage(assetName)
        }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else {
            throw InspectorError.emptyImage(assetName)
        }

        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        var rasterized = false
        buffer.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress else { return }
            guard let context = CGContext(
                data: base,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return }
            // Nearest-neighbour, 1:1, so no resampling can invent or erase
            // alpha anywhere in the image.
            context.interpolationQuality = .none
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            rasterized = true
        }
        guard rasterized else {
            throw InspectorError.couldNotRasterize(assetName)
        }

        var foundNonOpaque = false
        var foundPainted = false
        let pixelCount = width * height
        var index = 0
        while index < pixelCount, !(foundNonOpaque && foundPainted) {
            let alpha = buffer[index * 4 + 3]
            if alpha < 255 { foundNonOpaque = true }
            if alpha > 0 { foundPainted = true }
            index += 1
        }

        self.assetName = assetName
        self.hasAnyNonOpaquePixel = foundNonOpaque
        self.hasAnyPaintedPixel = foundPainted
    }
}
