import 'package:barcode_scanner_pro/src/generator/helpers/qr_payloads.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('simple payloads', () {
    expect(QrPayloads.url('https://x.io'), 'https://x.io');
    expect(QrPayloads.text('hi'), 'hi');
    expect(QrPayloads.phone('+15551234'), 'tel:+15551234');
    expect(QrPayloads.sms('+15551234', message: 'hey'), 'SMSTO:+15551234:hey');
    expect(QrPayloads.location(37.42, -122.08), 'geo:37.42,-122.08');
  });

  test('email query-encodes subject/body and omits null params', () {
    expect(QrPayloads.email('a@b.com'), 'mailto:a@b.com');
    expect(
      QrPayloads.email('a@b.com', subject: 'Hi there', body: 'a&b'),
      'mailto:a@b.com?subject=Hi%20there&body=a%26b',
    );
  });

  test('wifi escapes special chars and emits hidden flag', () {
    expect(
      QrPayloads.wifi(ssid: 'My;Net', password: 'p:a,ss', security: 'WPA'),
      r'WIFI:T:WPA;S:My\;Net;P:p\:a\,ss;H:false;;',
    );
    expect(
      QrPayloads.wifi(ssid: 'Open', security: 'nopass', hidden: true),
      r'WIFI:T:nopass;S:Open;P:;H:true;;',
    );
  });

  test('contact builds vCard from known keys', () {
    final v = QrPayloads.contact({'name': 'Ada Lovelace', 'email': 'ada@x.io'});
    expect(v, startsWith('BEGIN:VCARD'));
    expect(v, contains('VERSION:3.0'));
    expect(v, contains('FN:Ada Lovelace'));
    expect(v, contains('EMAIL:ada@x.io'));
    expect(v, endsWith('END:VCARD'));
  });

  test('calendar builds vEvent from known keys', () {
    final e = QrPayloads.calendar({
      'summary': 'Launch',
      'start': '20260701T090000Z',
      'end': '20260701T100000Z',
    });
    expect(e, startsWith('BEGIN:VEVENT'));
    expect(e, contains('SUMMARY:Launch'));
    expect(e, contains('DTSTART:20260701T090000Z'));
    expect(e, contains('DTEND:20260701T100000Z'));
    expect(e, endsWith('END:VEVENT'));
  });
}
