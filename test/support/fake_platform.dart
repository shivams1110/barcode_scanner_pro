import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// In-memory [BarcodeScannerPlatform] used by unit tests. Records every call
/// and lets tests drive the event stream manually, so the controller can be
/// exercised without any native code.
class FakeBarcodeScannerPlatform extends BarcodeScannerPlatform
    with MockPlatformInterfaceMixin {
  final List<String> calls = [];
  final Map<int, StreamController<ScannerEvent>> _controllers = {};

  bool permission = true;
  bool flash = false;

  StreamController<ScannerEvent> _controllerFor(int id) => _controllers
      .putIfAbsent(id, () => StreamController<ScannerEvent>.broadcast());

  /// Pushes an event to listeners of [viewId].
  void emit(int viewId, ScannerEvent event) =>
      _controllerFor(viewId).add(event);

  @override
  String get viewType => 'fake/view';

  @override
  Stream<ScannerEvent> events(int viewId) => _controllerFor(viewId).stream;

  @override
  Future<bool> checkPermission() async {
    calls.add('checkPermission');
    return permission;
  }

  @override
  Future<bool> requestPermission() async {
    calls.add('requestPermission');
    return permission;
  }

  @override
  Future<void> initialize(int viewId, ScannerConfiguration config) async =>
      calls.add('initialize');

  @override
  Future<void> start(int viewId) async => calls.add('start');

  @override
  Future<void> stop(int viewId) async => calls.add('stop');

  @override
  Future<void> pause(int viewId) async => calls.add('pause');

  @override
  Future<void> resume(int viewId) async => calls.add('resume');

  @override
  Future<void> dispose(int viewId) async {
    calls.add('dispose');
    await _controllers.remove(viewId)?.close();
  }

  @override
  Future<void> setFlash(int viewId, bool enabled) async {
    calls.add('setFlash:$enabled');
    flash = enabled;
  }

  @override
  Future<bool> toggleFlash(int viewId) async {
    calls.add('toggleFlash');
    flash = !flash;
    return flash;
  }

  @override
  Future<void> switchCamera(int viewId) async => calls.add('switchCamera');

  @override
  Future<void> setZoom(int viewId, double zoom) async =>
      calls.add('setZoom:$zoom');

  @override
  Future<void> setExposure(int viewId, double exposure) async =>
      calls.add('setExposure:$exposure');

  @override
  Future<void> setFocus(int viewId, Offset point) async =>
      calls.add('setFocus:${point.dx},${point.dy}');

  @override
  Future<Uint8List?> captureFrame(int viewId) async {
    calls.add('captureFrame');
    return Uint8List.fromList([1, 2, 3]);
  }

  List<Map<Object?, Object?>> decodeImageResult = const [];
  Object? decodeImageError; // if set, thrown
  int? lastDecodeMask;

  @override
  Future<List<Map<Object?, Object?>>> decodeImage(
    Uint8List bytes,
    int formatsMask,
  ) async {
    calls.add('decodeImage');
    lastDecodeMask = formatsMask;
    final err = decodeImageError;
    if (err != null) throw err;
    return decodeImageResult;
  }
}
