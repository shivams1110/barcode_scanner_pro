/// Controls how the scanner emits results.
enum ScanMode {
  /// Emit the first detected barcode, then stop decoding until restarted.
  single,

  /// Emit every detected barcode continuously, subject to the duplicate filter.
  continuous,

  /// Emit all barcodes found within a single frame as a batch.
  multiBarcode;

  static ScanMode fromIndex(int i) =>
      i >= 0 && i < values.length ? values[i] : single;
}
