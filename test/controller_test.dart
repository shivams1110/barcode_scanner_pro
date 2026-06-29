import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBarcodeScannerPlatform fake;
  late BarcodeScannerController controller;

  setUp(() {
    fake = FakeBarcodeScannerPlatform();
    BarcodeScannerPlatform.instance = fake;
    controller = BarcodeScannerController(platform: fake)..attach(1);
  });

  tearDown(() => controller.dispose());

  test('initialize transitions to ready and flips initialized', () async {
    expect(controller.state.value, ScannerState.uninitialized);
    await controller.initialize();
    expect(controller.initialized.value, isTrue);
    expect(controller.state.value, ScannerState.ready);
    expect(fake.calls, contains('initialize'));
  });

  test('control methods are forwarded to the platform', () async {
    await controller.start();
    await controller.setZoom(0.5);
    await controller.setFocus(const Offset(0.2, 0.8));
    await controller.captureFrame();
    expect(fake.calls, containsAll(['start', 'setZoom:0.5', 'captureFrame']));
  });

  test('setZoom clamps to [0,1] and updates the notifier', () async {
    await controller.setZoom(5);
    expect(controller.zoom.value, 1.0);
    await controller.setZoom(-3);
    expect(controller.zoom.value, 0.0);
  });

  test('toggleFlash reflects platform state', () async {
    await controller.toggleFlash();
    expect(controller.flashEnabled.value, isTrue);
  });

  test('barcode events are flattened onto the result stream', () async {
    final result = BarcodeResult.fromMap({
      'value': 'X',
      'format': BarcodeFormat.qr.bit,
      'boundingBox': {'left': 0, 'top': 0, 'width': 1, 'height': 1},
      'timestamp': 0,
      'imageWidth': 100,
      'imageHeight': 100,
      'rotation': 0,
    });
    final future = controller.barcodes.first;
    fake.emit(1, BarcodesEvent([result]));
    expect((await future).value, 'X');
  });

  test(
    'error events surface on the error stream and set error state',
    () async {
      final future = controller.errors.first;
      fake.emit(1, const ErrorEvent(CameraUnavailable('boom')));
      final e = await future;
      expect(e, isA<CameraUnavailable>());
      expect(controller.state.value, ScannerState.error);
    },
  );

  test('flash/zoom/camera events update notifiers', () async {
    fake.emit(1, const FlashChangedEvent(true));
    fake.emit(1, const ZoomChangedEvent(0.3));
    fake.emit(1, const CameraChangedEvent(CameraFacing.front));
    await Future<void>.delayed(Duration.zero);
    expect(controller.flashEnabled.value, isTrue);
    expect(controller.zoom.value, 0.3);
    expect(controller.cameraFacing.value, CameraFacing.front);
  });

  test('calling controls before attach throws ScannerBusy', () {
    final detached = BarcodeScannerController(platform: fake);
    expect(detached.start, throwsA(isA<ScannerBusy>()));
  });
}
