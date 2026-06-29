import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---- BarcodeGenerator.text ----

  test('text helper produces QR request with exact data', () {
    final req = BarcodeGenerator.text('hi');
    expect(req.data, 'hi');
    expect(req.format, BarcodeFormat.qr);
  });

  // ---- BarcodeGenerator.calendar ----

  test('calendar helper builds valid VEVENT payload', () {
    final req = BarcodeGenerator.calendar({
      'summary': 'X',
      'start': '20260701T090000Z',
      'end': '20260701T100000Z',
    });
    expect(req.format, BarcodeFormat.qr);
    expect(req.data, startsWith('BEGIN:VEVENT'));
    expect(req.data, contains('SUMMARY:X'));
    expect(req.data, contains('DTSTART:20260701T090000Z'));
    expect(req.data, contains('DTEND:20260701T100000Z'));
  });

  // ---- BarcodeGenerator.phone ----

  test('phone helper prefixes tel: scheme', () {
    final req = BarcodeGenerator.phone('+15551234');
    expect(req.data, 'tel:+15551234');
    expect(req.format, BarcodeFormat.qr);
  });

  // ---- BarcodeGenerator.location ----

  test('location helper prefixes geo: scheme', () {
    final req = BarcodeGenerator.location(1.5, 2.5);
    expect(req.data, 'geo:1.5,2.5');
    expect(req.format, BarcodeFormat.qr);
  });
}
