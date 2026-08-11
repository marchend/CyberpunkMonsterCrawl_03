import CoreGraphics
import UIKit

/// Reads the REAL pixels of a committed asset-catalog image so tests can
/// assert facts about the bytes rather than about a doc comment.
///
/// Everything in `docs/asset_manifest.json` is still
/// `PENDING-MEASUREMENT`, and the failure modes the repo cares about are all
/// silent ones that a green build never shows:
/// - an imageset that compiled EMPTY (bare-`filename` traversal bug, see
///   `AGENT.md`) still yields a texture, just a 1x1 placeholder;
/// - a wrong `sheetSize` still yields a valid normalized sub-rect over the
///   real sheet, just of the wrong region;
/// - `CGImage.alphaInfo != .none` says an alpha channel exists, not that any
///   pixel is actually translucent, so flattened transparency is invisible to
///   it.
///
/// Each of those is decidable from the pixels, which is what this type
/// exposes. It rasterizes the catalog image once into a known 8-bit RGBA
/// layout so alpha reads do not depend on the source PNG's colour space or on
/// whatever `actool` recompressed it to.
///
/// Coordinate convention: **top-left origin, y-DOWN**, matching
/// `AtlasFamily.cellRect` / `GroundTileset.rects` so a rect from production
/// code can be handed straight to a probe. Bounding boxes returned by this
/// type use **EXCLUSIVE** maxima (`maxX` / `maxY` are one past the last
/// content pixel), so `width` / `height` are true pixel counts.
struct PixelProbe {
    enum ProbeError: Error, CustomStringConvertible {
        /// `UIImage(named:)` returned nil -- the id is not in the compiled
        /// catalog. Never inferred from `SKTexture(imageNamed:)`, which
        /// silently substitutes a placeholder.
        case missingAsset(String)
        case noBackingCGImage(String)
        case emptyImage(String)
        case couldNotRasterize(String)

