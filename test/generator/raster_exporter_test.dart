import 'dart:ui' as ui;

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_options.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:barcode_scanner_pro/src/generator/rendering/raster_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rasterizes a PNG at the requested dpi', (tester) async {
    const exporter = RasterExporter();
    final out = await tester.runAsync(
      () => exporter.rasterize(
        const BarcodeRequest(
          data: 'hello',
          format: BarcodeFormat.qr,
          options: BarcodeOptions(size: 100, dpi: 300),
        ),
      ),
    );
    expect(out!.pixelSize.width, closeTo(312.5, 0.001)); // 100*300/96
    expect(out.image.width, 312); // truncated to int pixels
    expect(out.png.length, greaterThan(8));
    // PNG magic number
    expect(out.png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('transparentBackground yields a transparent corner pixel', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const exporter = RasterExporter();
      final out = await exporter.rasterize(
        const BarcodeRequest(
          data: 'hello',
          format: BarcodeFormat.qr,
          options: BarcodeOptions(size: 64, transparentBackground: true),
        ),
      );
      final data = await out.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      // Byte index 3 = alpha of the top-left (quiet-zone) pixel.
      expect(data!.getUint8(3), 0);
    });
  });

  testWidgets('opaque background yields a fully opaque corner pixel', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const exporter = RasterExporter();
      final out = await exporter.rasterize(
        const BarcodeRequest(
          data: 'hello',
          format: BarcodeFormat.qr,
          options: BarcodeOptions(size: 64),
        ),
      );
      final data = await out.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(data!.getUint8(3), 255);
    });
  });
}
