import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/batch/batch_generator.dart';
import 'package:barcode_scanner_pro/src/generator/batch/render_cache.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_gen_result.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns results in input order; cache collapses duplicates',
      (tester) async {
    final r = ui.PictureRecorder();
    Canvas(r).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
    final img = await r.endRecording().toImage(1, 1);

    var renderCount = 0;
    Future<BarcodeGenResult> fakeGen(BarcodeRequest req) async {
      renderCount++;
      return BarcodeGenResult(
        pngBytes: Uint8List.fromList([req.data.length]),
        uiImage: img,
        pixelSize: const Size(1, 1),
        format: req.format,
        request: req,
      );
    }

    final reqs = [
      const BarcodeRequest(data: 'a', format: BarcodeFormat.qr),
      const BarcodeRequest(data: 'b', format: BarcodeFormat.qr),
      const BarcodeRequest(data: 'a', format: BarcodeFormat.qr), // dup
      const BarcodeRequest(data: 'c', format: BarcodeFormat.qr),
    ];

    final out = await const BatchGenerator()
        .run(reqs, fakeGen, concurrency: 2, cache: RenderCache());

    expect(out.length, 4);
    expect(out.map((r) => r.request.data).toList(), ['a', 'b', 'a', 'c']);
    expect(renderCount, 3); // duplicate 'a' served from cache
  });
}
