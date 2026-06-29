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
  // Generator-added formats (bits must match Dart, even when Vision cannot
  // detect them as a distinct symbology).
  private static let gs128 = 1 << 13
  private static let itf14 = 1 << 14
  private static let itf16 = 1 << 15
  private static let ean5 = 1 << 16
  private static let ean2 = 1 << 17
  private static let isbn = 1 << 18
  private static let telepen = 1 << 19
  private static let rm4scc = 1 << 20
  private static let postnet = 1 << 21

  /// Builds the Vision symbology list requested by the bitmask.
  ///
  /// Several generator formats have no dedicated Vision symbology and collapse
  /// onto the one Vision actually detects:
  ///  - GS1-128 is a Code 128 application → `.code128`
  ///  - ITF-14 → `.itf14`; ITF-16 has no Vision constant → `.i2of5`
  ///  - ISBN is encoded as EAN-13 → `.ean13`
  /// A scan therefore reports the parent symbology's bit, not the subset.
  ///
  /// EAN-2, EAN-5, Telepen, RM4SCC and POSTNET are generate-only: Vision cannot
  /// detect them, so requesting them adds no symbology (silently ignored).
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
    // Subset formats collapse onto their detectable parent symbology.
    if mask & gs128 != 0 { out.append(.code128) }
    if mask & itf14 != 0 { out.append(.itf14) }
    if mask & itf16 != 0 { out.append(.i2of5) }
    if mask & isbn != 0 { out.append(.ean13) }
    // Subset formats may duplicate a parent symbology already requested; keep
    // the first occurrence of each so Vision receives a clean list.
    var seen = Set<VNBarcodeSymbology>()
    return out.filter { seen.insert($0).inserted }
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
