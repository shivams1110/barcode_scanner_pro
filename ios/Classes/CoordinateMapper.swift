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

  /// True when the center of a Vision-normalized [box] is within [area].
  static func isInside(box: CGRect, area: ScanAreaConfig) -> Bool {
    if area.isFull { return true }
    let nx = box.midX
    // Flip Y to top-left origin.
    let ny = 1.0 - box.midY
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
