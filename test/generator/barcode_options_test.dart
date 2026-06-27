import 'package:barcode_scanner_pro/src/generator/models/barcode_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults and pixelSize at 96 dpi', () {
    const o = BarcodeOptions();
    expect(o.size, 200);
    expect(o.dpi, 96);
    expect(o.scale, 1);
    expect(o.pixelSize, 200);
  });

  test('pixelSize scales with dpi and scale', () {
    const o = BarcodeOptions(size: 200, dpi: 300);
    expect(o.pixelSize, closeTo(625, 0.001)); // 200 * 300/96
    const o2 = BarcodeOptions(size: 100, dpi: 1200, scale: 2);
    expect(o2.pixelSize, closeTo(2500, 0.001)); // 100 * 12.5 * 2
  });

  test('copyWith + equality', () {
    const o = BarcodeOptions();
    expect(o.copyWith(dpi: 600).dpi, 600);
    expect(o.copyWith(), o);
  });
}
