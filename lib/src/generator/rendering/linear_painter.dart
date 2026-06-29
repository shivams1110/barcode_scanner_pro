import 'package:barcode/barcode.dart' as bc;
import 'package:flutter/painting.dart';

import '../../domain/barcode_format.dart';
import '../../error/barcode_gen_exception.dart';
import '../models/barcode_request.dart';

/// Maps a [BarcodeFormat] to a `barcode` package [bc.Barcode]. QR is handled by
/// `QrPainter`, so requesting it here is a programming error.
bc.Barcode barcodeFor(BarcodeFormat format) {
  switch (format) {
    case BarcodeFormat.code128:
      return bc.Barcode.code128();
    case BarcodeFormat.code39:
      return bc.Barcode.code39();
    case BarcodeFormat.code93:
      return bc.Barcode.code93();
    case BarcodeFormat.ean8:
      return bc.Barcode.ean8();
    case BarcodeFormat.ean13:
      return bc.Barcode.ean13();
    case BarcodeFormat.upcA:
      return bc.Barcode.upcA();
    case BarcodeFormat.upcE:
      return bc.Barcode.upcE();
    case BarcodeFormat.itf:
      return bc.Barcode.itf();
    case BarcodeFormat.itf14:
      return bc.Barcode.itf14();
    case BarcodeFormat.itf16:
      return bc.Barcode.itf16();
    case BarcodeFormat.codabar:
      return bc.Barcode.codabar();
    case BarcodeFormat.gs128:
      return bc.Barcode.gs128();
    case BarcodeFormat.ean5:
      return bc.Barcode.ean5();
    case BarcodeFormat.ean2:
      return bc.Barcode.ean2();
    case BarcodeFormat.isbn:
      return bc.Barcode.isbn();
    case BarcodeFormat.telepen:
      return bc.Barcode.telepen();
    case BarcodeFormat.rm4scc:
      return bc.Barcode.rm4scc();
    case BarcodeFormat.postnet:
      return bc.Barcode.postnet();
    case BarcodeFormat.pdf417:
      return bc.Barcode.pdf417();
    case BarcodeFormat.aztec:
      return bc.Barcode.aztec();
    case BarcodeFormat.dataMatrix:
      return bc.Barcode.dataMatrix();
    case BarcodeFormat.qr:
      throw const BarcodeGenException(
        'QR is rendered by QrPainter, not LinearPainter',
        format: BarcodeFormat.qr,
      );
  }
}

/// Paints linear and non-QR 2D symbologies by walking the `barcode` package's
/// vector element stream onto a [Canvas].
class LinearPainter {
  const LinearPainter();

  void paint(Canvas canvas, Size size, BarcodeRequest request) {
    final symbology = barcodeFor(request.format);
    final style = request.style;
    final fg = Paint()..color = style.foreground;

    // Reserve space for human-readable text when requested.
    final textHeight = style.showText ? style.fontSize * 1.4 : 0.0;
    final barsHeight = size.height - textHeight;

    final List<bc.BarcodeElement> elements;
    try {
      elements = symbology
          .make(
            request.data,
            width: size.width,
            height: barsHeight,
            drawText: false,
          )
          .toList();
    } on bc.BarcodeException catch (e) {
      throw BarcodeGenException(e.message, format: request.format);
    }

    for (final element in elements) {
      if (element is bc.BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width,
            element.height,
          ),
          fg,
        );
      }
    }

    if (style.showText) {
      final tp = TextPainter(
        text: TextSpan(
          text: request.data,
          style: TextStyle(
            color: style.foreground,
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      tp.paint(canvas, Offset((size.width - tp.width) / 2, barsHeight));
    }
  }
}
