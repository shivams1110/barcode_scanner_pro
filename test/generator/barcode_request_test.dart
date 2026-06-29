import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to const style/options and value equality', () {
    const r1 = BarcodeRequest(data: 'hi', format: BarcodeFormat.qr);
    const r2 = BarcodeRequest(data: 'hi', format: BarcodeFormat.qr);
    expect(r1, r2);
    expect(r1.isQr, isTrue);
    expect(r1.copyWith(data: 'bye').data, 'bye');
    expect(
      const BarcodeRequest(data: 'x', format: BarcodeFormat.code128).isQr,
      isFalse,
    );
  });
}
