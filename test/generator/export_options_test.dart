import 'package:barcode_scanner_pro/src/generator/models/export_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults and copyWith/equality', () {
    const o = BarcodeExportOptions();
    expect(o.svgDpi, 300);
    expect(o.pdfDpi, 300);
    expect(o.cellPadding, 8);
    expect(o.copyWith(pdfDpi: 600).pdfDpi, 600);
    expect(o.copyWith(), o);
    expect(const BarcodeExportOptions(svgDpi: 300), o);
  });
}
