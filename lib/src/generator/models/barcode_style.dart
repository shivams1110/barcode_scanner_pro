import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'barcode_logo.dart';
import 'enums.dart';

/// A foreground gradient applied across the barcode bounds.
@immutable
class BarcodeGradient {
  const BarcodeGradient({required this.type, required this.colors, this.stops});

  final GradientType type;
  final List<Color> colors;
  final List<double>? stops;

  /// Builds the [ui.Shader] for [bounds]. Returns a linear shader for
  /// [GradientType.none] as a safe fallback (callers gate on type first).
  ui.Shader createShader(Rect bounds) {
    switch (type) {
      case GradientType.radial:
        return RadialGradient(
          colors: colors,
          stops: stops,
        ).createShader(bounds);
      case GradientType.sweep:
        return SweepGradient(colors: colors, stops: stops).createShader(bounds);
      case GradientType.linear:
      case GradientType.none:
        return LinearGradient(
          colors: colors,
          stops: stops,
        ).createShader(bounds);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BarcodeGradient &&
      other.type == type &&
      _listEq(other.colors, colors) &&
      _listEq(other.stops, stops);

  @override
  int get hashCode => Object.hash(
    type,
    Object.hashAll(colors),
    stops == null ? null : Object.hashAll(stops!),
  );

  static bool _listEq<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Visual styling for a generated barcode. QR-only fields ([moduleShape],
/// [eyeShape], [eyeColor], [logo], [errorCorrection]) are ignored by linear
/// symbologies.
@immutable
class BarcodeStyle {
  const BarcodeStyle({
    this.foreground = const Color(0xFF000000),
    this.background = const Color(0xFFFFFFFF),
    this.gradient,
    this.moduleShape = ModuleShape.square,
    this.eyeShape = EyeShape.square,
    this.eyeColor,
    this.borderRadius = 0,
    this.quietZone = 4,
    this.errorCorrection = ErrorCorrection.medium,
    this.logo,
    this.showText = false,
    this.fontSize = 12,
    this.fontWeight = FontWeight.normal,
  });

  final Color foreground;
  final Color background;
  final BarcodeGradient? gradient;
  final ModuleShape moduleShape;
  final EyeShape eyeShape;
  final Color? eyeColor;
  final double borderRadius;
  final double quietZone;
  final ErrorCorrection errorCorrection;
  final BarcodeLogo? logo;
  final bool showText;
  final double fontSize;
  final FontWeight fontWeight;

  /// Eye color, defaulting to [foreground] when unset.
  Color get effectiveEyeColor => eyeColor ?? foreground;

  BarcodeStyle copyWith({
    Color? foreground,
    Color? background,
    BarcodeGradient? gradient,
    ModuleShape? moduleShape,
    EyeShape? eyeShape,
    Color? eyeColor,
    double? borderRadius,
    double? quietZone,
    ErrorCorrection? errorCorrection,
    BarcodeLogo? logo,
    bool? showText,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return BarcodeStyle(
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      gradient: gradient ?? this.gradient,
      moduleShape: moduleShape ?? this.moduleShape,
      eyeShape: eyeShape ?? this.eyeShape,
      eyeColor: eyeColor ?? this.eyeColor,
      borderRadius: borderRadius ?? this.borderRadius,
      quietZone: quietZone ?? this.quietZone,
      errorCorrection: errorCorrection ?? this.errorCorrection,
      logo: logo ?? this.logo,
      showText: showText ?? this.showText,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BarcodeStyle &&
      other.foreground == foreground &&
      other.background == background &&
      other.gradient == gradient &&
      other.moduleShape == moduleShape &&
      other.eyeShape == eyeShape &&
      other.eyeColor == eyeColor &&
      other.borderRadius == borderRadius &&
      other.quietZone == quietZone &&
      other.errorCorrection == errorCorrection &&
      other.logo == logo &&
      other.showText == showText &&
      other.fontSize == fontSize &&
      other.fontWeight == fontWeight;

  @override
  int get hashCode => Object.hashAll([
    foreground,
    background,
    gradient,
    moduleShape,
    eyeShape,
    eyeColor,
    borderRadius,
    quietZone,
    errorCorrection,
    logo,
    showText,
    fontSize,
    fontWeight,
  ]);
}
