import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:qr/qr.dart';

import '../../error/barcode_gen_exception.dart';
import '../models/barcode_logo.dart';
import '../models/barcode_request.dart';
import '../models/barcode_style.dart';
import '../models/enums.dart';

/// Error-correction levels that keep a logo-bearing QR scannable: the spec
/// requires >= quartile (Q or H). Low and medium are rejected.
const Set<ErrorCorrection> _logoMinEcc = {
  ErrorCorrection.quartile,
  ErrorCorrection.high,
};

/// Encodes [request] data into a `qr` package [QrCode] at the requested error
/// correction level. Wraps encoding failures as [BarcodeGenException].
QrCode buildQrCode(BarcodeRequest request) {
  try {
    return QrCode.fromData(
      data: request.data,
      errorCorrectLevel: request.style.errorCorrection.qrLevel,
    );
  } on InputTooLongException catch (e) {
    throw BarcodeGenException(e.message, format: request.format);
  }
}

/// Paints a styled QR code: quiet-zone background, shaped data modules, shaped
/// finder eyes, optional gradient foreground, and an optional center logo.
class QrPainter {
  const QrPainter();

  void paint(ui.Canvas canvas, ui.Size size, BarcodeRequest request) {
    final style = request.style;

    // Logo requires ECC >= quartile (Q or H) to preserve scannability.
    if (style.logo != null && !_logoMinEcc.contains(style.errorCorrection)) {
      throw const BarcodeGenException(
        'A logo requires errorCorrection >= quartile (Q or H) to stay scannable',
      );
    }

    final code = buildQrCode(request);
    final image = QrImage(code);
    final count = code.moduleCount;

    // Background (full canvas including quiet zone).
    if (style.background.a > 0) {
      canvas.drawRect(
        ui.Offset.zero & size,
        ui.Paint()..color = style.background,
      );
    }

    final quiet = style.quietZone;
    final available = size.width - quiet * 2;
    final module = available / count;
    final origin = ui.Offset(quiet, quiet);

    // Build foreground paint: gradient shader or solid color.
    final fg = ui.Paint()..isAntiAlias = true;
    if (style.gradient != null && style.gradient!.type != GradientType.none) {
      fg.shader = style.gradient!.createShader(ui.Offset.zero & size);
    } else {
      fg.color = style.foreground;
    }

    final eyePaint = ui.Paint()
      ..isAntiAlias = true
      ..color = style.effectiveEyeColor;

    // Draw data modules, skipping eye regions (drawn separately).
    for (var x = 0; x < count; x++) {
      for (var y = 0; y < count; y++) {
        if (!image.isDark(y, x)) continue;
        if (_isEyeModule(x, y, count)) continue;
        final rect = ui.Rect.fromLTWH(
          origin.dx + x * module,
          origin.dy + y * module,
          module,
          module,
        );
        _drawModule(canvas, rect, style.moduleShape, fg, style.borderRadius);
      }
    }

    _drawEyes(canvas, origin, module, count, style, eyePaint);

    if (style.logo != null) {
      _drawLogo(canvas, size, style.logo!);
    }
  }

  // ---------------------------------------------------------------------------
  // Eye detection
  // ---------------------------------------------------------------------------

  bool _isEyeModule(int x, int y, int count) {
    const eye = 7;
    final inTL = x < eye && y < eye;
    final inTR = x >= count - eye && y < eye;
    final inBL = x < eye && y >= count - eye;
    return inTL || inTR || inBL;
  }

  // ---------------------------------------------------------------------------
  // Module drawing
  // ---------------------------------------------------------------------------

  void _drawModule(
    ui.Canvas canvas,
    ui.Rect rect,
    ModuleShape shape,
    ui.Paint paint,
    double radius,
  ) {
    switch (shape) {
      case ModuleShape.square:
        canvas.drawRect(rect, paint);
      case ModuleShape.rounded:
        canvas.drawRRect(
          RRect.fromRectXY(rect, rect.width * 0.3, rect.height * 0.3),
          paint,
        );
      case ModuleShape.circular:
        canvas.drawOval(rect, paint);
      case ModuleShape.diamond:
        final p = ui.Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
        canvas.drawPath(p, paint);
      case ModuleShape.classy:
        final r = rect.width * (radius > 0 ? radius : 0.5);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: Radius.circular(r),
            bottomRight: Radius.circular(r),
          ),
          paint,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Eye drawing (shape independent of module shape)
  // ---------------------------------------------------------------------------

  void _drawEyes(
    ui.Canvas canvas,
    ui.Offset origin,
    double module,
    int count,
    BarcodeStyle style,
    ui.Paint paint,
  ) {
    const eye = 7;
    final positions = <ui.Offset>[
      origin,
      ui.Offset(origin.dx + (count - eye) * module, origin.dy),
      ui.Offset(origin.dx, origin.dy + (count - eye) * module),
    ];
    for (final pos in positions) {
      final outer = ui.Rect.fromLTWH(
        pos.dx,
        pos.dy,
        eye * module,
        eye * module,
      );
      final inner = outer.deflate(module);
      final center = inner.deflate(module);
      _drawEyeRing(canvas, outer, inner, style.eyeShape, paint);
      _drawEyeShape(canvas, center, style.eyeShape, paint);
    }
  }

  void _drawEyeRing(
    ui.Canvas canvas,
    ui.Rect outer,
    ui.Rect inner,
    EyeShape shape,
    ui.Paint paint,
  ) {
    final path = ui.Path()..fillType = ui.PathFillType.evenOdd;
    _addEyePath(path, outer, shape);
    _addEyePath(path, inner, shape);
    canvas.drawPath(path, paint);
  }

  void _drawEyeShape(
    ui.Canvas canvas,
    ui.Rect rect,
    EyeShape shape,
    ui.Paint paint,
  ) {
    final path = ui.Path();
    _addEyePath(path, rect, shape);
    canvas.drawPath(path, paint);
  }

  void _addEyePath(ui.Path path, ui.Rect rect, EyeShape shape) {
    switch (shape) {
      case EyeShape.square:
        path.addRect(rect);
      case EyeShape.rounded:
        path.addRRect(
          RRect.fromRectXY(rect, rect.width * 0.25, rect.height * 0.25),
        );
      case EyeShape.circular:
        path.addOval(rect);
      case EyeShape.leaf:
        path.addRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: Radius.circular(rect.width * 0.5),
            bottomRight: Radius.circular(rect.width * 0.5),
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Logo drawing
  // ---------------------------------------------------------------------------

  void _drawLogo(ui.Canvas canvas, ui.Size size, BarcodeLogo logo) {
    final side = size.width * logo.sizeRatio;
    final rect = ui.Rect.fromCenter(
      center: size.center(ui.Offset.zero),
      width: side,
      height: side,
    );
    final plate = rect.inflate(logo.padding);
    canvas.drawRRect(
      RRect.fromRectXY(plate, logo.padding, logo.padding),
      ui.Paint()..color = logo.background,
    );
    paintImage(
      canvas: canvas,
      rect: rect,
      image: logo.image,
      fit: BoxFit.contain,
      filterQuality: ui.FilterQuality.high,
    );
  }
}
