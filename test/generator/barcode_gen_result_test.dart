import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_gen_result.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('base64 + memory image wrappers', (tester) async {
    final r = ui.PictureRecorder();
    Canvas(r).drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint());
    final img = await r.endRecording().toImage(2, 2);
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final result = BarcodeGenResult(
      pngBytes: bytes,
      uiImage: img,
      pixelSize: const Size(2, 2),
      format: BarcodeFormat.qr,
      request: const BarcodeRequest(data: 'x', format: BarcodeFormat.qr),
    );

    expect(result.toBase64(), base64Encode(bytes));
    expect(result.toMemoryImage(), isA<MemoryImage>());
    expect(result.toImageProvider(), isA<ImageProvider>());
  });
}
