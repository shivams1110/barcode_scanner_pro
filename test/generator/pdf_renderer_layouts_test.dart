import 'dart:typed_data';

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/models/pdf_layout.dart';
import 'package:barcode_scanner_pro/src/generator/rendering/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

List<BarcodeRequest> _reqs(int n) => List.generate(
      n,
      (i) => BarcodeRequest(
          data: 'CODE${i.toString().padLeft(4, '0')}',
          format: BarcodeFormat.code128),
    );

void main() {
  for (final layout in <BarcodePdfLayout>[
    const BarcodePdfLayout.grid(columns: 2, rows: 3),
    const BarcodePdfLayout.a4(),
    BarcodePdfLayout.label(widthMm: 50, heightMm: 30),
    const BarcodePdfLayout.thermal(),
  ]) {
    testWidgets('layout ${layout.type} produces a valid multi-code PDF',
        (tester) async {
      Uint8List? pdf;
      await tester.runAsync(() async {
        pdf = await const PdfRenderer().render(_reqs(7), layout);
      });
      expect(pdf!.length, greaterThan(4));
      expect(String.fromCharCodes(pdf!.sublist(0, 4)), '%PDF');
    });
  }
}
