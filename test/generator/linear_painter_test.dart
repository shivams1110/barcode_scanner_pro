import 'dart:ui';

import 'package:barcode/barcode.dart' as bc;
import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/error/barcode_gen_exception.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/rendering/linear_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barcodeFor maps formats and rejects qr', () {
    expect(barcodeFor(BarcodeFormat.code128).name, bc.Barcode.code128().name);
    expect(barcodeFor(BarcodeFormat.ean13).name, bc.Barcode.ean13().name);
    expect(barcodeFor(BarcodeFormat.pdf417).name, bc.Barcode.pdf417().name);
    expect(barcodeFor(BarcodeFormat.aztec).name, bc.Barcode.aztec().name);
    expect(
      barcodeFor(BarcodeFormat.dataMatrix).name,
      bc.Barcode.dataMatrix().name,
    );
    expect(
      () => barcodeFor(BarcodeFormat.qr),
      throwsA(isA<BarcodeGenException>()),
    );
  });

  testWidgets('paint draws without throwing for valid data', (tester) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const req = BarcodeRequest(
      data: '012345678905',
      format: BarcodeFormat.upcA,
    );
    LinearPainter().paint(canvas, const Size(200, 100), req);
    final pic = recorder.endRecording();
    expect(pic, isNotNull);
  });

  testWidgets('invalid data surfaces BarcodeGenException', (tester) async {
    final canvas = Canvas(PictureRecorder());
    const req = BarcodeRequest(data: 'NOT-EAN', format: BarcodeFormat.ean13);
    expect(
      () => LinearPainter().paint(canvas, const Size(200, 100), req),
      throwsA(isA<BarcodeGenException>()),
    );
  });
}
