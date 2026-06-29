import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/rendering/svg_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('linear renders vector svg', (tester) async {
    String? svg;
    await tester.runAsync(() async {
      svg = await const SvgRenderer().render(
        const BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
      );
    });
    expect(svg, contains('<svg'));
    expect(svg, contains('</svg>'));
    // Vector linear must NOT embed a raster image.
    expect(svg, isNot(contains('data:image/png')));
  });

  testWidgets('qr renders an embedded png image svg', (tester) async {
    String? svg;
    await tester.runAsync(() async {
      svg = await const SvgRenderer().render(
        const BarcodeRequest(data: 'https://karnival.com', format: BarcodeFormat.qr),
      );
    });
    expect(svg, contains('<svg'));
    expect(svg, contains('<image'));
    expect(svg, contains('data:image/png;base64,'));
  });
}
