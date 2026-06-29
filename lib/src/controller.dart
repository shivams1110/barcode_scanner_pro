import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'config/scanner_configuration.dart';
import 'domain/barcode_result.dart';
import 'domain/camera_facing.dart';
import 'domain/scanner_state.dart';
import 'error/scanner_exception.dart';
import 'platform/barcode_scanner_platform.dart';
import 'platform/scanner_event.dart';

/// App-facing controller for a single scanner view.
///
/// Lifecycle: create a controller, hand it to a [BarcodeScannerView], then call
/// [initialize]/[start]. The view binds the native [viewId] via
/// [attach]; calling control methods before attachment throws [ScannerBusy].
///
/// The controller observes app lifecycle (background/resume) and automatically
/// pauses/resumes the camera, so callers normally do not manage this manually.
class BarcodeScannerController with WidgetsBindingObserver {
  /// [platform] is injectable for testing; defaults to the channel impl.
  BarcodeScannerController({
    ScannerConfiguration configuration = const ScannerConfiguration(),
    BarcodeScannerPlatform? platform,
  }) : _config = configuration,
       _platform = platform ?? BarcodeScannerPlatform.instance;

  final BarcodeScannerPlatform _platform;
  final ScannerConfiguration _config;

  int? _viewId;
  StreamSubscription<ScannerEvent>? _eventSub;
  bool _wasScanningBeforeBackground = false;
  bool _disposed = false;

  // --- Public reactive surface ---------------------------------------------

  final _barcodes = StreamController<BarcodeResult>.broadcast();
  final _errors = StreamController<ScannerException>.broadcast();

  /// Stream of individual detected barcodes (flattened from batch events).
  Stream<BarcodeResult> get barcodes => _barcodes.stream;

  /// Stream of recoverable/non-recoverable errors emitted by the scanner.
  Stream<ScannerException> get errors => _errors.stream;

  final ValueNotifier<ScannerState> state = ValueNotifier(
    ScannerState.uninitialized,
  );
  final ValueNotifier<bool> initialized = ValueNotifier(false);
  final ValueNotifier<bool> flashEnabled = ValueNotifier(false);
  final ValueNotifier<double> zoom = ValueNotifier(0);
  final ValueNotifier<CameraFacing> cameraFacing = ValueNotifier(
    CameraFacing.back,
  );

  ScannerConfiguration get configuration => _config;
  int? get viewId => _viewId;

  // --- View binding ---------------------------------------------------------

  /// Called by [BarcodeScannerView] once the native view is created. Wires the
  /// event stream and registers the lifecycle observer. Internal use.
  void attach(int viewId) {
    if (_disposed) return;
    _viewId = viewId;
    cameraFacing.value = _config.camera;
    WidgetsBinding.instance.addObserver(this);
    _eventSub = _platform.events(viewId).listen(_onEvent);
  }

  void _ensureAttached() {
    if (_viewId == null) {
      throw const ScannerBusy('Controller is not attached to a view yet.');
    }
  }

  void _onEvent(ScannerEvent event) {
    switch (event) {
      case BarcodesEvent(:final barcodes):
        for (final b in barcodes) {
          if (!_barcodes.isClosed) _barcodes.add(b);
        }
      case ScannerStartedEvent():
        state.value = ScannerState.scanning;
      case ScannerStoppedEvent():
        state.value = ScannerState.stopped;
      case PermissionDeniedEvent():
        _emitError(const CameraPermissionDenied('Camera permission denied.'));
      case CameraChangedEvent(:final camera):
        cameraFacing.value = camera;
      case FlashChangedEvent(:final enabled):
        flashEnabled.value = enabled;
      case ZoomChangedEvent(:final zoom):
        this.zoom.value = zoom;
      case ErrorEvent(:final exception):
        _emitError(exception);
    }
  }

  void _emitError(ScannerException e) {
    state.value = ScannerState.error;
    if (!_errors.isClosed) _errors.add(e);
  }

  // --- Lifecycle methods (public API) ---------------------------------------

  /// Configures the native camera + analyzer. Safe to call once per attach.
  Future<void> initialize() async {
    _ensureAttached();
    state.value = ScannerState.initializing;
    try {
      await _platform.initialize(_viewId!, _config);
      initialized.value = true;
      state.value = ScannerState.ready;
    } on ScannerException catch (e) {
      _emitError(e);
      rethrow;
    }
  }

  Future<void> start() async {
    _ensureAttached();
    await _platform.start(_viewId!);
  }

  Future<void> stop() async {
    _ensureAttached();
    await _platform.stop(_viewId!);
  }

  Future<void> pause() async {
    _ensureAttached();
    await _platform.pause(_viewId!);
    state.value = ScannerState.paused;
  }

  Future<void> resume() async {
    _ensureAttached();
    await _platform.resume(_viewId!);
    state.value = ScannerState.scanning;
  }

  // --- Camera controls -------------------------------------------------------

  Future<void> setFlash(bool enabled) async {
    _ensureAttached();
    await _platform.setFlash(_viewId!, enabled);
    flashEnabled.value = enabled;
  }

  Future<void> toggleFlash() async {
    _ensureAttached();
    flashEnabled.value = await _platform.toggleFlash(_viewId!);
  }

  Future<void> switchCamera() async {
    _ensureAttached();
    await _platform.switchCamera(_viewId!);
    cameraFacing.value = cameraFacing.value.opposite;
  }

  /// [value] normalized `[0, 1]`.
  Future<void> setZoom(double value) async {
    _ensureAttached();
    final clamped = value.clamp(0.0, 1.0);
    await _platform.setZoom(_viewId!, clamped);
    zoom.value = clamped;
  }

  /// [value] in `[-1, 1]`.
  Future<void> setExposure(double value) async {
    _ensureAttached();
    await _platform.setExposure(_viewId!, value.clamp(-1.0, 1.0));
  }

  /// [point] normalized `[0, 1]` in preview space.
  Future<void> setFocus(Offset point) async {
    _ensureAttached();
    await _platform.setFocus(_viewId!, point);
  }

  /// Captures the current frame as JPEG bytes.
  Future<Uint8List?> captureFrame() async {
    _ensureAttached();
    return _platform.captureFrame(_viewId!);
  }

  // --- App lifecycle handling ------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_viewId == null) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _wasScanningBeforeBackground =
            this.state.value == ScannerState.scanning;
        if (_wasScanningBeforeBackground) {
          pause().catchError((_) {});
        }
      case AppLifecycleState.resumed:
        if (_wasScanningBeforeBackground) {
          resume().catchError((_) {});
          _wasScanningBeforeBackground = false;
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Releases all native and Dart resources. Idempotent.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    await _eventSub?.cancel();
    if (_viewId != null) {
      try {
        await _platform.dispose(_viewId!);
      } on ScannerException {
        // Best-effort teardown; native side may already be gone.
      }
    }
    await _barcodes.close();
    await _errors.close();
    state.dispose();
    initialized.dispose();
    flashEnabled.dispose();
    zoom.dispose();
    cameraFacing.dispose();
  }
}
