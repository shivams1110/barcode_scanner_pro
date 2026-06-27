import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../config/scanner_configuration.dart';
import 'method_channel_barcode_scanner.dart';
import 'scanner_event.dart';

/// The contract every platform implementation must satisfy.
///
/// The controller depends on this abstraction rather than a concrete channel,
/// which keeps the controller unit-testable (inject a fake) and decouples the
/// public API from transport details. The default instance is
/// [MethodChannelBarcodeScanner].
///
/// Methods are scoped by [viewId] so a single app can host multiple
/// independent scanner views.
abstract class BarcodeScannerPlatform extends PlatformInterface {
  BarcodeScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static BarcodeScannerPlatform _instance = MethodChannelBarcodeScanner();

  static BarcodeScannerPlatform get instance => _instance;

  /// Overridable for tests / alternative implementations.
  static set instance(BarcodeScannerPlatform value) {
    PlatformInterface.verifyToken(value, _token);
    _instance = value;
  }

  /// The platform view type id to register with `AndroidView`/`UiKitView`.
  String get viewType;

  /// Returns the broadcast event stream for the given [viewId].
  Stream<ScannerEvent> events(int viewId);

  // --- Global, view-independent -------------------------------------------

  /// Whether camera permission is currently granted.
  Future<bool> checkPermission();

  /// Requests camera permission; resolves to the granted state.
  Future<bool> requestPermission();

  // --- View-scoped lifecycle ----------------------------------------------

  Future<void> initialize(int viewId, ScannerConfiguration config);
  Future<void> start(int viewId);
  Future<void> stop(int viewId);
  Future<void> pause(int viewId);
  Future<void> resume(int viewId);
  Future<void> dispose(int viewId);

  // --- View-scoped camera controls ----------------------------------------

  Future<void> setFlash(int viewId, bool enabled);
  Future<bool> toggleFlash(int viewId);
  Future<void> switchCamera(int viewId);

  /// [zoom] is a normalized value in `[0, 1]` mapped to the device's range.
  Future<void> setZoom(int viewId, double zoom);

  /// [exposure] in `[-1, 1]` mapped to the device's EV range; 0 is auto/neutral.
  Future<void> setExposure(int viewId, double exposure);

  /// [point] is normalized `[0, 1]` in preview space.
  Future<void> setFocus(int viewId, Offset point);

  /// Captures the current frame as JPEG bytes, or null if unavailable.
  Future<Uint8List?> captureFrame(int viewId);
}
