import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/generator_service.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('helpers return QR requests with correct payloads', () {
    final w = BarcodeGenerator.wifi(ssid: 'Net', password: 'pw');
    expect(w.format, BarcodeFormat.qr);
    expect(w.data, r'WIFI:T:WPA;S:Net;P:pw;H:false;;');

    expect(BarcodeGenerator.url('https://x.io').data, 'https://x.io');
    expect(BarcodeGenerator.phone('+15551234').data, 'tel:+15551234');
    expect(
      BarcodeGenerator.email('a@b.com', subject: 'Hi').data,
      'mailto:a@b.com?subject=Hi',
    );
    expect(BarcodeGenerator.location(1.5, 2.5).data, 'geo:1.5,2.5');
    expect(BarcodeGenerator.contact({'name': 'Ada'}).data, contains('FN:Ada'));
    expect(
      BarcodeGenerator.calendar({'summary': 'X'}).data,
      contains('SUMMARY:X'),
    );
    expect(BarcodeGenerator.text('hi').data, 'hi');
    expect(
      BarcodeGenerator.sms('5551234', message: 'yo').data,
      'SMSTO:5551234:yo',
    );
  });

  test('validate dispatches to BarcodeValidator', () {
    const gen = BarcodeGenerator();
    expect(
      gen.validate(
        const BarcodeRequest(
          data: '4006381333931',
          format: BarcodeFormat.ean13,
        ),
      ),
      isTrue,
    );
    expect(
      gen.validate(
        const BarcodeRequest(
          data: '4006381333930',
          format: BarcodeFormat.ean13,
        ),
      ),
      isFalse,
    );
    // QR/2D are always valid for generation:
    expect(
      gen.validate(
        const BarcodeRequest(data: 'anything', format: BarcodeFormat.qr),
      ),
      isTrue,
    );
  });
}
