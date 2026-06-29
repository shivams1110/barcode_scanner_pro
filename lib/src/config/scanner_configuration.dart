import '../domain/barcode_format.dart';
import '../domain/camera_facing.dart';
import '../domain/resolution_preset.dart';
import '../domain/scan_mode.dart';
import 'scan_area.dart';

/// Immutable configuration for a scanner session.
///
/// Pass an instance to `BarcodeScannerView` / `BarcodeScannerController.initialize`.
/// Use [copyWith] to derive variants. Every field maps 1:1 to a key consumed by
/// the native layer in [toMap].
class ScannerConfiguration {
  const ScannerConfiguration({
    this.camera = CameraFacing.back,
    this.resolution = ResolutionPreset.medium,
    this.formats = BarcodeFormat.all,
    this.scanMode = ScanMode.continuous,
    this.scanArea = ScanArea.full,
    this.continuousScanning = true,
    this.duplicateTimeout = const Duration(milliseconds: 1000),
    this.enableAutoFocus = true,
    this.enableAutoZoom = false,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableTorchButton = false,
    this.enablePinchZoom = true,
    this.enableTapFocus = true,
    this.frameRateLimit = 15,
    this.returnImage = false,
    this.detectInverted = false,
  }) : assert(frameRateLimit > 0 && frameRateLimit <= 60);

  final CameraFacing camera;
  final ResolutionPreset resolution;
  final Set<BarcodeFormat> formats;
  final ScanMode scanMode;
  final ScanArea scanArea;

  /// When false, decoding stops after the first emitted result regardless of
  /// [scanMode]. Convenience flag layered on top of [ScanMode].
  final bool continuousScanning;

  /// Window during which an identical (value+format) detection is suppressed.
  final Duration duplicateTimeout;

  final bool enableAutoFocus;
  final bool enableAutoZoom;
  final bool enableSound;
  final bool enableVibration;

  /// Whether the native preview draws its own torch button. Usually false —
  /// the Flutter overlay provides controls instead.
  final bool enableTorchButton;

  final bool enablePinchZoom;
  final bool enableTapFocus;

  /// Maximum frames per second handed to the decoder. The preview always runs
  /// at the camera's native rate; only decode cadence is throttled.
  final int frameRateLimit;

  /// When true, each result carries a JPEG snapshot of the frame in `rawBytes`.
  /// Increases payload size and latency — enable only when needed.
  final bool returnImage;

  /// Attempt detection of color-inverted codes (light-on-dark).
  final bool detectInverted;

  ScannerConfiguration copyWith({
    CameraFacing? camera,
    ResolutionPreset? resolution,
    Set<BarcodeFormat>? formats,
    ScanMode? scanMode,
    ScanArea? scanArea,
    bool? continuousScanning,
    Duration? duplicateTimeout,
    bool? enableAutoFocus,
    bool? enableAutoZoom,
    bool? enableSound,
    bool? enableVibration,
    bool? enableTorchButton,
    bool? enablePinchZoom,
    bool? enableTapFocus,
    int? frameRateLimit,
    bool? returnImage,
    bool? detectInverted,
  }) {
    return ScannerConfiguration(
      camera: camera ?? this.camera,
      resolution: resolution ?? this.resolution,
      formats: formats ?? this.formats,
      scanMode: scanMode ?? this.scanMode,
      scanArea: scanArea ?? this.scanArea,
      continuousScanning: continuousScanning ?? this.continuousScanning,
      duplicateTimeout: duplicateTimeout ?? this.duplicateTimeout,
      enableAutoFocus: enableAutoFocus ?? this.enableAutoFocus,
      enableAutoZoom: enableAutoZoom ?? this.enableAutoZoom,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      enableTorchButton: enableTorchButton ?? this.enableTorchButton,
      enablePinchZoom: enablePinchZoom ?? this.enablePinchZoom,
      enableTapFocus: enableTapFocus ?? this.enableTapFocus,
      frameRateLimit: frameRateLimit ?? this.frameRateLimit,
      returnImage: returnImage ?? this.returnImage,
      detectInverted: detectInverted ?? this.detectInverted,
    );
  }

  /// Serializes to the channel representation consumed by native code.
  Map<String, dynamic> toMap() => {
    'camera': camera.index,
    'resolution': resolution.index,
    'formats': BarcodeFormat.encode(formats),
    'scanMode': scanMode.index,
    'scanArea': scanArea.toMap(),
    'continuousScanning': continuousScanning,
    'duplicateTimeoutMs': duplicateTimeout.inMilliseconds,
    'enableAutoFocus': enableAutoFocus,
    'enableAutoZoom': enableAutoZoom,
    'enableSound': enableSound,
    'enableVibration': enableVibration,
    'enableTorchButton': enableTorchButton,
    'enablePinchZoom': enablePinchZoom,
    'enableTapFocus': enableTapFocus,
    'frameRateLimit': frameRateLimit,
    'returnImage': returnImage,
    'detectInverted': detectInverted,
  };
}
