import 'package:barcode/barcode.dart' as bc;
import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/rendering/linear_painter.dart'
    show barcodeFor;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Sample payloads that satisfy each new symbology's input rules.
  const samples = <BarcodeFormat, String>{
    BarcodeFormat.gs128: '(01)00012345678905',
    BarcodeFormat.itf14: '1234567890123',
    BarcodeFormat.itf16: '123456789012345',
    BarcodeFormat.ean5: '12345',
    BarcodeFormat.ean2: '12',
    BarcodeFormat.isbn: '9781234567897',
    BarcodeFormat.telepen: 'ABC123',
    BarcodeFormat.rm4scc: 'BX11LT1A',
    BarcodeFormat.postnet: '55555',
  };

  group('newly wired symbologies encode without throwing', () {
    for (final entry in samples.entries) {
      test('${entry.key.name} produces bars', () {
        final symbology = barcodeFor(entry.key);
        final elements = symbology
            .make(entry.value, width: 200, height: 80, drawText: false)
            .whereType<bc.BarcodeBar>()
            .toList();
        expect(elements, isNotEmpty);
        expect(elements.any((b) => b.black), isTrue);
      });
    }
  });
}
