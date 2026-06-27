import '../domain/barcode_result.dart';
import '../domain/camera_facing.dart';
import '../error/scanner_exception.dart';
import 'channels.dart';

/// A typed event decoded from the native [EventChannel] stream.
///
/// This is an internal transport type; the controller fans these out into the
/// public result stream and value notifiers. Use the sealed subtypes to switch
/// exhaustively.
sealed class ScannerEvent {
  const ScannerEvent();

  /// Decodes a raw event map. Returns null for unrecognized payloads so the
  /// stream can ignore them defensively.
  static ScannerEvent? fromMap(Map<dynamic, dynamic> map) {
    final type = ScannerEventType.fromName(map['type'] as String? ?? '');
    switch (type) {
      case ScannerEventType.barcodeDetected:
        final list = (map['barcodes'] as List<dynamic>? ?? const [])
            .map((e) => BarcodeResult.fromMap(e as Map<dynamic, dynamic>))
            .toList(growable: false);
        return BarcodesEvent(list);
      case ScannerEventType.scannerStarted:
        return const ScannerStartedEvent();
      case ScannerEventType.scannerStopped:
        return const ScannerStoppedEvent();
      case ScannerEventType.permissionDenied:
        return const PermissionDeniedEvent();
      case ScannerEventType.cameraChanged:
        return CameraChangedEvent(
          CameraFacing.fromIndex(map['camera'] as int? ?? 0),
        );
      case ScannerEventType.flashChanged:
        return FlashChangedEvent(map['enabled'] as bool? ?? false);
      case ScannerEventType.zoomChanged:
        return ZoomChangedEvent((map['zoom'] as num?)?.toDouble() ?? 0);
      case ScannerEventType.error:
        return ErrorEvent(
          ScannerException.fromCode(
            map['code'] as String? ?? ScannerErrorCode.decodingError,
            map['message'] as String?,
            map['details'],
          ),
        );
      case null:
        return null;
    }
  }
}

class BarcodesEvent extends ScannerEvent {
  const BarcodesEvent(this.barcodes);
  final List<BarcodeResult> barcodes;
}

class ScannerStartedEvent extends ScannerEvent {
  const ScannerStartedEvent();
}

class ScannerStoppedEvent extends ScannerEvent {
  const ScannerStoppedEvent();
}

class PermissionDeniedEvent extends ScannerEvent {
  const PermissionDeniedEvent();
}

class CameraChangedEvent extends ScannerEvent {
  const CameraChangedEvent(this.camera);
  final CameraFacing camera;
}

class FlashChangedEvent extends ScannerEvent {
  const FlashChangedEvent(this.enabled);
  final bool enabled;
}

class ZoomChangedEvent extends ScannerEvent {
  const ZoomChangedEvent(this.zoom);
  final double zoom;
}

class ErrorEvent extends ScannerEvent {
  const ErrorEvent(this.exception);
  final ScannerException exception;
}
