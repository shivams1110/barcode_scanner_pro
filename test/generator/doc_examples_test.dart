import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = BarcodeGenerator();

  testWidgets('README quick start: generate QR PNG bytes', (tester) async {
    await tester.runAsync(() async {
      final bytes = await gen.generateBytes(
        const BarcodeRequest(
          data: 'https://umda.com',
          format: BarcodeFormat.qr,
        ),
      );
      expect(bytes.length, greaterThan(8));
    });
  });

  testWidgets('generate returns a populated result + output conversions', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final result = await gen.generate(
        const BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
      );
      expect(result.pngBytes.length, greaterThan(8));
      expect(result.toBase64(), isNotEmpty);
      expect(result.toMemoryImage(), isA<MemoryImage>());
      expect(
        (await gen.generateImage(
          const BarcodeRequest(data: 'x', format: BarcodeFormat.qr),
        )).width,
        greaterThan(0),
      );
    });
  });

  test('named QR helper builds a WIFI payload', () {
    final req = BarcodeGenerator.wifi(ssid: 'Net', password: 'pw');
    expect(req.format, BarcodeFormat.qr);
    expect(req.data, startsWith('WIFI:'));
  });

  testWidgets('SVG (vector linear) + PDF export', (tester) async {
    await tester.runAsync(() async {
      final svg = await gen.generateSvg(
        const BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
      );
      expect(svg, contains('<svg'));
      final pdf = await gen.generatePdf(const [
        BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
      ], layout: const BarcodePdfLayout.grid(columns: 2, rows: 4));
      expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF');
    });
  });

  test('validation', () {
    expect(BarcodeValidator.isValidEAN13('4006381333931'), isTrue);
  });

  testWidgets('styled BarcodeWidget renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: BarcodeWidget(
            data: 'https://umda.com',
            format: BarcodeFormat.qr,
            width: 200,
            height: 200,
            moduleShape: ModuleShape.rounded,
            eyeShape: EyeShape.circular,
            errorCorrectionLevel: ErrorCorrection.high,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(BarcodeWidget), findsOneWidget);
  });
}
