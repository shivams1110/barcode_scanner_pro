import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/error/barcode_gen_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message and format surface in toString', () {
    final e = BarcodeGenException('too long', format: BarcodeFormat.ean13);
    expect(e.message, 'too long');
    expect(e.format, BarcodeFormat.ean13);
    expect(e.toString(), contains('too long'));
    expect(e.toString(), contains('ean13'));
  });
}
