import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/generator_service.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/models/export_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = BarcodeGenerator();
  const req = BarcodeRequest(data: 'https://example.com', format: BarcodeFormat.qr);

  testWidgets(
      'generateSvg: higher svgDpi produces a larger embedded PNG (longer SVG string)',
      (tester) async {
    String? svgLow;
    String? svgHigh;

    await tester.runAsync(() async {
      svgLow = await gen.generateSvg(
        req,
        options: const BarcodeExportOptions(svgDpi: 96),
      );
      svgHigh = await gen.generateSvg(
        req,
        options: const BarcodeExportOptions(svgDpi: 600),
      );
    });

    expect(svgLow, isNotNull);
    expect(svgHigh, isNotNull);
    expect(svgLow, contains('<svg'));
    expect(svgHigh, contains('<svg'));

    // Higher DPI embeds a larger PNG → longer base64 → longer SVG string.
    expect(
      svgHigh!.length,
      greaterThan(svgLow!.length),
      reason:
          'svgDpi=600 SVG (${svgHigh!.length} chars) should be longer than '
          'svgDpi=96 SVG (${svgLow!.length} chars)',
    );
  });
}
