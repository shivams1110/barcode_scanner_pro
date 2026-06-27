# barcode_scanner_pro

A high-performance, **fully offline** barcode & QR scanner plugin for Flutter.

- **Android** — CameraX + ML Kit (bundled, on-device model), Kotlin, native `PlatformView`.
- **iOS** — AVFoundation + Vision framework, Swift, native `PlatformView`.
- **No commercial SDKs, no third-party camera packages.** The camera preview is
  always rendered natively; Flutter only draws the overlay and controls.

> Flutter 3.35+ · Dart 3+ · Null-safe · Android minSdk 24 · iOS 13+

## Features

- Live native preview via `PlatformView` (never a Flutter camera image)
- 13 symbologies: QR, Code128/39/93, EAN-8/13, UPC-A/E, PDF417, Aztec, DataMatrix, ITF, Codabar
- Scan modes: **single**, **continuous**, **multi-barcode**
- Camera controls: flash/torch, switch camera, pinch-to-zoom, tap-to-focus, exposure
- **Frame skipping** (decode FPS cap) + **duplicate filtering** + **scan-area cropping**
- Configurable Flutter overlay: dark mask, rounded window, corner indicators,
  animated laser, live detection highlights
- Typed error model and a reactive controller (`Stream` + `ValueNotifier`s)
- Automatic app-lifecycle handling (pause on background, resume on foreground)

## Install

```yaml
dependencies:
  barcode_scanner_pro: ^0.1.0
```

### Platform setup

**iOS** — add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan barcodes.</string>
```

**Android** — the `CAMERA` permission is declared by the plugin and merged
automatically. Request it at runtime (see below). minSdk must be ≥ 24.

## Quick start

```dart
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';

final controller = BarcodeScannerController(
  configuration: const ScannerConfiguration(
    formats: {BarcodeFormat.qr, BarcodeFormat.ean13},
    scanMode: ScanMode.continuous,
  ),
);

// 1. Ensure permission (returns true if granted).
await BarcodeScannerPlatform.instance.requestPermission();

// 2. Render the native preview + overlay.
BarcodeScannerView(
  controller: controller,
  overlayBuilder: (context, c) => ScannerOverlay(controller: c),
  onScannerCreated: (c) async {
    await c.initialize();
    await c.start();
  },
);

// 3. Listen for results.
controller.barcodes.listen((r) => print('${r.format.name}: ${r.value}'));

// 4. Always dispose.
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

## Documentation

| Doc | Contents |
|-----|----------|
| [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md) | Layers, data flow, channel design |
| [doc/NATIVE.md](doc/NATIVE.md) | Android (CameraX/ML Kit) & iOS (AVFoundation/Vision) internals |
| [doc/PERFORMANCE.md](doc/PERFORMANCE.md) | Frame skipping, buffers, dedup, tuning |
| [doc/API.md](doc/API.md) | Full public API reference |
| [doc/MIGRATION.md](doc/MIGRATION.md) | Moving from other scanner packages |

## Example

A complete demo app lives in [`example/`](example/) — flash, camera switch, zoom
slider, continuous/QR-only toggles, scan history with copy & open-URL, and a
light/dark theme switch.

## Testing

```bash
flutter test                       # unit + widget tests
flutter test test/benchmark        # parse-throughput benchmark
cd example && flutter test integration_test   # on-device smoke test
```

## License

See [LICENSE](LICENSE).
