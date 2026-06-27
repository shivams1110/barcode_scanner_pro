import 'dart:typed_data';

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/generator_service.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_gen_result.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = BarcodeGenerator();
  const req = BarcodeRequest(data: 'hello', format: BarcodeFormat.qr);

  testWidgets('generate returns a populated result', (tester) async {
    final result = await tester.runAsync(() => gen.generate(req));
    expect(result, isA<BarcodeGenResult>());
    expect(result!.pngBytes.length, greaterThan(8));
    expect(result.format, BarcodeFormat.qr);
  });

  testWidgets('generateBytes + generateImage + toBase64', (tester) async {
    final bytes = await tester.runAsync(() => gen.generateBytes(req));
    expect(bytes!.length, greaterThan(8));

    final image = await tester.runAsync(() => gen.generateImage(req));
    expect(image!.width, greaterThan(0));

    final b64 = await tester.runAsync(() => gen.toBase64(req));
    expect(b64!.isNotEmpty, isTrue);
  });

  test('later-phase methods are stubbed', () {
    expect(() => gen.generateBatch([req]), throwsA(isA<UnimplementedError>()));
    expect(() => gen.decodeImage(Uint8List(0)),
        throwsA(isA<UnimplementedError>()));
    expect(() => gen.validate(req), throwsA(isA<UnimplementedError>()));
    expect(() => BarcodeGenerator.url('https://x.io'),
        throwsA(isA<UnimplementedError>()));
  });
}
