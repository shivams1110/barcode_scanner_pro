import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../domain/barcode_format.dart';
import '../../error/barcode_gen_exception.dart';
import '../models/barcode_request.dart';
import '../models/export_options.dart';
import '../models/pdf_layout.dart';
import 'raster_exporter.dart';

/// Maps a [BarcodeFormat] to a `pdf` package [pw.Barcode]. QR is rendered as an
/// embedded PNG, so requesting it here is a programming error.
///
/// API note (pdf 3.11 / barcode 2.2.9):
/// - `pw.Barcode` re-exports the `barcode` package's `Barcode` class.
/// - Factory names match the `barcode` package directly: `.code128()`, `.code39()`,
///   `.code93()`, `.ean8()`, `.ean13()`, `.upcA()`, `.upcE()`, `.itf()`,
///   `.codabar()`, `.pdf417()`, `.aztec()`, `.dataMatrix()`.
pw.Barcode pwBarcodeFor(BarcodeFormat format) {
  switch (format) {
    case BarcodeFormat.code128:
      return pw.Barcode.code128();
    case BarcodeFormat.code39:
      return pw.Barcode.code39();
    case BarcodeFormat.code93:
      return pw.Barcode.code93();
    case BarcodeFormat.ean8:
      return pw.Barcode.ean8();
    case BarcodeFormat.ean13:
      return pw.Barcode.ean13();
    case BarcodeFormat.upcA:
      return pw.Barcode.upcA();
    case BarcodeFormat.upcE:
      return pw.Barcode.upcE();
    case BarcodeFormat.itf:
      return pw.Barcode.itf();
    case BarcodeFormat.codabar:
      return pw.Barcode.codabar();
    case BarcodeFormat.pdf417:
      return pw.Barcode.pdf417();
    case BarcodeFormat.aztec:
      return pw.Barcode.aztec();
    case BarcodeFormat.dataMatrix:
      return pw.Barcode.dataMatrix();
    case BarcodeFormat.qr:
      throw const BarcodeGenException(
        'QR is embedded as PNG in PDF, not drawn via pw.Barcode',
        format: BarcodeFormat.qr,
      );
  }
}

/// Builds printable PDFs from generated barcodes. Linear/2D codes are native
/// vector (`pw.BarcodeWidget`); QR codes embed the high-DPI PNG raster.
class PdfRenderer {
  const PdfRenderer();

  static const RasterExporter _exporter = RasterExporter();

  Future<Uint8List> render(
    List<BarcodeRequest> requests,
    BarcodePdfLayout layout, {
    BarcodeExportOptions options = const BarcodeExportOptions(),
  }) async {
    if (requests.isEmpty) {
      throw const BarcodeGenException(
          'PDF export requires at least one request');
    }
    final doc = pw.Document();

    // Pre-rasterize QR images (async) before building sync pw widgets.
    final widgets = <pw.Widget>[];
    for (final req in requests) {
      widgets.add(await _codeWidget(req, options));
    }

    switch (layout.type) {
      case PdfLayoutType.single:
      case PdfLayoutType.label:
      case PdfLayoutType.thermal:
        for (final w in widgets) {
          doc.addPage(pw.Page(
            pageFormat: layout.pageFormat,
            build: (_) => pw.Center(child: w),
          ));
        }
      case PdfLayoutType.grid:
      case PdfLayoutType.a4:
      case PdfLayoutType.custom:
        _addGridPages(doc, widgets, layout); // implemented in Task 7
    }
    return doc.save();
  }

  Future<pw.Widget> _codeWidget(
      BarcodeRequest req, BarcodeExportOptions options) async {
    if (req.format == BarcodeFormat.qr) {
      final dpiReq =
          req.copyWith(options: req.options.copyWith(dpi: options.pdfDpi));
      final out = await _exporter.rasterize(dpiReq);
      // pw.Image first positional arg is ImageProvider (pw.MemoryImage).
      // width/height are optional named params on pw.Image.
      return pw.Image(pw.MemoryImage(out.png),
          width: req.options.size, height: req.options.size);
    }
    // pw.BarcodeWidget: data (named String), barcode, width, height, drawText.
    return pw.BarcodeWidget(
      barcode: pwBarcodeFor(req.format),
      data: req.data,
      width: req.options.size,
      height: req.options.size / 2.5,
      drawText: req.style.showText,
    );
  }

  // Task 7 fills this in. Stub keeps Task 6 compiling/testable for single.
  void _addGridPages(
      pw.Document doc, List<pw.Widget> widgets, BarcodePdfLayout layout) {
    throw const BarcodeGenException('grid layout arrives in the next step');
  }
}
