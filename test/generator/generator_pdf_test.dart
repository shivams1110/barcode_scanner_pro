import 'dart:io';

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/error/barcode_gen_exception.dart';
import 'package:barcode_scanner_pro/src/generator/generator_service.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/models/pdf_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = BarcodeGenerator();
  const req = BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA);

  testWidgets('generatePdf default + grid layout', (tester) async {
    await tester.runAsync(() async {
      final a = await gen.generatePdf(const [req]);
      expect(String.fromCharCodes(a.sublist(0, 4)), '%PDF');
      final b = await gen.generatePdf(const [req, req],
          layout: const BarcodePdfLayout.grid(columns: 2, rows: 2));
      expect(String.fromCharCodes(b.sublist(0, 4)), '%PDF');
    });
  });

  testWidgets('save dispatches by extension', (tester) async {
    final dir = Directory.systemTemp.createTempSync('bsp_save');
    await tester.runAsync(() async {
      final svg = await gen.save(req, '${dir.path}/a.svg');
      final pdf = await gen.save(req, '${dir.path}/a.pdf');
      expect(svg.readAsStringSync(), contains('<svg'));
      expect(String.fromCharCodes(pdf.readAsBytesSync().sublist(0, 4)), '%PDF');
    });
    dir.deleteSync(recursive: true);
  });

  test('save rejects unknown extension', () {
    expect(() => gen.save(req, '/tmp/a.bmp'),
        throwsA(isA<BarcodeGenException>()));
  });
}
