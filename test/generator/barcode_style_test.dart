import 'package:barcode_scanner_pro/src/generator/models/barcode_style.dart';
import 'package:barcode_scanner_pro/src/generator/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults', () {
    const s = BarcodeStyle();
    expect(s.foreground, const Color(0xFF000000));
    expect(s.background, const Color(0xFFFFFFFF));
    expect(s.moduleShape, ModuleShape.square);
    expect(s.eyeShape, EyeShape.square);
    expect(s.errorCorrection, ErrorCorrection.medium);
    expect(s.quietZone, 4);
    expect(s.effectiveEyeColor, const Color(0xFF000000));
  });

  test('effectiveEyeColor falls back to foreground', () {
    const s = BarcodeStyle(foreground: Color(0xFF112233));
    expect(s.effectiveEyeColor, const Color(0xFF112233));
    const s2 = BarcodeStyle(eyeColor: Color(0xFFAABBCC));
    expect(s2.effectiveEyeColor, const Color(0xFFAABBCC));
  });

  test('copyWith overrides only given fields and preserves equality', () {
    const s = BarcodeStyle();
    final s2 = s.copyWith(quietZone: 8);
    expect(s2.quietZone, 8);
    expect(s2.foreground, s.foreground);
    expect(s.copyWith(), s);
  });

  test('BarcodeGradient value equality', () {
    const g1 = BarcodeGradient(
      type: GradientType.linear,
      colors: [Color(0xFF000000), Color(0xFFFF0000)],
    );
    const g2 = BarcodeGradient(
      type: GradientType.linear,
      colors: [Color(0xFF000000), Color(0xFFFF0000)],
    );
    expect(g1, g2);
  });
}
