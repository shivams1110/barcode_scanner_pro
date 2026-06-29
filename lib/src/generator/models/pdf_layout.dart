import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';

/// Page-layout strategy for multi-barcode PDF export.
enum PdfLayoutType { single, grid, label, thermal, a4, custom }

/// Default 58 mm thermal roll page format (pre-computed const).
const _kThermal58 = PdfPageFormat(
  58 * PdfPageFormat.mm,
  58 * PdfPageFormat.mm,
  marginAll: 2 * PdfPageFormat.mm,
);

/// Describes how generated codes are arranged across PDF pages.
///
/// Named constructors cover common use-cases:
/// - [single] — one code centred on an A4 page.
/// - [grid]   — columns×rows grid flowed across A4 pages.
/// - [label]  — physical label stock of exact mm dimensions.
/// - [thermal]— narrow roll for thermal printers (variable width).
/// - [a4]     — grid tuned for A4 label sheets (3×8 default).
/// - [custom] — caller-supplied [PdfPageFormat] and grid.
///
/// [PdfPageFormat] is re-exported from `package:pdf` for callers.
///
/// **pdf 3.11 API notes:**
/// - `PdfPageFormat.a4` is a const — used as default for single/grid/a4.
/// - `PdfPageFormat.mm` is a const double (= 72/25.4 pts/mm).
/// - `PdfPageFormat(w, h, {marginAll})` accepts `marginAll` as an optional
///   named param that applies uniformly to all four margins.
/// - `label` and `thermal` constructors multiply mm doubles at runtime and
///   therefore cannot be `const`.
@immutable
class BarcodePdfLayout {
  const BarcodePdfLayout._({
    required this.type,
    required this.columns,
    required this.rows,
    required this.pageFormat,
    this.cellPadding = 8,
  });

  /// One code centred per page (A4).
  const BarcodePdfLayout.single()
    : this._(
        type: PdfLayoutType.single,
        columns: 1,
        rows: 1,
        pageFormat: PdfPageFormat.a4,
      );

  /// [columns]×[rows] codes flowed across A4 pages.
  const BarcodePdfLayout.grid({int columns = 3, int rows = 4})
    : this._(
        type: PdfLayoutType.grid,
        columns: columns,
        rows: rows,
        pageFormat: PdfPageFormat.a4,
      );

  /// One code per fixed physical label of [widthMm]×[heightMm] millimetres.
  ///
  /// Not const — mm arithmetic is computed at runtime.
  BarcodePdfLayout.label({required double widthMm, required double heightMm})
    : this._(
        type: PdfLayoutType.label,
        columns: 1,
        rows: 1,
        pageFormat: PdfPageFormat(
          widthMm * PdfPageFormat.mm,
          heightMm * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
      );

  /// Continuous narrow roll for thermal printers (default 58 mm wide).
  ///
  /// This zero-argument form is `const`. Pass a custom [widthMm] to override
  /// the page format (use the [custom] constructor for non-standard widths).
  const BarcodePdfLayout.thermal()
    : this._(
        type: PdfLayoutType.thermal,
        columns: 1,
        rows: 1,
        pageFormat: _kThermal58,
      );

  /// Thermal roll with a custom [widthMm] (not const — uses runtime mm math).
  BarcodePdfLayout.thermalWide({required double widthMm})
    : this._(
        type: PdfLayoutType.thermal,
        columns: 1,
        rows: 1,
        pageFormat: PdfPageFormat(
          widthMm * PdfPageFormat.mm,
          widthMm * PdfPageFormat.mm,
          marginAll: 2 * PdfPageFormat.mm,
        ),
      );

  /// Grid tuned for A4 label sheets (3 columns × 8 rows by default).
  const BarcodePdfLayout.a4({int columns = 3, int rows = 8})
    : this._(
        type: PdfLayoutType.a4,
        columns: columns,
        rows: rows,
        pageFormat: PdfPageFormat.a4,
      );

  /// Caller-supplied page format and grid.
  const BarcodePdfLayout.custom({
    required PdfPageFormat pageFormat,
    int columns = 1,
    int rows = 1,
  }) : this._(
         type: PdfLayoutType.custom,
         columns: columns,
         rows: rows,
         pageFormat: pageFormat,
       );

  final PdfLayoutType type;
  final int columns;
  final int rows;
  final PdfPageFormat pageFormat;

  /// Padding (in points) around each barcode cell.
  final double cellPadding;

  /// Codes per page for grid-style layouts; always >= 1.
  int get perPage => (columns * rows).clamp(1, 1 << 30);

  @override
  bool operator ==(Object other) =>
      other is BarcodePdfLayout &&
      other.type == type &&
      other.columns == columns &&
      other.rows == rows &&
      other.pageFormat == pageFormat &&
      other.cellPadding == cellPadding;

  @override
  int get hashCode => Object.hash(type, columns, rows, pageFormat, cellPadding);
}
