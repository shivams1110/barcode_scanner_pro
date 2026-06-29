import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/error/barcode_gen_exception.dart';
import 'package:barcode_scanner_pro/src/generator/validators/barcode_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateChecksum (verified references)', () {
    test('EAN-13', () {
      expect(
        BarcodeValidator.calculateChecksum(BarcodeFormat.ean13, '400638133393'),
        1,
      );
    });
    test('EAN-8', () {
      expect(
        BarcodeValidator.calculateChecksum(BarcodeFormat.ean8, '9638507'),
        4,
      );
    });
    test('UPC-A', () {
      expect(
        BarcodeValidator.calculateChecksum(BarcodeFormat.upcA, '03600029145'),
        2,
      );
    });
    test('throws for formats without a numeric check digit', () {
      expect(
        () => BarcodeValidator.calculateChecksum(BarcodeFormat.code128, 'ABC'),
        throwsA(isA<BarcodeGenException>()),
      );
      expect(
        () => BarcodeValidator.calculateChecksum(BarcodeFormat.qr, 'x'),
        throwsA(isA<BarcodeGenException>()),
      );
    });
  });

  group('isValid*', () {
    test('EAN-13 accepts valid, rejects bad check / length / non-digit', () {
      expect(BarcodeValidator.isValidEAN13('4006381333931'), isTrue);
      expect(
        BarcodeValidator.isValidEAN13('4006381333930'),
        isFalse,
      ); // bad check
      expect(
        BarcodeValidator.isValidEAN13('400638133393'),
        isFalse,
      ); // 12 digits
      expect(
        BarcodeValidator.isValidEAN13('40063813339A1'),
        isFalse,
      ); // non-digit
    });
    test('EAN-8 + UPC-A', () {
      expect(BarcodeValidator.isValidEAN8('96385074'), isTrue);
      expect(BarcodeValidator.isValidEAN8('96385070'), isFalse);
      expect(BarcodeValidator.isValidUPC('036000291452'), isTrue);
      expect(BarcodeValidator.isValidUPC('036000291450'), isFalse);
    });
    test('Code128 / Code39 delegate to symbology charset validity', () {
      expect(BarcodeValidator.isValidCode128('ABC-123'), isTrue);
      expect(BarcodeValidator.isValidCode39('HELLO 123'), isTrue);
      // Code39 has a restricted charset; lowercase is invalid:
      expect(BarcodeValidator.isValidCode39('hello'), isFalse);
    });
  });
}
