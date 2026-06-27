import Vision

/// Translates between the cross-platform format bitmask (Dart `BarcodeFormat`)
/// and Vision's `VNBarcodeSymbology`.
enum FormatMapper {
  // Bit positions must match Dart `BarcodeFormat.bit`.
  private static let qr = 1 << 0
  private static let code128 = 1 << 1
  private static let code39 = 1 << 2
  private static let code93 = 1 << 3
  private static let ean8 = 1 << 4
  private static let ean13 = 1 << 5
  private static let upcA = 1 << 6  // Vision has no dedicated UPC-A; maps via EAN-13.
  private static let upcE = 1 << 7
  private static let pdf417 = 1 << 8
  private static let aztec = 1 << 9
  private static let dataMatrix = 1 << 10
  private static let itf = 1 << 11
  private static let codabar = 1 << 12

  /// Builds the Vision symbology list requested by the bitmask.
  static func toSymbologies(_ mask: Int) -> [VNBarcodeSymbology] {
    var out: [VNBarcodeSymbology] = []
    if mask & qr != 0 { out.append(.qr) }
    if mask & code128 != 0 { out.append(.code128) }
    if mask & code39 != 0 { out.append(.code39) }
    if mask & code93 != 0 { out.append(.code93) }
    if mask & ean8 != 0 { out.append(.ean8) }
    if mask & ean13 != 0 { out.append(.ean13) }
    if mask & upcE != 0 { out.append(.upce) }
    if mask & pdf417 != 0 { out.append(.pdf417) }
    if mask & aztec != 0 { out.append(.aztec) }
    if mask & dataMatrix != 0 { out.append(.dataMatrix) }
    if mask & itf != 0 { out.append(.itf14); out.append(.i2of5) }
    if #available(iOS 15.0, *), mask & codabar != 0 { out.append(.codabar) }
    return out
  }

  /// Maps a Vision symbology back to our single-format bit value.
  static func toBit(_ sym: VNBarcodeSymbology) -> Int {
    switch sym {
    case .qr: return qr
    case .code128: return code128
    case .code39, .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum: return code39
    case .code93, .code93i: return code93
    case .ean8: return ean8
    case .ean13: return ean13
    case .upce: return upcE
    case .pdf417: return pdf417
    case .aztec: return aztec
    case .dataMatrix: return dataMatrix
    case .itf14, .i2of5, .i2of5Checksum: return itf
    default:
      if #available(iOS 15.0, *), sym == .codabar { return codabar }
      return qr
    }
  }
}
