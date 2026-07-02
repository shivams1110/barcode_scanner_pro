// Web implementation of barcode_scanner_pro.
//
// Camera preview comes from a `<video>` element hosted in an `HtmlElementView`;
// detection uses the browser-native `BarcodeDetector` API (Chromium-based
// browsers and Android Chrome). Safari and Firefox do not ship `BarcodeDetector`
// today — there the plugin feature-detects and emits an unsupported error rather
// than bundling a third-party decoder, mirroring the plugin's native-only ethos
// on iOS/Android (Vision / ML Kit).
//
// This file is only ever compiled for the web target (referenced via the `web`
// plugin `fileName` in pubspec); it must not be imported from shared library
// code, which would break mobile/desktop builds.
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;
import 'dart:ui_web' as ui_web;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import '../config/scanner_configuration.dart';
import '../domain/barcode_format.dart';
import '../domain/barcode_result.dart';
import '../domain/camera_facing.dart';
import '../error/scanner_exception.dart';
import '../platform/barcode_scanner_platform.dart';
import '../platform/channels.dart';
import '../platform/scanner_event.dart';

// --- BarcodeDetector JS interop ---------------------------------------------

extension type _BarcodeDetectorOptions._(JSObject _) implements JSObject {
  external factory _BarcodeDetectorOptions({JSArray<JSString> formats});
}

@JS('BarcodeDetector')
extension type _BarcodeDetector._(JSObject _) implements JSObject {
  external factory _BarcodeDetector([_BarcodeDetectorOptions options]);
  external JSPromise<JSArray<_DetectedBarcode>> detect(JSObject source);
}

extension type _DetectedBarcode._(JSObject _) implements JSObject {
  external String get rawValue;
  external String get format;
  external web.DOMRectReadOnly get boundingBox;
  external JSArray<web.DOMPointReadOnly> get cornerPoints;
}

/// Whether the current browser exposes the `BarcodeDetector` API.
bool get _barcodeDetectorSupported =>
    globalContext.has('BarcodeDetector');

// --- Format mapping ----------------------------------------------------------

/// `BarcodeDetector` format string → our [BarcodeFormat].
const Map<String, BarcodeFormat> _webFormatToEnum = {
  'aztec': BarcodeFormat.aztec,
  'codabar': BarcodeFormat.codabar,
  'code_128': BarcodeFormat.code128,
  'code_39': BarcodeFormat.code39,
  'code_93': BarcodeFormat.code93,
  'data_matrix': BarcodeFormat.dataMatrix,
  'ean_13': BarcodeFormat.ean13,
  'ean_8': BarcodeFormat.ean8,
  'itf': BarcodeFormat.itf,
  'pdf417': BarcodeFormat.pdf417,
  'qr_code': BarcodeFormat.qr,
  'upc_a': BarcodeFormat.upcA,
  'upc_e': BarcodeFormat.upcE,
};

BarcodeFormat _formatFromWeb(String s) => _webFormatToEnum[s] ?? BarcodeFormat.qr;

/// Our [BarcodeFormat] → `BarcodeDetector` format string.
final Map<BarcodeFormat, String> _enumToWebFormat = {
  for (final e in _webFormatToEnum.entries) e.value: e.key,
};

/// Translates a cross-platform format bitmask into the `BarcodeDetector`
/// `formats` list. An empty result means "detect all supported formats".
List<String> _formatsFromMask(int mask) {
  if (mask == 0) return const [];
  final out = <String>[];
  for (final f in BarcodeFormat.values) {
    if (mask & f.bit != 0) {
      final s = _enumToWebFormat[f];
      if (s != null) out.add(s);
    }
  }
  return out;
}

// --- Per-view scanner --------------------------------------------------------

/// Owns one `<video>` preview, its media stream, and the detection loop for a
/// single Flutter platform view.
class _WebScanner {
  _WebScanner(this.viewId) {
    video = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true');
    video.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'cover';
  }

  final int viewId;
  late final web.HTMLVideoElement video;

  final StreamController<ScannerEvent> _events =
      StreamController<ScannerEvent>.broadcast();
  Stream<ScannerEvent> get events => _events.stream;

  _BarcodeDetector? _detector;
  web.MediaStream? _stream;
  Timer? _loop;
  bool _analyzing = false;
  bool _busy = false;
  String _facing = 'environment';

  // Simple duplicate suppression: value|format → last-emitted time.
  final Map<String, DateTime> _recent = {};
  static const Duration _dedupWindow = Duration(seconds: 2);

  Future<void> initialize(ScannerConfiguration config) async {
    if (!_barcodeDetectorSupported) {
      _emitError(
        ScannerErrorCode.decodingError,
        'BarcodeDetector API is unavailable in this browser',
      );
      return;
    }
    final formats = _formatsFromMask(config.toMap()['formats'] as int? ?? 0);
    _detector = formats.isEmpty
        ? _BarcodeDetector()
        : _BarcodeDetector(
            _BarcodeDetectorOptions(
              formats: formats.map((s) => s.toJS).toList().toJS,
            ),
          );

    try {
      await _openStream();
    } on Object catch (e) {
      _emitError(ScannerErrorCode.initializationFailed, e.toString());
      rethrow;
    }
  }

