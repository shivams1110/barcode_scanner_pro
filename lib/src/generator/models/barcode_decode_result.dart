import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../../domain/barcode_format.dart';

/// A single barcode decoded from a static image by [BarcodeGenerator.decodeImage]
/// (Phase 3b). Lightweight by design — unlike the scanner's `BarcodeResult`, it
/// carries no frame geometry (imageSize/rotation/timestamp).
@immutable
class BarcodeDecodeResult {
  const BarcodeDecodeResult({
    required this.value,
    required this.format,
    this.rawBytes,
    this.cornerPoints,
  });

  final String value;
  final BarcodeFormat format;
  final Uint8List? rawBytes;
  final List<Offset>? cornerPoints;

  /// Builds a result from the native decode channel map (Phase 3b).
  factory BarcodeDecodeResult.fromMap(Map<dynamic, dynamic> map) {
    List<Offset>? corners;
    final raw = map['cornerPoints'] as List<dynamic>?;
    if (raw != null) {
      corners = [
        for (final p in raw)
          Offset(
            ((p as Map)['x'] as num).toDouble(),
            (p['y'] as num).toDouble(),
          ),
      ];
    }
    return BarcodeDecodeResult(
      value: (map['value'] as String?) ?? '',
      format: BarcodeFormat.fromBit(map['format'] as int),
      rawBytes: map['rawBytes'] as Uint8List?,
      cornerPoints: corners,
    );
  }

  @override
  String toString() => 'BarcodeDecodeResult(${format.name}: "$value")';

  @override
  bool operator ==(Object other) =>
      other is BarcodeDecodeResult &&
      other.value == value &&
      other.format == format &&
      _bytesEq(other.rawBytes, rawBytes) &&
      _offsetsEq(other.cornerPoints, cornerPoints);

  @override
  int get hashCode => Object.hash(
        value,
        format,
        rawBytes == null ? null : Object.hashAll(rawBytes!),
        cornerPoints == null ? null : Object.hashAll(cornerPoints!),
      );

  static bool _bytesEq(Uint8List? a, Uint8List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _offsetsEq(List<Offset>? a, List<Offset>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
