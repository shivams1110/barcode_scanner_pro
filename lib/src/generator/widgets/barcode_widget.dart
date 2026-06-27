import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/barcode_format.dart';
import '../models/barcode_logo.dart';
import '../models/barcode_options.dart';
import '../models/barcode_request.dart';
import '../models/barcode_style.dart';
import '../models/enums.dart';
import '../rendering/barcode_renderer.dart';

/// Renders a generated barcode/QR code directly in the widget tree. Repaints
/// only when the resolved [BarcodeRequest] changes (value equality).
class BarcodeWidget extends StatelessWidget {
  const BarcodeWidget({
    super.key,
    required this.data,
    required this.format,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.showText = false,
    this.fontSize = 12,
    this.fontWeight = FontWeight.normal,
    this.borderRadius = 0,
    this.logo,
    this.logoSize = 0.2,
    this.gradient,
    this.errorCorrectionLevel = ErrorCorrection.medium,
    this.quietZone = 4,
    this.moduleShape = ModuleShape.square,
    this.eyeShape = EyeShape.square,
    this.animation,
  });

  final String data;
  final BarcodeFormat format;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final Color foregroundColor;
  final Color backgroundColor;
  final bool showText;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final ui.Image? logo;
  final double logoSize;
  final Gradient? gradient;
  final ErrorCorrection errorCorrectionLevel;
  final double quietZone;
  final ModuleShape moduleShape;
  final EyeShape eyeShape;
  final Duration? animation;

  BarcodeRequest _buildRequest() {
    return BarcodeRequest(
      data: data,
      format: format,
      style: BarcodeStyle(
        foreground: foregroundColor,
        background: backgroundColor,
        gradient: _mapGradient(gradient),
        moduleShape: moduleShape,
        eyeShape: eyeShape,
        borderRadius: borderRadius,
        quietZone: quietZone,
        errorCorrection: errorCorrectionLevel,
        logo: logo == null
            ? null
            : BarcodeLogo(image: logo!, sizeRatio: logoSize),
        showText: showText,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      options: const BarcodeOptions(),
    );
  }

  BarcodeGradient? _mapGradient(Gradient? g) {
    if (g == null) return null;
    final type = switch (g) {
      RadialGradient() => GradientType.radial,
      SweepGradient() => GradientType.sweep,
      _ => GradientType.linear,
    };
    return BarcodeGradient(type: type, colors: g.colors, stops: g.stops);
  }

  @override
  Widget build(BuildContext context) {
    final request = _buildRequest();
    final size = Size(
      width ?? 200,
      height ?? (format == BarcodeFormat.qr ? (width ?? 200) : 120),
    );

    Widget paint(double progress) => CustomPaint(
          size: size,
          painter: _BarcodeCustomPainter(request, progress),
        );

    final child = animation == null
        ? paint(1)
        : _AnimatedBarcode(duration: animation!, builder: paint);

    return RepaintBoundary(
      child: Padding(padding: padding, child: child),
    );
  }
}

class _BarcodeCustomPainter extends CustomPainter {
  const _BarcodeCustomPainter(this.request, this.progress);

  static const BarcodeRenderer _renderer = BarcodeRenderer();
  final BarcodeRequest request;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 1) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, progress),
      );
    }
    _renderer.paint(canvas, size, request);
    if (progress < 1) canvas.restore();
  }

  @override
  bool shouldRepaint(_BarcodeCustomPainter old) =>
      old.request != request || old.progress != progress;
}

class _AnimatedBarcode extends StatefulWidget {
  const _AnimatedBarcode({required this.duration, required this.builder});

  final Duration duration;
  final Widget Function(double progress) builder;

  @override
  State<_AnimatedBarcode> createState() => _AnimatedBarcodeState();
}

class _AnimatedBarcodeState extends State<_AnimatedBarcode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => widget.builder(_c.value),
      );
}
