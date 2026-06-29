# API reference

All public types are exported from `package:barcode_scanner_pro/barcode_scanner_pro.dart`.

## BarcodeScannerController

Reactive, app-facing controller for one scanner view.

```dart
BarcodeScannerController({
  ScannerConfiguration configuration = const ScannerConfiguration(),
  BarcodeScannerPlatform? platform, // injectable for testing
});
```

### Methods

| Method | Description |
|--------|-------------|
| `Future<void> initialize()` | Configure camera + analyzer. |
| `Future<void> start()` | Begin decoding. |
| `Future<void> stop()` | Stop and release the camera session. |
| `Future<void> pause()` / `resume()` | Halt/resume decoding (session retained). |
| `Future<void> dispose()` | Release all resources (idempotent). |
| `Future<void> setFlash(bool)` / `toggleFlash()` | Torch control. |
| `Future<void> switchCamera()` | Toggle front/back. |
| `Future<void> setZoom(double)` | Normalized `[0,1]`. |
| `Future<void> setExposure(double)` | `[-1,1]`, 0 = neutral. |
| `Future<void> setFocus(Offset)` | Normalized `[0,1]` preview point. |
| `Future<Uint8List?> captureFrame()` | JPEG snapshot of the current frame. |

> Calling a control before the view is attached throws `ScannerBusy`.

### Properties

| Property | Type |
|----------|------|
| `barcodes` | `Stream<BarcodeResult>` |
| `errors` | `Stream<ScannerException>` |
| `state` | `ValueNotifier<ScannerState>` |
| `initialized` | `ValueNotifier<bool>` |
| `flashEnabled` | `ValueNotifier<bool>` |
| `zoom` | `ValueNotifier<double>` |
| `cameraFacing` | `ValueNotifier<CameraFacing>` |

## BarcodeScannerView

```dart
BarcodeScannerView({
  required BarcodeScannerController controller,
  OverlayBuilder? overlayBuilder,           // (context, controller) => Widget
  void Function(BarcodeScannerController)? onScannerCreated,
});
```

Hosts the native preview (`PlatformView`) and handles pinch-zoom / tap-focus
gestures when enabled in the configuration.

## ScannerConfiguration

| Field | Type | Default |
|-------|------|---------|
| `camera` | `CameraFacing` | `back` |
| `resolution` | `ResolutionPreset` | `medium` |
| `formats` | `Set<BarcodeFormat>` | all |
| `scanMode` | `ScanMode` | `continuous` |
| `scanArea` | `ScanArea` | `full` |
| `continuousScanning` | `bool` | `true` |
| `duplicateTimeout` | `Duration` | 1000 ms |
| `enableAutoFocus` | `bool` | `true` |
| `enableAutoZoom` | `bool` | `false` |
| `enableSound` | `bool` | `true` |
| `enableVibration` | `bool` | `true` |
| `enableTorchButton` | `bool` | `false` |
| `enablePinchZoom` | `bool` | `true` |
| `enableTapFocus` | `bool` | `true` |
| `frameRateLimit` | `int` | `15` |
| `returnImage` | `bool` | `false` |
| `detectInverted` | `bool` | `false` |

`copyWith(...)` derives variants; `toMap()` is the channel serialization.

## BarcodeResult

`value` · `format` · `boundingBox` (px) · `cornerPoints` (px) · `timestamp` ·
`rawBytes?` · `imageSize` · `rotation` · `confidence?`

Geometry is in image-pixel space with `imageSize`/`rotation` provided to map into
widget space (see the overlay painters).

## Enums

- `BarcodeFormat` — qr, code128, code39, code93, ean8, ean13, upcA, upcE, pdf417,
  aztec, dataMatrix, itf, codabar (+ `all`, `encode`, `fromBit`).
- `ScanMode` — single, continuous, multiBarcode.
- `ScannerState` — uninitialized, initializing, ready, scanning, paused, stopped, error.
- `CameraFacing` — back, front.
- `ResolutionPreset` — low, medium, high, max.

## Errors (`sealed class ScannerException`)

`CameraPermissionDenied` · `CameraUnavailable` · `CameraInitializationFailed` ·
`ScannerBusy` · `DecodingError` · `InvalidConfiguration` · `UnsupportedDevice`.

## Overlay

```dart
ScannerOverlay({
  required BarcodeScannerController controller,
  ScanArea? scanArea,                 // defaults to controller's config
  ScannerOverlayStyle style = const ScannerOverlayStyle(),
});
```

`ScannerOverlayStyle` controls colors, corner geometry, and toggles for the
laser, corners, and detection highlights.
