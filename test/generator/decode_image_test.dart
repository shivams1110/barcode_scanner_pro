import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/error/barcode_gen_exception.dart';
import 'package:barcode_scanner_pro/src/generator/generator_service.dart';
import 'package:barcode_scanner_pro/src/platform/barcode_scanner_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_platform.dart';

void main() {
  late FakeBarcodeScannerPlatform fake;
  const gen = BarcodeGenerator();

  setUp(() {
    fake = FakeBarcodeScannerPlatform();
    BarcodeScannerPlatform.instance = fake;
  });

  test('maps native maps to BarcodeDecodeResult and forwards format mask', () async {
    fake.decodeImageResult = [
      {'value': 'HELLO', 'format': BarcodeFormat.qr.bit},
      {'value': '4006381333931', 'format': BarcodeFormat.ean13.bit},
    ];
    final out = await gen.decodeImage(
      Uint8List.fromList([1, 2, 3]),
      formats: {BarcodeFormat.qr, BarcodeFormat.ean13},
    );
    expect(out, hasLength(2));
    expect(out.first.value, 'HELLO');
    expect(out.first.format, BarcodeFormat.qr);
    expect(out[1].format, BarcodeFormat.ean13);
    expect(fake.lastDecodeMask,
        BarcodeFormat.encode({BarcodeFormat.qr, BarcodeFormat.ean13}));
  });

  test('no formats => mask 0 (all)', () async {
    fake.decodeImageResult = const [];
    final out = await gen.decodeImage(Uint8List.fromList([1]));
    expect(out, isEmpty);
    expect(fake.lastDecodeMask, 0);
  });

  test('empty bytes throws BarcodeGenException before the channel', () async {
    expect(() => gen.decodeImage(Uint8List(0)),
        throwsA(isA<BarcodeGenException>()));
  });

  test('PlatformException is wrapped as BarcodeGenException', () async {
    fake.decodeImageError =
        PlatformException(code: 'DECODING_ERROR', message: 'bad image');
    expect(() => gen.decodeImage(Uint8List.fromList([1])),
        throwsA(isA<BarcodeGenException>()));
  });
}
