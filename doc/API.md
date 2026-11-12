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
| `confirmations` | `int` | `2` |
| `enableAutoFocus` | `bool` | `true` |
| `enableAutoZoom` | `bool` | `false` (Android only) |
| `enableSound` | `bool` | `true` |
| `enableVibration` | `bool` | `true` |
| `enableTorchButton` | `bool` | `false` |
| `enablePinchZoom` | `bool` | `true` |
| `enableTapFocus` | `bool` | `true` |
| `frameRateLimit` | `int` | `15` |
| `returnImage` | `bool` | `false` |
| `detectInverted` | `bool` | `false` |

`copyWith(...)` derives variants; `toMap()` is the channel serialization.

### Misread protection — `confirmations`

The decode engines (ML Kit, Vision) return a payload with no confidence score.
Symbologies with no mandatory check digit — **Code 39, Code 93, ITF, Codabar** —
can decode a blurred, tilted or edge-clipped frame into a *structurally valid
but wrong* payload: a substituted character (`A106851` → `A106898`), or another
enabled symbology matching part of the bar pattern (`A106852` → `780685`, a
Code 39 pattern read as ITF digits).

`confirmations` is how many decodes, within about a second, must produce the
same `value` + `format` before a result is emitted. The payload must also have
been read more often than **all competing readings combined** in that window:

- While a code is held in view the genuine value is decoded in most frames, so
  an occasional misread is outvoted even though it would eventually reach the
  count.
- When the engine keeps flipping between several values and none has a
  majority, the image is too poor to trust and **nothing is emitted**. No
  result is the intended outcome here; move closer, hold the code flat, or
  improve the light.
- Codes decoded in the same frame are different physical codes, so they never
  compete with each other (`ScanMode.multiBarcode` is unaffected).

| Value | Behavior |
|-------|----------|
| `1` | Emit every decode. Fastest, no protection. |
| `2` (default) | One extra frame interval (~67 ms at `frameRateLimit: 15`). |
| `3` | Recommended for handheld scanning of checksum-free 1D codes. |

The gate runs **before** the duplicate filter and before `ScanMode.single`
stops the pipeline, so a wrong first decode can no longer end the scan.

Limits of the vote:

- A misread that is decoded more often than the real value — a code held at a
  fixed, blurred distance — will still confirm, as will a misread that fills
  the very first frames of a fresh scan. Pair the gate with more pixels per bar
  (`ResolutionPreset.high` / `max`), a code that fills more of the frame, and
  `enableAutoZoom` on Android.
- Moving straight from one code to another with no pause can delay the new
  code by up to about half a second while it overtakes the previous code's
  votes.
- If your payloads follow a known pattern, validate it in your `barcodes`
  listener as a final guard.

**Also restrict `formats` to what you actually scan.** Leaving every symbology
enabled lets ITF/Code 93 claim fragments of a Code 39 pattern:

```dart
ScannerConfiguration(
  formats: {BarcodeFormat.code39},  // not BarcodeFormat.all
  confirmations: 3,
)
```

### Auto-zoom — `enableAutoZoom` (Android)

When enabled, ML Kit reports the zoom ratio needed for a code it has located
but cannot decode because it is too small or too far away, and the camera zooms
to that ratio (clamped to what the lens supports). The zoom stays where it was
left; call `controller.setZoom(0)` to zoom back out. iOS ignores this flag —
Vision has no equivalent.

### Overlay detection highlights

`ScannerOverlay` maps detections with the same fill-and-crop the native preview
uses, and mirrors them for the front camera, so the highlight sits on the code
for any widget aspect ratio.

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
