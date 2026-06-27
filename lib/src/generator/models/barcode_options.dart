import 'package:flutter/foundation.dart';

/// Geometry and export resolution for a generated barcode.
///
/// [size] is the logical edge length (square for QR; width for linear codes).
/// [pixelSize] is the rasterized edge in device pixels, scaled by [dpi] (base
/// 96) and [scale]. Use dpi 300/600/1200 for print.
@immutable
class BarcodeOptions {
  const BarcodeOptions({
    this.size = 200,
    this.scale = 1,
    this.rotationDegrees = 0,
    this.dpi = 96,
    this.transparentBackground = false,
  });

  final double size;
  final double scale;
  final double rotationDegrees;
  final int dpi;
  final bool transparentBackground;

  /// Rasterized edge length in device pixels.
  double get pixelSize => size * (dpi / 96) * scale;

  BarcodeOptions copyWith({
    double? size,
    double? scale,
    double? rotationDegrees,
    int? dpi,
    bool? transparentBackground,
  }) {
    return BarcodeOptions(
      size: size ?? this.size,
      scale: scale ?? this.scale,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      dpi: dpi ?? this.dpi,
      transparentBackground:
          transparentBackground ?? this.transparentBackground,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BarcodeOptions &&
      other.size == size &&
      other.scale == scale &&
      other.rotationDegrees == rotationDegrees &&
      other.dpi == dpi &&
      other.transparentBackground == transparentBackground;

  @override
  int get hashCode =>
      Object.hash(size, scale, rotationDegrees, dpi, transparentBackground);
}
