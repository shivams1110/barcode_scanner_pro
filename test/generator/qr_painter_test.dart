import 'dart:ui' as ui;

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/error/barcode_gen_exception.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_logo.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_style.dart';
import 'package:barcode_scanner_pro/src/generator/models/enums.dart';
import 'package:barcode_scanner_pro/src/generator/rendering/qr_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _square() {
  final r = ui.PictureRecorder();
  Canvas(r).drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint());
  return r.endRecording().toImage(8, 8);
}

void main() {
  test('buildQrCode encodes data', () {
    const req = BarcodeRequest(data: 'https://x.io', format: BarcodeFormat.qr);
    expect(buildQrCode(req).moduleCount, greaterThan(0));
  });

  testWidgets('paint draws styled modules without throwing', (tester) async {
    final canvas = Canvas(ui.PictureRecorder());
    const req = BarcodeRequest(
      data: 'hello',
      format: BarcodeFormat.qr,
      style: BarcodeStyle(
        moduleShape: ModuleShape.rounded,
        eyeShape: EyeShape.circular,
        gradient: BarcodeGradient(
          type: GradientType.linear,
          colors: [Color(0xFF000000), Color(0xFF2222FF)],
        ),
      ),
    );
    QrPainter().paint(canvas, const Size(210, 210), req);
  });

  testWidgets('logo with low ecc throws', (tester) async {
    final img = await _square();
    final req = BarcodeRequest(
      data: 'x',
      format: BarcodeFormat.qr,
      style: BarcodeStyle(
        errorCorrection: ErrorCorrection.low,
        logo: BarcodeLogo(image: img),
      ),
    );
    expect(
      () => QrPainter()
          .paint(Canvas(ui.PictureRecorder()), const Size(100, 100), req),
      throwsA(isA<BarcodeGenException>()),
    );
  });
}
