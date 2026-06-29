import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScannerEvent.fromMap', () {
    test('decodes a barcodeDetected batch', () {
      final event = ScannerEvent.fromMap({
        'type': 'barcodeDetected',
        'barcodes': [
          {
            'value': 'A',
            'format': BarcodeFormat.code128.bit,
            'boundingBox': {'left': 0, 'top': 0, 'width': 1, 'height': 1},
            'timestamp': 0,
            'imageWidth': 10,
            'imageHeight': 10,
            'rotation': 0,
          },
        ],
      });
      expect(event, isA<BarcodesEvent>());
      expect((event as BarcodesEvent).barcodes.single.value, 'A');
    });

    test('decodes lifecycle and control events', () {
      expect(
        ScannerEvent.fromMap({'type': 'scannerStarted'}),
        isA<ScannerStartedEvent>(),
      );
      expect(
        ScannerEvent.fromMap({'type': 'scannerStopped'}),
        isA<ScannerStoppedEvent>(),
      );
      expect(
        ScannerEvent.fromMap({'type': 'permissionDenied'}),
        isA<PermissionDeniedEvent>(),
      );
      expect(
        ScannerEvent.fromMap({'type': 'flashChanged', 'enabled': true}),
        isA<FlashChangedEvent>(),
      );
      expect(
        ScannerEvent.fromMap({'type': 'zoomChanged', 'zoom': 0.4}),
        isA<ZoomChangedEvent>(),
      );
    });

    test('maps error codes to typed exceptions', () {
      final event = ScannerEvent.fromMap({
        'type': 'error',
        'code': 'CAMERA_PERMISSION_DENIED',
        'message': 'nope',
      });
      expect(event, isA<ErrorEvent>());
      expect((event as ErrorEvent).exception, isA<CameraPermissionDenied>());
    });

    test('returns null for unknown event types', () {
      expect(ScannerEvent.fromMap({'type': 'nope'}), isNull);
    });
  });
}
