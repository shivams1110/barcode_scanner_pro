import '../domain/barcode_format.dart';

/// Thrown when a [BarcodeRequest] cannot be encoded: invalid data for the
/// chosen symbology, capacity exceeded, or an unsupported styling combination
/// (e.g. a logo with insufficient QR error correction).
class BarcodeGenException implements Exception {
  const BarcodeGenException(this.message, {this.format});

  /// Human-readable reason.
  final String message;

  /// Symbology being generated when the error occurred, if known.
  final BarcodeFormat? format;

  @override
  String toString() {
    final fmt = format;
    return fmt == null
        ? 'BarcodeGenException: $message'
        : 'BarcodeGenException(${fmt.name}): $message';
  }
}