  Future<void> _openStream() async {
    final constraints = web.MediaStreamConstraints(
      video: web.MediaTrackConstraints(facingMode: _facing.toJS) as JSAny,
      audio: false.toJS,
    );
    final stream = await web.window.navigator.mediaDevices
        .getUserMedia(constraints)
        .toDart;
    _stream = stream;
    video.srcObject = stream;
    // Play returns a promise; ignore rejection (autoplay policies vary).
    video.play().toDart.ignore();
  }

  void start() {
    _analyzing = true;
    _recent.clear();
    _loop ??= Timer.periodic(const Duration(milliseconds: 150), (_) {
      _tick();
    });
    _events.add(const ScannerStartedEvent());
  }

  void stop() {
    _analyzing = false;
    _loop?.cancel();
    _loop = null;
    _events.add(const ScannerStoppedEvent());
  }

  void pause() => _analyzing = false;

  void resume() {
    _recent.clear();
    _analyzing = true;
  }

  Future<void> _tick() async {
    if (!_analyzing || _busy) return;
    final detector = _detector;
    if (detector == null) return;
    if (video.readyState < 2 /* HAVE_CURRENT_DATA */) return;
    _busy = true;
    try {
      final found = (await detector.detect(video).toDart).toDart;
      if (found.isEmpty) return;
      final w = video.videoWidth.toDouble();
      final h = video.videoHeight.toDouble();
      final results = <BarcodeResult>[];
      final now = DateTime.now();
      for (final b in found) {
        final key = '${b.rawValue}|${b.format}';
        final last = _recent[key];
        if (last != null && now.difference(last) < _dedupWindow) continue;
        _recent[key] = now;
        results.add(_toResult(b, w, h, now));
      }
      if (results.isNotEmpty) _events.add(BarcodesEvent(results));
    } on Object catch (_) {
      // Transient detect() failures (e.g. frame not ready) are ignored.
    } finally {
      _busy = false;
    }
  }

  BarcodeResult _toResult(
    _DetectedBarcode b,
    double imgW,
    double imgH,
    DateTime ts,
  ) {
    final box = b.boundingBox;
    final corners = <Offset>[];
    for (final p in b.cornerPoints.toDart) {
      corners.add(Offset(p.x.toDouble(), p.y.toDouble()));
    }
    return BarcodeResult(
      value: b.rawValue,
      format: _formatFromWeb(b.format),
      boundingBox: Rect.fromLTWH(
        box.x.toDouble(),
        box.y.toDouble(),
        box.width.toDouble(),
        box.height.toDouble(),
      ),
      cornerPoints: corners,
      timestamp: ts,
      imageSize: Size(imgW, imgH),
      rotation: 0,
    );
  }

  Future<void> switchCamera() async {
    _facing = _facing == 'environment' ? 'user' : 'environment';
    _stopTracks();
    try {
      await _openStream();
      _events.add(
        CameraChangedEvent(
          _facing == 'user' ? CameraFacing.front : CameraFacing.back,
        ),
      );
    } on Object catch (e) {
      _emitError(ScannerErrorCode.cameraUnavailable, e.toString());
    }
  }

  Future<void> setFlash(bool enabled) async {
    if (await _applyTrackConstraint('torch', enabled.toJS)) {
      _events.add(FlashChangedEvent(enabled));
    }
  }

  bool _flashOn = false;
  Future<bool> toggleFlash() async {
    final next = !_flashOn;
    await setFlash(next);
    _flashOn = next;
    return next;
  }

  Future<void> setZoom(double zoom) async {
    // Map normalized [0,1] onto the track's zoom capability when present.
    final track = _videoTrack;
    if (track == null) return;
    final caps = track.getCapabilities();
    if (!caps.has('zoom')) return;
    final zc = caps.getProperty<JSObject>('zoom'.toJS);
    final min = (zc.getProperty<JSNumber>('min'.toJS)).toDartDouble;
    final max = (zc.getProperty<JSNumber>('max'.toJS)).toDartDouble;
    final value = min + zoom.clamp(0.0, 1.0) * (max - min);
    if (await _applyTrackConstraint('zoom', value.toJS)) {
      _events.add(ZoomChangedEvent(zoom.clamp(0.0, 1.0)));
    }
  }

  web.MediaStreamTrack? get _videoTrack {
    final tracks = _stream?.getVideoTracks().toDart;
    if (tracks == null || tracks.isEmpty) return null;
    return tracks.first;
  }

