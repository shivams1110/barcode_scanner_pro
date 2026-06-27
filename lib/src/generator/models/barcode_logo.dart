import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A center logo overlaid on a QR code. [sizeRatio] is the fraction of the QR
/// width the logo occupies (0–1). [background] fills a rounded plate behind the
/// logo so it remains legible; [padding] is logical pixels around the image.
@immutable
class BarcodeLogo {
  const BarcodeLogo({
    required this.image,
    this.sizeRatio = 0.2,
    this.padding = 4,
    this.background = const Color(0xFFFFFFFF),
  });

  final ui.Image image;
  final double sizeRatio;
  final double padding;
  final Color background;

  @override
  bool operator ==(Object other) =>
      other is BarcodeLogo &&
      other.image == image &&
      other.sizeRatio == sizeRatio &&
      other.padding == padding &&
      other.background == background;

  @override
  int get hashCode => Object.hash(image, sizeRatio, padding, background);
}
