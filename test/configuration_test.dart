import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarcodeFormat', () {
    test('encode is the OR of member bits', () {
      final mask = BarcodeFormat.encode({BarcodeFormat.qr, BarcodeFormat.ean13});
      expect(mask, BarcodeFormat.qr.bit | BarcodeFormat.ean13.bit);
    });

    test('fromBit round-trips every format', () {
      for (final f in BarcodeFormat.values) {
        expect(BarcodeFormat.fromBit(f.bit), f);
      }
    });

    test('bits are unique', () {
      final bits = BarcodeFormat.values.map((f) => f.bit).toSet();
      expect(bits.length, BarcodeFormat.values.length);
    });
  });

  group('ScanArea', () {
    test('full covers the whole preview', () {
      expect(ScanArea.full.isFull, isTrue);
    });

    test('centeredSquare is symmetric', () {
      final a = ScanArea.centeredSquare(fraction: 0.6);
      expect(a.width, 0.6);
      expect(a.left, closeTo((1 - 0.6) / 2, 1e-9));
      expect(a.left + a.width, closeTo(1 - a.left, 1e-9));
    });
  });

  group('ScannerConfiguration', () {
    test('toMap encodes formats as a bitmask', () {
      const config = ScannerConfiguration(formats: {BarcodeFormat.qr});
      expect(config.toMap()['formats'], BarcodeFormat.qr.bit);
    });

    test('copyWith overrides only the given fields', () {
      const base = ScannerConfiguration();
      final updated = base.copyWith(frameRateLimit: 30, detectInverted: true);
      expect(updated.frameRateLimit, 30);
      expect(updated.detectInverted, isTrue);
      expect(updated.scanMode, base.scanMode);
    });

    test('duplicateTimeout serializes to milliseconds', () {
      const config =
          ScannerConfiguration(duplicateTimeout: Duration(milliseconds: 750));
      expect(config.toMap()['duplicateTimeoutMs'], 750);
    });
  });
}
