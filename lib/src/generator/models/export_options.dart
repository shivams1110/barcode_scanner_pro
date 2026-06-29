import 'package:flutter/foundation.dart';

/// Resolution and spacing for SVG/PDF export. [svgDpi]/[pdfDpi] set the pixel
/// resolution of QR codes embedded as PNG; [cellPadding] is logical-pixel
/// padding around each code in a PDF layout cell.
@immutable
class BarcodeExportOptions {
  const BarcodeExportOptions({
    this.svgDpi = 300,
    this.pdfDpi = 300,
    this.cellPadding = 8,
  });

  final int svgDpi;
  final int pdfDpi;
  final double cellPadding;

  BarcodeExportOptions copyWith({
    int? svgDpi,
    int? pdfDpi,
    double? cellPadding,
  }) {
    return BarcodeExportOptions(
      svgDpi: svgDpi ?? this.svgDpi,
      pdfDpi: pdfDpi ?? this.pdfDpi,
      cellPadding: cellPadding ?? this.cellPadding,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BarcodeExportOptions &&
      other.svgDpi == svgDpi &&
      other.pdfDpi == pdfDpi &&
      other.cellPadding == cellPadding;

  @override
  int get hashCode => Object.hash(svgDpi, pdfDpi, cellPadding);
}
