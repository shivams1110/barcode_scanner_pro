// A lightweight micro-benchmark for the generator hot path: rasterizing QR and
// linear barcodes, batching with concurrency, and cache dedup. Run with:
//
//   flutter test test/benchmark/generator_benchmark.dart
//
// Written as a test so it runs in CI without extra tooling, and asserts only
// loose bounds so the suite never flakes on slow CI machines.
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = BarcodeGenerator();

  testWidgets('BENCH single QR generate', (tester) async {
    const request = BarcodeRequest(
      data: 'https://umda.com',
      format: BarcodeFormat.qr,
    );

    final sw = Stopwatch()..start();
    final result = await tester.runAsync(() => gen.generate(request));
    sw.stop();

    debugPrint('BENCH qr.generate: ${sw.elapsedMilliseconds}ms');

    expect(result, isNotNull);
    expect(result!.pngBytes, isNotEmpty);
    // Loose upper bound: anything beyond 30 s indicates a hang, not slowness.
    expect(sw.elapsedMilliseconds, lessThan(30000));
  });

  testWidgets('BENCH single linear (code128) generate', (tester) async {
    const request = BarcodeRequest(
      data: 'ABC-123',
      format: BarcodeFormat.code128,
    );

    final sw = Stopwatch()..start();
    final result = await tester.runAsync(() => gen.generate(request));
    sw.stop();

    debugPrint('BENCH code128.generate: ${sw.elapsedMilliseconds}ms');

    expect(result, isNotNull);
    expect(result!.pngBytes, isNotEmpty);
    expect(sw.elapsedMilliseconds, lessThan(30000));
  });

  testWidgets('BENCH generateBatch 100 code128 items concurrency=8', (
    tester,
  ) async {
    final requests = List.generate(
      100,
      (i) => BarcodeRequest(data: 'ITEM-$i', format: BarcodeFormat.code128),
    );

    final sw = Stopwatch()..start();
    final results = await tester.runAsync(
      () => gen.generateBatch(requests, concurrency: 8),
    );
    sw.stop();

    debugPrint(
      'BENCH batch(100, code128, concurrency=8): ${sw.elapsedMilliseconds}ms',
    );

    expect(results, isNotNull);
    expect(results!.length, 100);

    // Assert INPUT ORDER is preserved.
    for (var i = 0; i < 100; i++) {
      expect(results[i].request.data, 'ITEM-$i');
    }

    expect(sw.elapsedMilliseconds, lessThan(60000));
  });

  testWidgets('BENCH generateBatch 150 requests (100 unique + 50 duplicates)', (
    tester,
  ) async {
    // 100 unique items followed by 50 duplicates of the first 50.
    final unique = List.generate(
      100,
      (i) => BarcodeRequest(data: 'ITEM-$i', format: BarcodeFormat.code128),
    );
    final duplicates = List.generate(
      50,
      (i) => BarcodeRequest(data: 'ITEM-$i', format: BarcodeFormat.code128),
    );
    final requests = [...unique, ...duplicates];

    final sw = Stopwatch()..start();
    final results = await tester.runAsync(
      () => gen.generateBatch(requests, concurrency: 8),
    );
    sw.stop();

    debugPrint(
      'BENCH batch(150 = 100 unique + 50 dup, code128): ${sw.elapsedMilliseconds}ms',
    );

    expect(results, isNotNull);
    // Must return exactly 150 results — one per input request, including dups.
    expect(results!.length, 150);

    expect(sw.elapsedMilliseconds, lessThan(60000));
  });

  test('value-equality on BarcodeRequest (drives shouldRepaint)', () {
    const a = BarcodeRequest(data: 'hello', format: BarcodeFormat.qr);
    const b = BarcodeRequest(data: 'world', format: BarcodeFormat.qr);

    // Same data+format → equal.
    expect(
      const BarcodeRequest(data: 'hello', format: BarcodeFormat.qr),
      equals(a),
    );
    // Different data → not equal.
    expect(a, isNot(equals(b)));
    // Hash codes consistent with equality.
    expect(
      a.hashCode,
      equals(
        const BarcodeRequest(data: 'hello', format: BarcodeFormat.qr).hashCode,
      ),
    );
  });
}
