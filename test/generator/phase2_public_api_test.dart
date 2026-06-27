import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phase 2 public types resolve from package root', () {
    const layout = BarcodePdfLayout.grid(columns: 2, rows: 2);
    expect(layout.type, PdfLayoutType.grid);
    const opts = BarcodeExportOptions(pdfDpi: 600);
    expect(opts.pdfDpi, 600);
    // PdfPageFormat re-exported for custom layouts:
    final custom = BarcodePdfLayout.custom(pageFormat: PdfPageFormat.a5);
    expect(custom.type, PdfLayoutType.custom);
  });
}
