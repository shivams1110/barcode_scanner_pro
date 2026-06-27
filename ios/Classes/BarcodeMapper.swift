import CoreGraphics
import Vision

/// Converts a `VNBarcodeObservation` into the cross-platform result dictionary
/// consumed by Dart `BarcodeResult.fromMap`.
enum BarcodeMapper {

  static func toMap(
    _ obs: VNBarcodeObservation,
    orientedSize: CGSize,
    timestampMs: Int64
  ) -> [String: Any?] {
    let corners = [obs.topLeft, obs.topRight, obs.bottomRight, obs.bottomLeft]
      .map { CoordinateMapper.toPixel($0, size: orientedSize) }

    return [
      "value": obs.payloadStringValue ?? "",
      "format": FormatMapper.toBit(obs.symbology),
      "boundingBox": CoordinateMapper.toPixelRect(obs.boundingBox, size: orientedSize),
      "cornerPoints": corners,
      "timestamp": timestampMs,
      "rawBytes": nil,
      "imageWidth": Int(orientedSize.width),
      "imageHeight": Int(orientedSize.height),
      "rotation": 0,
      "confidence": Double(obs.confidence),
    ]
  }

  /// Stable dedup key for the duplicate filter.
  static func dedupKey(_ obs: VNBarcodeObservation) -> String {
    "\(obs.symbology.rawValue):\(obs.payloadStringValue ?? "")"
  }
}
