import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/batch/render_cache.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_gen_result.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BarcodeGenResult _result(BarcodeRequest req, ui.Image img) => BarcodeGenResult(
      pngBytes: Uint8List.fromList([1]),
      uiImage: img,
      pixelSize: const Size(1, 1),
      format: req.format,
      request: req,
    );

void main() {
  testWidgets('hit by value-equal key; LRU eviction', (tester) async {
    final r = ui.PictureRecorder();
    Canvas(r).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
    final img = await r.endRecording().toImage(1, 1);

    final cache = RenderCache(capacity: 2);
    const a = BarcodeRequest(data: 'a', format: BarcodeFormat.qr);
    const b = BarcodeRequest(data: 'b', format: BarcodeFormat.qr);
    const c = BarcodeRequest(data: 'c', format: BarcodeFormat.qr);

    cache.put(a, _result(a, img));
    cache.put(b, _result(b, img));
    // value-equal lookup hits:
    expect(cache.get(const BarcodeRequest(data: 'a', format: BarcodeFormat.qr)),
        isNotNull);
    // touching 'a' makes 'b' the LRU; inserting 'c' evicts 'b':
    cache.put(c, _result(c, img));
    expect(cache.get(b), isNull);
    expect(cache.get(a), isNotNull);
    expect(cache.get(c), isNotNull);
    expect(cache.length, 2);
  });
}
