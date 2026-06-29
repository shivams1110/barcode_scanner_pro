import 'package:barcode/barcode.dart' as bc;

import '../../domain/barcode_format.dart';
import '../../error/barcode_gen_exception.dart';

/// Validation helpers for linear symbologies. Numeric symbologies (EAN/UPC) use
/// a hand-written GS1 mod-10 check digit; charset-based symbologies (Code128,
/// Code39) delegate to the `barcode` package's own validity check.
///
/// `bc.Barcode.code128().isValid(String)` and `bc.Barcode.code39().isValid(String)`
/// both exist in barcode 2.2.9 — defined on the abstract [Barcode] base class as
/// a `@nonVirtual` method that calls `verify()` and returns true/false (never throws).
/// The `on Object` catch in [isValidCode128] and [isValidCode39] is an extra guard in
/// case a future package version changes that contract.
abstract final class BarcodeValidator {
  /// GS1 mod-10 over [data] (the digits BEFORE the check digit): the rightmost
  /// data digit has weight 3, alternating 1,3,… leftward.
  ///
  /// Throws [BarcodeGenException] for formats without a standalone numeric check
  /// digit (e.g. Code128 uses mod-103 over the full encoded symbol, not derivable
  /// from raw payload alone; QR uses Reed–Solomon).
  static int calculateChecksum(BarcodeFormat format, String data) {
    switch (format) {
      case BarcodeFormat.ean13:
      case BarcodeFormat.ean8:
      case BarcodeFormat.upcA:
        if (!_allDigits(data)) {
          throw BarcodeGenException(
            'checksum input must be digits',
            format: format,
          );
        }
        return _mod10(data);
      default:
        throw BarcodeGenException(
          'No standalone numeric checksum for ${format.name}',
          format: format,
        );
    }
  }

  /// Returns true iff [value] is a valid 13-digit EAN-13 barcode
  /// (correct length, all digits, check digit matches).
  static bool isValidEAN13(String value) =>
      _numericValid(value, 13, BarcodeFormat.ean13);

  /// Returns true iff [value] is a valid 8-digit EAN-8 barcode.
  static bool isValidEAN8(String value) =>
      _numericValid(value, 8, BarcodeFormat.ean8);

  /// Returns true iff [value] is a valid 12-digit UPC-A barcode.
  static bool isValidUPC(String value) =>
      _numericValid(value, 12, BarcodeFormat.upcA);

  /// Returns true iff [value] contains only Code 128-encodable characters.
  /// Delegates to [bc.Barcode.code128().isValid].
  static bool isValidCode128(String value) {
    try {
      return bc.Barcode.code128().isValid(value);
    } on Object {
      return false;
    }
  }

  /// Returns true iff [value] contains only Code 39-encodable characters
  /// (uppercase A–Z, digits 0–9, and the special characters -, ., $, /, +, %, space).
  /// Lowercase letters are NOT in the Code 39 charset and will return false.
  /// Delegates to [bc.Barcode.code39().isValid].
  static bool isValidCode39(String value) {
    try {
      return bc.Barcode.code39().isValid(value);
    } on Object {
      return false;
    }
  }

  // ---- internals ----

  static bool _numericValid(String value, int length, BarcodeFormat format) {
    if (value.length != length || !_allDigits(value)) return false;
    final data = value.substring(0, length - 1);
    final check = int.parse(value[length - 1]);
    return _mod10(data) == check;
  }

  /// GS1 mod-10: weight 3 on rightmost data digit, alternating 1,3 leftward.
  static int _mod10(String data) {
    var sum = 0;
    var weight = 3; // rightmost data digit weight 3
    for (var i = data.length - 1; i >= 0; i--) {
      sum += (data.codeUnitAt(i) - 0x30) * weight;
      weight = weight == 3 ? 1 : 3;
    }
    return (10 - (sum % 10)) % 10;
  }

  static bool _allDigits(String s) {
    if (s.isEmpty) return false;
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c < 0x30 || c > 0x39) return false;
    }
    return true;
  }
}