        var description: String {
            switch self {
            case .missingAsset(let name):
                return "asset '\(name)' does not resolve via UIImage(named:) -- it is absent from the compiled catalog, or its imageset compiled EMPTY"
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
    let width: Int
    let height: Int

    /// 8-bit premultiplied RGBA, row-major, `width * 4` bytes per row, first
    /// row = TOP row of the image. Premultiplication does not alter the alpha
    /// channel itself, so alpha reads are exact.
    private let rgba: [UInt8]

    init(assetName: String) throws {
        guard let image = UIImage(named: assetName) else {
            throw ProbeError.missingAsset(assetName)
        }
        guard let cgImage = image.cgImage else {
            throw ProbeError.noBackingCGImage(assetName)
        }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else {
            throw ProbeError.emptyImage(assetName)
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
            // alpha at the edges of a cell.
            context.interpolationQuality = .none
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            rasterized = true
        }
        guard rasterized else {
            throw ProbeError.couldNotRasterize(assetName)
        }

        self.assetName = assetName
        self.width = width
        self.height = height
        self.rgba = buffer
    }

    /// The image's real pixel size -- the thing a declared `sheetSize` has to
    /// agree with.
    var pixelSize: CGSize {
        CGSize(width: width, height: height)
    }

    /// The whole image as a rect, for the whole-image questions below.
    var wholeImageRect: CGRect {
        CGRect(origin: .zero, size: pixelSize)
    }

    /// Whether ANY pixel in the whole image has alpha < 255 -- the direct,
    /// pixel-level "transparency was preserved through import rather than
    /// flattened to opaque" fact. Unlike `CGImage.alphaInfo != .none`, which
    /// only says an alpha channel EXISTS, this says a pixel actually uses it.
    var hasAnyNonOpaquePixel: Bool {
        hasNonOpaquePixel(in: wholeImageRect)
    }

    /// Whether ANY pixel in the whole image has alpha > 0 -- the "this is not
    /// an empty imageset rendered as a blank canvas" fact.
    var hasAnyPaintedPixel: Bool {
        hasNonTransparentPixel(in: wholeImageRect)
    }

    /// Alpha of the pixel at `(x, y)`, top-left origin, y-down. Out-of-range
    /// coordinates read as fully transparent so callers can probe a rect that
    /// overhangs the sheet without trapping.
    func alpha(x: Int, y: Int) -> UInt8 {
        guard x >= 0, y >= 0, x < width, y < height else { return 0 }
        return rgba[(y * width + x) * 4 + 3]
    }

    /// Number of pixels in `rect` with any alpha at all.
    func nonTransparentPixelCount(in rect: CGRect) -> Int {
        var count = 0
        forEachPixel(in: rect) { x, y in
            if alpha(x: x, y: y) > 0 { count += 1 }
        }
        return count
    }

    func hasNonTransparentPixel(in rect: CGRect) -> Bool {
        nonTransparentPixelCount(in: rect) > 0
    }

    /// Whether any pixel in `rect` is partially or fully transparent. This is
    /// the real "transparency was preserved" check -- unlike
    /// `CGImage.alphaInfo`, it cannot pass on an image whose transparency was
    /// flattened to opaque during import.
    func hasNonOpaquePixel(in rect: CGRect) -> Bool {
        var found = false
        forEachPixel(in: rect) { x, y in
            if alpha(x: x, y: y) < 255 { found = true }
        }
        return found
    }

    /// Whether pixel column `x` is fully transparent over the whole sheet
    /// height -- the direct evidence for an inter-tile gutter.
    func columnIsFullyTransparent(_ x: Int) -> Bool {
        guard x >= 0, x < width else { return true }
        for y in 0..<height where alpha(x: x, y: y) > 0 {
            return false
        }
        return true
    }

    /// Per-column count of non-transparent pixels, left to right. Printing
    /// this is how a packing model gets proved instead of inferred.
    func columnAlphaProfile() -> [Int] {
        (0..<width).map { x in
            (0..<height).reduce(0) { $0 + (alpha(x: x, y: $1) > 0 ? 1 : 0) }
        }
    }

    /// Bounding box of all non-transparent pixels, or nil if the image is
    /// entirely transparent. **Maxima are EXCLUSIVE**: a single content pixel
    /// at (0, 0) yields `CGRect(x: 0, y: 0, width: 1, height: 1)`.
    func alphaBoundingBox() -> CGRect? {
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where alpha(x: x, y: y) > 0 {
                if x < minX { minX = x }
                if y < minY { minY = y }
                if x > maxX { maxX = x }
                if y > maxY { maxY = y }
            }
        }
        guard maxX >= 0, maxY >= 0 else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    /// The alpha silhouette of `rect`, row-major, as "has any alpha" flags.
    /// Compared instead of full RGB so a colour touch-up on an otherwise
    /// mirrored row does not read as a broken mirror.
    func alphaMask(in rect: CGRect) -> [Bool] {
        var mask: [Bool] = []
        forEachPixel(in: rect) { x, y in
            mask.append(alpha(x: x, y: y) > 0)
        }
        return mask
    }

    /// `alphaMask(in:)` with every row reversed left-to-right -- what a
    /// horizontally mirrored copy of `rect` would look like.
    func horizontallyMirroredAlphaMask(in rect: CGRect) -> [Bool] {
        let bounds = integerBounds(of: rect)
        var mask: [Bool] = []
        for y in bounds.minY..<bounds.maxY {
            for x in stride(from: bounds.maxX - 1, through: bounds.minX, by: -1) {
                mask.append(alpha(x: x, y: y) > 0)
            }
        }
        return mask
    }

    // MARK: - Rect iteration

    private struct IntegerBounds {
        let minX: Int, minY: Int, maxX: Int, maxY: Int
    }

    /// Snaps `rect` (which is authored in whole pixels everywhere in this
    /// codebase) to integer pixel indices, exclusive maxima.
    private func integerBounds(of rect: CGRect) -> IntegerBounds {
        IntegerBounds(
            minX: Int(rect.minX.rounded()),
            minY: Int(rect.minY.rounded()),
            maxX: Int(rect.maxX.rounded()),
            maxY: Int(rect.maxY.rounded())
        )
    }

    private func forEachPixel(in rect: CGRect, _ body: (Int, Int) -> Void) {
        let bounds = integerBounds(of: rect)
        guard bounds.maxX > bounds.minX, bounds.maxY > bounds.minY else { return }
        for y in bounds.minY..<bounds.maxY {
            for x in bounds.minX..<bounds.maxX {
                body(x, y)
            }
        }
    }
}
