import 'package:flutter/services.dart';

import '../config/scanner_configuration.dart';
import '../error/scanner_exception.dart';
import 'barcode_scanner_platform.dart';
import 'channels.dart';
import 'scanner_event.dart';

/// Default [BarcodeScannerPlatform] backed by [MethodChannel]/[EventChannel].
///
/// One method channel and one event channel are created lazily per [viewId].
/// Event streams are cached and shared (broadcast) so multiple listeners on the
/// same view do not open redundant native sinks.
class MethodChannelBarcodeScanner extends BarcodeScannerPlatform {
  final MethodChannel _global = const MethodChannel(Channels.global);
  final Map<int, MethodChannel> _methodChannels = {};
  final Map<int, Stream<ScannerEvent>> _eventStreams = {};

  @override
  String get viewType => Channels.viewType;

  MethodChannel _method(int viewId) =>
      _methodChannels[viewId] ??= MethodChannel(Channels.methods(viewId));

  @override
  Stream<ScannerEvent> events(int viewId) {
    return _eventStreams[viewId] ??= EventChannel(Channels.events(viewId))
        .receiveBroadcastStream()
        .map((e) => ScannerEvent.fromMap(e as Map<dynamic, dynamic>))
        .where((e) => e != null)
        .cast<ScannerEvent>();
  }

  /// Wraps a native call, translating [PlatformException] into the typed
  /// [ScannerException] hierarchy so callers never see raw platform errors.
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (e) {
      throw ScannerException.fromCode(e.code, e.message, e.details);
    }
  }

  @override
  Future<bool> checkPermission() => _guard(
    () async =>
        await _global.invokeMethod<bool>(ScannerMethod.checkPermission) ??
        false,
  );

  @override
  Future<bool> requestPermission() => _guard(
    () async =>
        await _global.invokeMethod<bool>(ScannerMethod.requestPermission) ??
        false,
  );

  @override
  Future<void> initialize(int viewId, ScannerConfiguration config) => _guard(
    () => _method(
      viewId,
    ).invokeMethod<void>(ScannerMethod.initialize, config.toMap()),
  );

  @override
  Future<void> start(int viewId) =>
      _guard(() => _method(viewId).invokeMethod<void>(ScannerMethod.start));

  @override
  Future<void> stop(int viewId) =>
      _guard(() => _method(viewId).invokeMethod<void>(ScannerMethod.stop));

  @override
  Future<void> pause(int viewId) =>
      _guard(() => _method(viewId).invokeMethod<void>(ScannerMethod.pause));

  @override
  Future<void> resume(int viewId) =>
      _guard(() => _method(viewId).invokeMethod<void>(ScannerMethod.resume));

  @override
  Future<void> dispose(int viewId) async {
    await _guard(
      () => _method(viewId).invokeMethod<void>(ScannerMethod.dispose),
    );
    _methodChannels.remove(viewId);
    _eventStreams.remove(viewId);
  }

  @override
  Future<void> setFlash(int viewId, bool enabled) => _guard(
    () => _method(
      viewId,
    ).invokeMethod<void>(ScannerMethod.setFlash, {'enabled': enabled}),
  );

  @override
  Future<bool> toggleFlash(int viewId) => _guard(
    () async =>
        await _method(viewId).invokeMethod<bool>(ScannerMethod.toggleFlash) ??
        false,
  );

  @override
  Future<void> switchCamera(int viewId) => _guard(
    () => _method(viewId).invokeMethod<void>(ScannerMethod.switchCamera),
  );

  @override
  Future<void> setZoom(int viewId, double zoom) => _guard(
    () => _method(
      viewId,
    ).invokeMethod<void>(ScannerMethod.setZoom, {'zoom': zoom}),
  );

  @override
  Future<void> setExposure(int viewId, double exposure) => _guard(
    () => _method(
      viewId,
    ).invokeMethod<void>(ScannerMethod.setExposure, {'exposure': exposure}),
  );

  @override
  Future<void> setFocus(int viewId, Offset point) => _guard(
    () => _method(viewId).invokeMethod<void>(ScannerMethod.setFocus, {
      'x': point.dx,
      'y': point.dy,
    }),
  );

  @override
  Future<Uint8List?> captureFrame(int viewId) => _guard(
    () => _method(viewId).invokeMethod<Uint8List>(ScannerMethod.captureFrame),
  );

  @override
  Future<List<Map<Object?, Object?>>> decodeImage(
    Uint8List bytes,
    int formatsMask,
  ) async {
    // Intentionally NOT wrapped in _guard: decodeImage surfaces errors as
    // BarcodeGenException at the generator layer, so PlatformException must
    // propagate here rather than being converted to ScannerException.
    final result = await _global.invokeMethod<List<Object?>>(
      ScannerMethod.decodeImage,
      {'bytes': bytes, 'formats': formatsMask},
    );
    return (result ?? const <Object?>[])
        .map((e) => (e as Map).cast<Object?, Object?>())
        .toList();
  }
}
