import 'package:flutter/widgets.dart';

import '../config/scan_area.dart';
import '../domain/barcode_result.dart';

/// Paints a translucent mask over the whole preview with a rounded-rectangle
/// cut-out for the active [scanArea], plus corner indicators.
class ScannerMaskPainter extends CustomPainter {
  ScannerMaskPainter({
    required this.scanArea,
    required this.maskColor,
    required this.borderColor,
    required this.borderRadius,
    required this.cornerLength,
    required this.cornerWidth,
  });

  final ScanArea scanArea;
  final Color maskColor;
  final Color borderColor;
  final double borderRadius;
  final double cornerLength;
  final double cornerWidth;

  Rect _windowRect(Size size) => Rect.fromLTWH(
    scanArea.left * size.width,
    scanArea.top * size.height,
    scanArea.width * size.width,
    scanArea.height * size.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final window = _windowRect(size);
    final rrect = RRect.fromRectAndRadius(
      window,
      Radius.circular(borderRadius),
    );

    // Dark mask with the window punched out (even-odd fill).
    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = maskColor);

    _paintCorners(canvas, window);
  }

  void _paintCorners(Canvas canvas, Rect r) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;
    final l = cornerLength;

    final path = Path()
      // top-left
      ..moveTo(r.left, r.top + l)
      ..lineTo(r.left, r.top + borderRadius)
      ..arcToPoint(
        Offset(r.left + borderRadius, r.top),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(r.left + l, r.top)
      // top-right
      ..moveTo(r.right - l, r.top)
      ..lineTo(r.right - borderRadius, r.top)
      ..arcToPoint(
        Offset(r.right, r.top + borderRadius),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(r.right, r.top + l)
      // bottom-right
      ..moveTo(r.right, r.bottom - l)
      ..lineTo(r.right, r.bottom - borderRadius)
      ..arcToPoint(
        Offset(r.right - borderRadius, r.bottom),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(r.right - l, r.bottom)
      // bottom-left
      ..moveTo(r.left + l, r.bottom)
      ..lineTo(r.left + borderRadius, r.bottom)
      ..arcToPoint(
        Offset(r.left, r.bottom - borderRadius),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(r.left, r.bottom - l);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScannerMaskPainter old) =>
      old.scanArea != scanArea ||
      old.maskColor != maskColor ||
      old.borderColor != borderColor;
}

/// Animated horizontal laser line sweeping within the scan window.
class LaserPainter extends CustomPainter {
  LaserPainter({
    required this.scanArea,
    required this.progress,
    required this.color,
  }) : super(repaint: progress);

  final ScanArea scanArea;
  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final window = Rect.fromLTWH(
      scanArea.left * size.width,
      scanArea.top * size.height,
      scanArea.width * size.width,
      scanArea.height * size.height,
    );
    final y = window.top + window.height * progress.value;
    final rect = Rect.fromLTRB(
      window.left + 8,
      y - 1.5,
      window.right - 8,
      y + 1.5,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant LaserPainter old) =>
      old.color != color || old.scanArea != scanArea;
}

/// Highlights detected barcodes by drawing their corner polygon (or bounding
/// box) mapped from image space into widget space.
class DetectionPainter extends CustomPainter {
  DetectionPainter({
    required this.barcodes,
    required this.color,
    required this.fillColor,
  });

  final List<BarcodeResult> barcodes;
  final Color color;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (barcodes.isEmpty) return;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = fillColor;

    for (final b in barcodes) {
      // Map from image pixel space to widget space, honoring rotation so the
      // analyzed image's longer axis aligns with the preview.
      final imageSize = _orientedImageSize(b);
      final scaleX = size.width / imageSize.width;
      final scaleY = size.height / imageSize.height;

      Offset map(Offset p) {
        final r = _rotatePoint(p, b.rotation, b.imageSize);
        return Offset(r.dx * scaleX, r.dy * scaleY);
      }

      final path = Path();
      if (b.cornerPoints.length == 4) {
        path.addPolygon(b.cornerPoints.map(map).toList(), true);
      } else {
        final tl = map(b.boundingBox.topLeft);
        final br = map(b.boundingBox.bottomRight);
        path.addRect(Rect.fromPoints(tl, br));
      }
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  Size _orientedImageSize(BarcodeResult b) =>
      b.rotation == 90 || b.rotation == 270
      ? Size(b.imageSize.height, b.imageSize.width)
      : b.imageSize;

  Offset _rotatePoint(Offset p, int rotation, Size img) {
    switch (rotation) {
      case 90:
        return Offset(img.height - p.dy, p.dx);
      case 180:
        return Offset(img.width - p.dx, img.height - p.dy);
      case 270:
        return Offset(p.dy, img.width - p.dx);
      default:
        return p;
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter old) =>
      old.barcodes != barcodes || old.color != color;
}
