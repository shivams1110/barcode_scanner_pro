import 'dart:ui' as ui;
import 'package:barcode_scanner_pro/src/generator/models/barcode_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _img() {
  final r = ui.PictureRecorder();
  Canvas(r).drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint());
  return r.endRecording().toImage(4, 4);
}

void main() {
  testWidgets('defaults and value equality', (tester) async {
    final img = await _img();
    final l1 = BarcodeLogo(image: img);
    final l2 = BarcodeLogo(image: img);
    expect(l1.sizeRatio, 0.2);
    expect(l1.padding, 4);
    expect(l1.background, const Color(0xFFFFFFFF));
    expect(l1, l2);
    expect(l1.hashCode, l2.hashCode);
  });
}
