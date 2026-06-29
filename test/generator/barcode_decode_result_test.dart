import 'dart:typed_data';

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_decode_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('value equality + fields', () {
    final a = BarcodeDecodeResult(
      value: 'hello',
      format: BarcodeFormat.qr,
      rawBytes: Uint8List.fromList([1, 2]),
      cornerPoints: const [Offset(0, 0), Offset(1, 1)],
    );
    final b = BarcodeDecodeResult(
      value: 'hello',
      format: BarcodeFormat.qr,
      rawBytes: Uint8List.fromList([1, 2]),
      cornerPoints: const [Offset(0, 0), Offset(1, 1)],
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.toString(), contains('hello'));
  });

  test('fromMap parses channel payload', () {
    final r = BarcodeDecodeResult.fromMap({
      'value': 'X',
      'format': BarcodeFormat.code128.bit,
      'cornerPoints': [
        {'x': 1.0, 'y': 2.0},
      ],
    });
    expect(r.value, 'X');
    expect(r.format, BarcodeFormat.code128);
    expect(r.cornerPoints!.first, const Offset(1, 2));
  });
}
