import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../models/barcode_request.dart';
import 'linear_painter.dart';
import 'qr_painter.dart';

/// Single entry point that paints any [BarcodeRequest] onto a [Canvas],
/// dispatching to [QrPainter] or [LinearPainter] and applying rotation. Shared
/// by both on-screen rendering (BarcodeWidget) and raster export.
class BarcodeRenderer {
  const BarcodeRenderer();

  void paint(Canvas canvas, Size size, BarcodeRequest request) {
    final rotation = request.options.rotationDegrees % 360;
    if (rotation != 0) {
      canvas
        ..save()
        ..translate(size.width / 2, size.height / 2)
        ..rotate(rotation * math.pi / 180)
        ..translate(-size.width / 2, -size.height / 2);
    }

    try {
      if (request.isQr) {
        const QrPainter().paint(canvas, size, request);
      } else {
        const LinearPainter().paint(canvas, size, request);
      }
    } finally {
      if (rotation != 0) canvas.restore();
    }
  }
}
