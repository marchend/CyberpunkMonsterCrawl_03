import CoreGraphics

/// Test-only, single-purpose façade over `PixelProbe`: answers the two
/// whole-image alpha questions the catalog-wide sweep in
/// `TextureFilteringGateTests` asks, under names that say what is being
/// proved.
///
/// - `hasAnyNonOpaquePixel` -- does ANY pixel have alpha < 255? That is the
///   direct, pixel-level proof that transparency was preserved through the
///   asset pipeline rather than flattened to opaque during import, which
///   `CGImage.alphaInfo` cannot tell you: `alphaInfo != .none` only means an
///   alpha channel EXISTS, not that any pixel actually uses it (see
///   `BuildingSet.cgImageHasAlphaChannel`'s doc comment for the same point).
/// - `hasAnyPaintedPixel` -- does ANY pixel have alpha > 0? i.e. this is not
///   an imageset that compiled EMPTY and rasterized to a blank canvas.
///
/// **This type deliberately owns NO pixel handling of its own.** It composes
/// a `PixelProbe` and forwards to `PixelProbe.hasAnyNonOpaquePixel` /
/// `hasAnyPaintedPixel`. An earlier version of this file re-implemented
/// `PixelProbe.init`'s rasterization line-for-line (same `CGContext` config,
/// same `premultipliedLast`, same `interpolationQuality = .none`, same four
/// error cases). Two copies of the rasterization path meant a future fix to
/// one -- a `bytesPerRow` alignment case, a colour-space surprise out of
/// `actool` -- silently would not reach the other, and this is precisely the
/// layer the repo trusts to tell measured facts from inferred ones. There is
/// now exactly one rasterizer in the test target, in `PixelProbe`.
///
/// Errors therefore come straight from `PixelProbe.ProbeError` (including
/// `.missingAsset` when `UIImage(named:)` returns nil) rather than a parallel
/// error enum that would have to be kept in sync.
struct ImageAlphaInspector {
    private let probe: PixelProbe

    /// The catalog id under inspection.
    var assetName: String { probe.assetName }

    /// The image's real pixel size, as measured by the probe.
    var pixelSize: CGSize { probe.pixelSize }

    /// True if at least one pixel anywhere in the image has alpha < 255,
    /// i.e. the image is not entirely opaque -- the "transparency was not
    /// flattened" fact.
    var hasAnyNonOpaquePixel: Bool { probe.hasAnyNonOpaquePixel }

    /// True if at least one pixel anywhere in the image has alpha > 0,
    /// i.e. the image is not entirely transparent -- the "this is not an
    /// empty imageset rendered as a blank canvas" fact.
    var hasAnyPaintedPixel: Bool { probe.hasAnyPaintedPixel }

    /// Throws `PixelProbe.ProbeError` -- `.missingAsset` for an id that does
    /// not resolve via `UIImage(named:)` (absent from the compiled catalog,
    /// or compiled EMPTY), and the probe's other rasterization failures.
    init(assetName: String) throws {
        self.probe = try PixelProbe(assetName: assetName)
    }

    /// For callers that already hold a probe for this asset, so a sweep never
    /// rasterizes the same image twice.
    init(probe: PixelProbe) {
        self.probe = probe
    }
}
