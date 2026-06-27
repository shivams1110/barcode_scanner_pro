import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'barcode_format.dart';

/// An immutable, decoded barcode produced by the native scanner.
///
/// All geometry is expressed in the **image coordinate space** of the analyzed
/// frame (origin top-left, pixels), together with [imageSize] and [rotation] so
/// that consumers can map points into widget space. See `BarcodeScannerView`
/// and the overlay painters for an example mapping.
class BarcodeResult {
  const BarcodeResult({
    required this.value,
    required this.format,
    required this.boundingBox,
    required this.cornerPoints,
    required this.timestamp,
    required this.imageSize,
    required this.rotation,
    this.rawBytes,
    this.confidence,
  });

  /// Decoded payload as a UTF-8/ASCII string. May be empty for binary codes;
  /// in that case rely on [rawBytes].
  final String value;

  /// Detected symbology.
  final BarcodeFormat format;

  /// Axis-aligned bounding box in image pixel coordinates.
  final Rect boundingBox;

  /// Four corner points (clockwise from top-left) in image pixel coordinates.
  /// May be empty if the native detector did not provide corners.
  final List<Offset> cornerPoints;

  /// Capture time of the frame the code was decoded from.
  final DateTime timestamp;

  /// Raw decoded bytes when available (e.g. binary QR). Null otherwise.
  final Uint8List? rawBytes;

  /// Size of the analyzed image in pixels.
  final Size imageSize;

  /// Clockwise rotation in degrees (0/90/180/270) needed to view the image
  /// upright relative to the device's natural orientation.
  final int rotation;

  /// Detector confidence in `[0, 1]` when reported by the platform; null if the
  /// platform does not expose confidence (e.g. ML Kit).
  final double? confidence;

  /// Builds a result from the cross-platform channel map.
  factory BarcodeResult.fromMap(Map<dynamic, dynamic> map) {
    final corners = <Offset>[];
    final rawCorners = map['cornerPoints'] as List<dynamic>?;
    if (rawCorners != null) {
      for (final p in rawCorners) {
        final m = p as Map<dynamic, dynamic>;
        corners.add(
          Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble()),
        );
      }
    }
    final box = map['boundingBox'] as Map<dynamic, dynamic>;
    return BarcodeResult(
      value: (map['value'] as String?) ?? '',
      format: BarcodeFormat.fromBit(map['format'] as int),
      boundingBox: Rect.fromLTWH(
        (box['left'] as num).toDouble(),
        (box['top'] as num).toDouble(),
        (box['width'] as num).toDouble(),
        (box['height'] as num).toDouble(),
      ),
      cornerPoints: corners,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? 0,
      ),
      rawBytes: map['rawBytes'] as Uint8List?,
      imageSize: Size(
        (map['imageWidth'] as num).toDouble(),
        (map['imageHeight'] as num).toDouble(),
      ),
      rotation: (map['rotation'] as num?)?.toInt() ?? 0,
      confidence: (map['confidence'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() =>
      'BarcodeResult(${format.name}: "$value" @ $boundingBox)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeResult &&
          other.value == value &&
          other.format == format &&
          other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(value, format, timestamp);
}
