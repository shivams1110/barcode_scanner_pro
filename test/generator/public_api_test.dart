import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generator public API is exported from package root', () {
    const gen = BarcodeGenerator();
    const req = BarcodeRequest(data: 'x', format: BarcodeFormat.qr);
    const style = BarcodeStyle(moduleShape: ModuleShape.rounded);
    const options = BarcodeOptions(dpi: 300);
    expect(gen, isNotNull);
    expect(req.isQr, isTrue);
    expect(style.moduleShape, ModuleShape.rounded);
    expect(options.dpi, 300);
    // Types resolve from root import:
    expect(ErrorCorrection.high.qrLevel, 2);
    expect(EyeShape.values, contains(EyeShape.leaf));
  });
}
