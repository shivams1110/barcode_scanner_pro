/// Centralized channel naming and method/event identifiers.
///
/// Channels are scoped per native PlatformView via the view id so that multiple
/// concurrent scanners never receive each other's traffic. This is the single
/// source of truth for names — mirrored verbatim in the Android and iOS code.
class Channels {
  Channels._();

  static const String _base = 'com.karnival.barcode_scanner_pro';

  /// View identifier registered with the platform-view factory.
  static const String viewType = '$_base/view';

  /// Method channel for commands targeting the view [id].
  static String methods(int id) => '$_base/methods/$id';

  /// Event channel streaming scanner events for the view [id].
  static String events(int id) => '$_base/events/$id';

  /// Global method channel for view-independent calls (permissions).
  static const String global = '$_base/global';
}

/// Method names invoked Flutter -> native.
class ScannerMethod {
  ScannerMethod._();

  static const initialize = 'initialize';
  static const start = 'start';
  static const stop = 'stop';
  static const pause = 'pause';
  static const resume = 'resume';
  static const dispose = 'dispose';
  static const setFlash = 'setFlash';
  static const toggleFlash = 'toggleFlash';
  static const switchCamera = 'switchCamera';
  static const setZoom = 'setZoom';
  static const setExposure = 'setExposure';
  static const setFocus = 'setFocus';
  static const captureFrame = 'captureFrame';
  static const decodeImage = 'decodeImage';

  // Global
  static const requestPermission = 'requestPermission';
  static const checkPermission = 'checkPermission';
}

/// Event type discriminator carried in the `type` field of every event map.
enum ScannerEventType {
  barcodeDetected,
  scannerStarted,
  scannerStopped,
  permissionDenied,
  error,
  cameraChanged,
  flashChanged,
  zoomChanged;

  static ScannerEventType? fromName(String name) {
    for (final e in values) {
      if (e.name == name) return e;
    }
    return null;
  }
}
