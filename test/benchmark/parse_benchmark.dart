// A lightweight micro-benchmark for the hot Dart path: decoding event maps
// arriving from the native event channel. Run with:
//
//   flutter test test/benchmark/parse_benchmark.dart
//
// It is written as a test so it runs in CI without extra tooling, and asserts a
// (very loose) throughput floor to catch gross regressions.
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _event() => {
      'type': 'barcodeDetected',
      'barcodes': [
        {
          'value': 'https://example.com/some/path?q=benchmark',
          'format': BarcodeFormat.qr.bit,
          'boundingBox': {'left': 12, 'top': 34, 'width': 200, 'height': 200},
          'cornerPoints': [
            {'x': 12, 'y': 34},
            {'x': 212, 'y': 34},
            {'x': 212, 'y': 234},
            {'x': 12, 'y': 234},
          ],
          'timestamp': 1700000000000,
          'imageWidth': 1280,
          'imageHeight': 720,
          'rotation': 90,
          'confidence': 0.9,
        }
      ],
    };

void main() {
  test('event parsing throughput', () {
    const iterations = 50000;
    final sample = _event();

    final sw = Stopwatch()..start();
    var sink = 0;
    for (var i = 0; i < iterations; i++) {
      final e = ScannerEvent.fromMap(sample);
      if (e is BarcodesEvent) sink += e.barcodes.length;
    }
    sw.stop();

    final perSec = iterations / (sw.elapsedMicroseconds / 1e6);
    // ignore: avoid_print
    print('parsed $sink barcodes — ${perSec.toStringAsFixed(0)} events/sec');

    // Loose floor: anything below ~10k/sec indicates a serious regression.
    expect(perSec, greaterThan(10000));
  });
}