  Future<bool> _applyTrackConstraint(String key, JSAny value) async {
    final track = _videoTrack;
    if (track == null) return false;
    try {
      final advanced = web.MediaTrackConstraintSet();
      advanced.setProperty(key.toJS, value);
      final constraints = web.MediaTrackConstraints(
        advanced: [advanced].toJS,
      );
      await track.applyConstraints(constraints).toDart;
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  Uint8List? captureFrame() {
    final w = video.videoWidth;
    final h = video.videoHeight;
    if (w == 0 || h == 0) return null;
    final canvas = web.HTMLCanvasElement()
      ..width = w
      ..height = h;
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (ctx == null) return null;
    ctx.drawImage(video, 0, 0);
    final dataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
    final comma = dataUrl.indexOf(',');
    if (comma < 0) return null;
    return base64Decode(dataUrl.substring(comma + 1));
  }

  void _emitError(String code, String message) =>
      _events.add(ErrorEvent(ScannerException.fromCode(code, message, null)));

  void _stopTracks() {
    final tracks = _stream?.getTracks().toDart;
    if (tracks != null) {
      for (final t in tracks) {
        t.stop();
      }
    }
    _stream = null;
  }

  void dispose() {
    _loop?.cancel();
    _loop = null;
    _stopTracks();
    video.srcObject = null;
    _events.close();
  }
}

// --- Plugin ------------------------------------------------------------------

/// Web platform implementation registered via the `web` plugin declaration.
class BarcodeScannerProWeb extends BarcodeScannerPlatform {
  BarcodeScannerProWeb() {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final scanner = _WebScanner(viewId);
      _views[viewId] = scanner;
      return scanner.video;
    });
  }

  static void registerWith(Registrar registrar) {
    BarcodeScannerPlatform.instance = BarcodeScannerProWeb();
  }

  final Map<int, _WebScanner> _views = {};

  @override
  String get viewType => Channels.viewType;

  @override
  Stream<ScannerEvent> events(int viewId) =>
      _views[viewId]?.events ?? const Stream<ScannerEvent>.empty();

  @override
  Future<bool> checkPermission() async {
    try {
      final status = await web.window.navigator.permissions
          .query({'name': 'camera'}.jsify() as JSObject)
          .toDart;
      return status.state == 'granted';
    } on Object catch (_) {
      // Permissions API or the "camera" name may be unsupported; report unknown
      // as false and let requestPermission drive the actual prompt.
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final constraints = web.MediaStreamConstraints(video: true.toJS);
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
      // Immediately release; this call exists only to trigger the prompt.
      for (final t in stream.getTracks().toDart) {
        t.stop();
      }
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Future<int?> initialize(int viewId, ScannerConfiguration config) async {
    await _views[viewId]?.initialize(config);
    return null;
  }

  @override
  Future<void> start(int viewId) async => _views[viewId]?.start();

  @override
  Future<void> stop(int viewId) async => _views[viewId]?.stop();

  @override
  Future<void> pause(int viewId) async => _views[viewId]?.pause();

  @override
  Future<void> resume(int viewId) async => _views[viewId]?.resume();

  @override
  Future<void> dispose(int viewId) async {
    _views.remove(viewId)?.dispose();
  }

  @override
  Future<void> setFlash(int viewId, bool enabled) async =>
      _views[viewId]?.setFlash(enabled);

  @override
  Future<bool> toggleFlash(int viewId) async =>
      await _views[viewId]?.toggleFlash() ?? false;

  @override
  Future<void> switchCamera(int viewId) async =>
      _views[viewId]?.switchCamera();

  @override
  Future<void> setZoom(int viewId, double zoom) async =>
      _views[viewId]?.setZoom(zoom);

  // Exposure and tap-to-focus have no portable web equivalent; no-op.
  @override
  Future<void> setExposure(int viewId, double exposure) async {}

  @override
  Future<void> setFocus(int viewId, Offset point) async {}

  @override
  Future<Uint8List?> captureFrame(int viewId) async =>
      _views[viewId]?.captureFrame();

  @override
  Future<List<Map<Object?, Object?>>> decodeImage(
    Uint8List bytes,
    int formatsMask,
  ) async {
    if (!_barcodeDetectorSupported) {
      throw ScannerException.fromCode(
        ScannerErrorCode.decodingError,
        'BarcodeDetector API is unavailable in this browser',
        null,
      );
    }
    final formats = _formatsFromMask(formatsMask);
    final detector = formats.isEmpty
        ? _BarcodeDetector()
        : _BarcodeDetector(
            _BarcodeDetectorOptions(
              formats: formats.map((s) => s.toJS).toList().toJS,
            ),
          );

    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/octet-stream'),
    );
    final bitmap = await web.window.createImageBitmap(blob).toDart;
    final found = (await detector.detect(bitmap).toDart).toDart;
    final out = <Map<Object?, Object?>>[];
    for (final b in found) {
      final corners = <Map<String, double>>[];
      for (final p in b.cornerPoints.toDart) {
        corners.add({'x': p.x.toDouble(), 'y': p.y.toDouble()});
      }
      out.add({
        'value': b.rawValue,
        'format': _formatFromWeb(b.format).bit,
        'rawBytes': null,
        'cornerPoints': corners,
      });
    }
    return out;
  }
}
