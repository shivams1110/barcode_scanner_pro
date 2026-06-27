import 'dart:ui';

import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> sampleMap() => {
        'value': 'hello',
        'format': BarcodeFormat.qr.bit,
        'boundingBox': {'left': 10, 'top': 20, 'width': 100, 'height': 50},
        'cornerPoints': [
          {'x': 10, 'y': 20},
          {'x': 110, 'y': 20},
          {'x': 110, 'y': 70},
          {'x': 10, 'y': 70},
        ],
        'timestamp': 1700000000000,
        'imageWidth': 1280,
        'imageHeight': 720,
        'rotation': 90,
        'confidence': 0.95,
      };

  test('fromMap parses all fields', () {
    final r = BarcodeResult.fromMap(sampleMap());
    expect(r.value, 'hello');
    expect(r.format, BarcodeFormat.qr);
    expect(r.boundingBox, const Rect.fromLTWH(10, 20, 100, 50));
    expect(r.cornerPoints.length, 4);
    expect(r.cornerPoints.first, const Offset(10, 20));
    expect(r.imageSize, const Size(1280, 720));
    expect(r.rotation, 90);
    expect(r.confidence, 0.95);
  });

  test('handles missing optional fields gracefully', () {
    final map = sampleMap()
      ..remove('cornerPoints')
      ..remove('confidence');
    final r = BarcodeResult.fromMap(map);
    expect(r.cornerPoints, isEmpty);
    expect(r.confidence, isNull);
  });

  test('equality is value + format + timestamp based', () {
    final a = BarcodeResult.fromMap(sampleMap());
    final b = BarcodeResult.fromMap(sampleMap());
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
