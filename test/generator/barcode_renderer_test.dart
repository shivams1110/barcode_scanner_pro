import 'dart:ui';

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_options.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/rendering/barcode_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('routes qr and linear without throwing', (tester) async {
    const r = BarcodeRenderer();
    r.paint(Canvas(PictureRecorder()), const Size(200, 200),
        const BarcodeRequest(data: 'qr', format: BarcodeFormat.qr));
    r.paint(Canvas(PictureRecorder()), const Size(200, 80),
        const BarcodeRequest(data: 'CODE128', format: BarcodeFormat.code128));
  });

  testWidgets('applies rotation transform', (tester) async {
    const r = BarcodeRenderer();
    r.paint(
      Canvas(PictureRecorder()),
      const Size(200, 200),
      const BarcodeRequest(
        data: 'qr',
        format: BarcodeFormat.qr,
        options: BarcodeOptions(rotationDegrees: 90),
      ),
    );
  });
}
