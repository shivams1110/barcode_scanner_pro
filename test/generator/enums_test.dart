import 'package:barcode_scanner_pro/src/generator/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ErrorCorrection maps to qr package level ints', () {
    expect(ErrorCorrection.low.qrLevel, 1); // QrErrorCorrectLevel.L
    expect(ErrorCorrection.medium.qrLevel, 0); // M
    expect(ErrorCorrection.quartile.qrLevel, 3); // Q
    expect(ErrorCorrection.high.qrLevel, 2); // H
  });

  test('all enums expose every variant', () {
    expect(ModuleShape.values.length, 5);
    expect(EyeShape.values.length, 4);
    expect(ExportFormat.values.length, 3);
    expect(GradientType.values.length, 4);
  });
}
