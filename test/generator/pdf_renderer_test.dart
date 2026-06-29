import 'dart:typed_data';

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/error/barcode_gen_exception.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/models/pdf_layout.dart';
import 'package:barcode_scanner_pro/src/generator/rendering/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pwBarcodeFor rejects qr', () {
    expect(
      () => pwBarcodeFor(BarcodeFormat.qr),
      throwsA(isA<BarcodeGenException>()),
    );
    expect(pwBarcodeFor(BarcodeFormat.code128), isNotNull);
  });

  testWidgets('single layout produces a valid PDF (linear)', (tester) async {
    Uint8List? pdf;
    await tester.runAsync(() async {
      pdf = await const PdfRenderer().render(const [
        BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
      ], const BarcodePdfLayout.single());
    });
    expect(pdf!.length, greaterThan(4));
    expect(String.fromCharCodes(pdf!.sublist(0, 4)), '%PDF');
  });

  testWidgets('single layout embeds qr png', (tester) async {
    Uint8List? pdf;
    await tester.runAsync(() async {
      pdf = await const PdfRenderer().render(const [
        BarcodeRequest(data: 'https://x.io', format: BarcodeFormat.qr),
      ], const BarcodePdfLayout.single());
    });
    expect(String.fromCharCodes(pdf!.sublist(0, 4)), '%PDF');
  });
}
