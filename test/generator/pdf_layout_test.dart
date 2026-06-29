import 'package:barcode_scanner_pro/src/generator/models/pdf_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

void main() {
  test('named constructors set type + grid dims', () {
    expect(const BarcodePdfLayout.single().type, PdfLayoutType.single);
    final g = const BarcodePdfLayout.grid(columns: 2, rows: 5);
    expect(g.type, PdfLayoutType.grid);
    expect(g.columns, 2);
    expect(g.rows, 5);
    expect(const BarcodePdfLayout.a4().pageFormat, PdfPageFormat.a4);
    expect(const BarcodePdfLayout.thermal().type, PdfLayoutType.thermal);
  });

  test('label uses physical mm dimensions', () {
    final l = BarcodePdfLayout.label(widthMm: 50, heightMm: 30);
    expect(l.type, PdfLayoutType.label);
    expect(l.pageFormat.width, closeTo(50 * PdfPageFormat.mm, 0.001));
    expect(l.pageFormat.height, closeTo(30 * PdfPageFormat.mm, 0.001));
  });

  test('value equality', () {
    expect(const BarcodePdfLayout.grid(columns: 3, rows: 4),
        const BarcodePdfLayout.grid(columns: 3, rows: 4));
  });
}
