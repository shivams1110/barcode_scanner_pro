import CoreGraphics
import ImageIO

/// Converts Vision's normalized, bottom-left-origin geometry into the
/// pixel-space, top-left-origin representation the Dart layer expects.
///
/// Frames are handed to Vision already oriented upright (via
/// `CGImagePropertyOrientation`), so the reported `imageSize` is the oriented
/// size and `rotation` is always 0 on iOS — the Flutter overlay then maps
/// detections to the upright preview with no extra rotation.
enum CoordinateMapper {

  /// Oriented (upright) pixel size for a buffer of [width]x[height].
  static func orientedSize(
    width: Int, height: Int, orientation: CGImagePropertyOrientation
  ) -> CGSize {
    switch orientation {
    case .left, .right, .leftMirrored, .rightMirrored:
      return CGSize(width: height, height: width)
    default:
      return CGSize(width: width, height: height)
    }
  }

  /// True when the center of a Vision-normalized [box] (in an upright image of
  /// [imageSize]) is within [area], which is normalized to the visible part of
  /// an aspect-fill preview of [viewSize]. The preview scales the image to
  /// cover the view and crops the overflow equally on both sides, so the
  /// detection is mapped into that visible region first. A zero [viewSize]
  /// (not laid out yet) falls back to the uncropped image.
  static func isInside(
    box: CGRect, area: ScanAreaConfig, imageSize: CGSize, viewSize: CGSize
  ) -> Bool {
    if area.isFull { return true }
    var visibleW = 1.0
    var visibleH = 1.0
    if viewSize.width > 0, viewSize.height > 0, imageSize.width > 0, imageSize.height > 0 {
      let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
      visibleW = Double(viewSize.width / scale / imageSize.width)
      visibleH = Double(viewSize.height / scale / imageSize.height)
    }
    // Flip Y to top-left origin, then into visible-region coordinates.
    let nx = (Double(box.midX) - (1 - visibleW) / 2) / visibleW
    let ny = (Double(1.0 - box.midY) - (1 - visibleH) / 2) / visibleH
    return nx >= area.left && nx <= area.left + area.width
      && ny >= area.top && ny <= area.top + area.height
  }

  /// Converts a Vision-normalized point (bottom-left origin) to a pixel point
  /// (top-left origin) within an image of [size].
  static func toPixel(_ p: CGPoint, size: CGSize) -> [String: Double] {
    [
      "x": Double(p.x) * Double(size.width),
      "y": Double(1.0 - p.y) * Double(size.height),
    ]
  }

  /// Converts a Vision-normalized rect to a pixel rect (top-left origin).
  static func toPixelRect(_ r: CGRect, size: CGSize) -> [String: Double] {
    let left = Double(r.minX) * Double(size.width)
    let top = Double(1.0 - r.maxY) * Double(size.height)
    return [
      "left": left,
      "top": top,
      "width": Double(r.width) * Double(size.width),
      "height": Double(r.height) * Double(size.height),
    ]
  }
}
