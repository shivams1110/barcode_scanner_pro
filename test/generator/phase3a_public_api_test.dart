import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phase 3a public surface resolves from root', () {
    expect(BarcodeValidator.isValidEAN13('4006381333931'), isTrue);
    expect(BarcodeValidator.calculateChecksum(BarcodeFormat.upcA, '03600029145'), 2);
    final r = BarcodeGenerator.wifi(ssid: 'N');
    expect(r.format, BarcodeFormat.qr);
    // Decode contract type is exported (compile-time resolution):
    const result = BarcodeDecodeResult(value: 'x', format: BarcodeFormat.qr);
    expect(result.value, 'x');
  });
}
