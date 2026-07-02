import 'package:barcode_scanner_pro/src/config/scanner_configuration.dart';
import 'package:barcode_scanner_pro/src/controller.dart';
import 'package:barcode_scanner_pro/src/platform/barcode_scanner_platform.dart';
import 'package:barcode_scanner_pro/src/platform/scanner_event.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlatform extends BarcodeScannerPlatform {
  _FakePlatform() : super();
  int? initReturn;
  @override
  String get viewType => 'fake';
  @override
  Stream<ScannerEvent> events(int viewId) => const Stream.empty();
  @override
  Future<bool> checkPermission() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<int?> initialize(int viewId, ScannerConfiguration config) async =>
      initReturn;
  // Remaining overrides throw UnimplementedError — not exercised here.
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('controller stores textureId returned by initialize', () async {
    final fake = _FakePlatform()..initReturn = 42;
    final c = BarcodeScannerController(platform: fake);
    c.attach(1);
    await c.initialize();
    expect(c.textureId, 42);
  });

  test('null textureId on non-desktop platforms', () async {
    final fake = _FakePlatform()..initReturn = null;
    final c = BarcodeScannerController(platform: fake);
    c.attach(1);
    await c.initialize();
    expect(c.textureId, isNull);
  });
}
