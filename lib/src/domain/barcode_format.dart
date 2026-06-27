/// Supported 1D/2D barcode symbologies.
///
/// The integer [bit] value mirrors the bitmask used on the native side so that
/// a configured set of formats can be transferred across the method channel as
/// a single integer. Keeping the bit values in one place (here) is the single
/// source of truth shared with the Android and iOS implementations.
enum BarcodeFormat {
  qr(1 << 0),
  code128(1 << 1),
  code39(1 << 2),
  code93(1 << 3),
  ean8(1 << 4),
  ean13(1 << 5),
  upcA(1 << 6),
  upcE(1 << 7),
  pdf417(1 << 8),
  aztec(1 << 9),
  dataMatrix(1 << 10),
  itf(1 << 11),
  codabar(1 << 12);

  const BarcodeFormat(this.bit);

  /// Bit position used in the cross-platform format bitmask.
  final int bit;

  /// Convenience set representing every supported format.
  static const Set<BarcodeFormat> all = {
    qr,
    code128,
    code39,
    code93,
    ean8,
    ean13,
    upcA,
    upcE,
    pdf417,
    aztec,
    dataMatrix,
    itf,
    codabar,
  };

  /// Encodes a set of formats into the cross-platform bitmask.
  static int encode(Set<BarcodeFormat> formats) =>
      formats.fold(0, (mask, f) => mask | f.bit);

  /// Decodes a single native format identifier back into an enum value.
  ///
  /// Falls back to [BarcodeFormat.qr] only when the native layer reports an
  /// unknown value, which should not happen in practice.
  static BarcodeFormat fromBit(int bit) =>
      values.firstWhere((f) => f.bit == bit, orElse: () => qr);
}
