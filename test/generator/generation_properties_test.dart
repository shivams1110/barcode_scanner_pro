import 'dart:ui' as ui;

import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

// Sample data for each of the 13 BarcodeFormat values.
//
// Changed from the brief's original samples:
//
// * upcE: '01234565' → '01200003' (8-digit UPC-E form, first=0, 6 middle digits,
//   checksum=3)
//   The barcode package's upcE() uses fallback:false. '01234565' expands to
//   UPC-A '012345000065', which cannot be compressed back to UPC-E under the
//   package's algorithm (the manufacturer/product code pattern doesn't satisfy
//   any of the four compressible cases), causing a BarcodeException.
//   '012000' expands to UPC-A '012000000005' but checksum digit is 3, not 5.
//   '01200003' is the correct 8-digit UPC-E (first=0, 6 digits, checksum=3),
//   which expands cleanly and compresses back via the '000'-suffix manufacturer
//   pattern (pattern 1).
//
// * itf: '1234567890' → stays as-is (even digit count, no checksum by default).
//
// * codabar: 'A123456A' → '1234567890'
//   With the default explicitStartStop:false, the body data must only contain
//   characters with ASCII code < 0x41. 'A' is 0x41, which triggers
//   BarcodeException. Pure-digit data like '1234567890' is always valid.
const _samples = <BarcodeFormat, String>{
  BarcodeFormat.qr: 'https://karnival.com',
  BarcodeFormat.code128: 'ABC-123',
  BarcodeFormat.code39: 'HELLO 123',
  BarcodeFormat.code93: 'HELLO93',
  BarcodeFormat.ean8: '96385074',
  BarcodeFormat.ean13: '4006381333931',
  BarcodeFormat.upcA: '036000291452',
  BarcodeFormat.upcE: '01200003',
  BarcodeFormat.itf: '1234567890',
  BarcodeFormat.codabar: '1234567890',
  BarcodeFormat.pdf417: 'PDF417 sample',
  BarcodeFormat.aztec: 'Aztec sample',
  BarcodeFormat.dataMatrix: 'DataMatrix sample',
};

void main() {
  const gen = BarcodeGenerator();

  testWidgets('every one of the 13 formats generates a PNG', (tester) async {
    await tester.runAsync(() async {
      for (final entry in _samples.entries) {
        final bytes = await gen.generateBytes(
          BarcodeRequest(data: entry.value, format: entry.key),
        );
        expect(bytes.length, greaterThan(8), reason: '${entry.key.name} empty');
        expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47],
            reason: '${entry.key.name} not PNG');
      }
    });
  });

  testWidgets('DPI scales raster pixel dimensions', (tester) async {
    await tester.runAsync(() async {
      for (final dpi in [300, 600, 1200]) {
        final result = await gen.generate(BarcodeRequest(
          data: 'https://karnival.com',
          format: BarcodeFormat.qr,
          options: BarcodeOptions(size: 100, dpi: dpi),
        ));
        final expected = (100 * dpi / 96).floor();
        expect(result.uiImage.width, expected, reason: 'dpi $dpi');
      }
    });
  });

  testWidgets('corner pixel reflects background; transparent => alpha 0',
      (tester) async {
    await tester.runAsync(() async {
      // Opaque white bg → top-left corner alpha 255.
      final opaque = await gen.generate(const BarcodeRequest(
        data: 'x', format: BarcodeFormat.qr,
        options: BarcodeOptions(size: 64),
      ));
      final od = await opaque.uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(od!.getUint8(3), 255);

      // Transparent bg → corner alpha 0.
      final clear = await gen.generate(const BarcodeRequest(
        data: 'x', format: BarcodeFormat.qr,
        options: BarcodeOptions(size: 64, transparentBackground: true),
      ));
      final cd = await clear.uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(cd!.getUint8(3), 0);
    });
  });
}
