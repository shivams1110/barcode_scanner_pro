import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = BarcodeGenerator();

  const linearReq = BarcodeRequest(
    data: '012345678905',
    format: BarcodeFormat.upcA,
  );

  const qrReq = BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
  );

  // ---- SVG output ----

  testWidgets('linear generateSvg contains <svg and no base64 PNG embed', (
    tester,
  ) async {
    String? svg;
    await tester.runAsync(() async {
      svg = await gen.generateSvg(linearReq);
    });
    expect(svg, contains('<svg'));
    expect(svg, isNot(contains('data:image/png')));
  });

  testWidgets('QR generateSvg embeds a base64 PNG image', (tester) async {
    String? svg;
    await tester.runAsync(() async {
      svg = await gen.generateSvg(qrReq);
    });
    expect(svg, contains('data:image/png;base64,'));
  });

  // ---- PDF layouts — all six ----

  testWidgets('generatePdf single() starts with %PDF', (tester) async {
    await tester.runAsync(() async {
      final bytes = await gen.generatePdf(const [linearReq]);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });

  testWidgets('generatePdf grid(columns:2,rows:4) starts with %PDF', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await gen.generatePdf(const [
        linearReq,
      ], layout: const BarcodePdfLayout.grid(columns: 2, rows: 4));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });

  testWidgets('generatePdf label(widthMm:50,heightMm:30) starts with %PDF', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await gen.generatePdf(const [
        linearReq,
      ], layout: BarcodePdfLayout.label(widthMm: 50, heightMm: 30));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });

  testWidgets('generatePdf thermal() starts with %PDF', (tester) async {
    await tester.runAsync(() async {
      final bytes = await gen.generatePdf(const [
        linearReq,
      ], layout: const BarcodePdfLayout.thermal());
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });

  testWidgets('generatePdf a4() starts with %PDF', (tester) async {
    await tester.runAsync(() async {
      final bytes = await gen.generatePdf(const [
        linearReq,
      ], layout: const BarcodePdfLayout.a4());
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });

  testWidgets(
    'generatePdf custom(pageFormat: PdfPageFormat.a5) starts with %PDF',
    (tester) async {
      await tester.runAsync(() async {
        final bytes = await gen.generatePdf(const [
          linearReq,
        ], layout: const BarcodePdfLayout.custom(pageFormat: PdfPageFormat.a5));
        expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
      });
    },
  );

  // ---- Styled QR module/eye shape smoke tests ----
  // BarcodeWidget paints synchronously, so runAsync is not needed.

  final shapeCombos = [
    (ModuleShape.square, EyeShape.square),
    (ModuleShape.rounded, EyeShape.rounded),
    (ModuleShape.circular, EyeShape.circular),
    (ModuleShape.diamond, EyeShape.leaf),
    (ModuleShape.classy, EyeShape.square),
  ];

  for (final combo in shapeCombos) {
    final module = combo.$1;
    final eye = combo.$2;

    testWidgets(
      'BarcodeWidget QR moduleShape=$module eyeShape=$eye throws no exception',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: BarcodeWidget(
                data: 'x',
                format: BarcodeFormat.qr,
                moduleShape: module,
                eyeShape: eye,
                width: 120,
                height: 120,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
