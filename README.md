# barcode_scanner_pro

A high-performance, **fully offline** barcode & QR scanner plugin for Flutter.

- **Android** — CameraX + ML Kit (bundled, on-device model), Kotlin, native `PlatformView`.
- **iOS** — AVFoundation + Vision framework, Swift, native `PlatformView`.
- **No commercial SDKs, no third-party camera packages.** The camera preview is
  always rendered natively; Flutter only draws the overlay and controls.

> Flutter 3.35+ · Dart 3+ · Null-safe · Android minSdk 24 · iOS 13+

## Features

- Live native preview via `PlatformView` (never a Flutter camera image)
- 22 symbologies: QR, Code128/39/93, EAN-8/13, UPC-A/E, PDF417, Aztec, DataMatrix, ITF, Codabar, GS1-128, ITF-14/16, EAN-5/2, ISBN, Telepen, RM4SCC, POSTNET (9 generate-focused formats added in 0.2.0)
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
  barcode_scanner_pro: ^0.2.0
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

## Barcode & QR Code Generation

`barcode_scanner_pro` ships a complete, **fully offline** barcode and QR code
generator alongside its scanner. You can produce PNG, SVG, or print-ready PDF
output (300/600/1200 DPI), style QR codes with custom module shapes, eye
shapes, gradients, and logos, run batch jobs, validate common symbologies, and
decode barcodes from native images — all with the same package import, no extra
dependencies.

### Supported formats

| Format | `BarcodeFormat` value | Type | Generate | Scan |
|--------|----------------------|------|----------|------|
| QR Code | `qr` | QR | ✅ | ✅ |
| Code 128 | `code128` | 1D | ✅ | ✅ |
| Code 39 | `code39` | 1D | ✅ | ✅ |
| Code 93 | `code93` | 1D | ✅ | ✅ |
| EAN-8 | `ean8` | 1D | ✅ | ✅ |
| EAN-13 | `ean13` | 1D | ✅ | ✅ |
| UPC-A | `upcA` | 1D | ✅ | ✅ |
| UPC-E | `upcE` | 1D | ✅ | ✅ |
| PDF417 | `pdf417` | 2D | ✅ | ✅ |
| Aztec | `aztec` | 2D | ✅ | ✅ |
| Data Matrix | `dataMatrix` | 2D | ✅ | ✅ |
| ITF | `itf` | 1D | ✅ | ✅ |
| Codabar | `codabar` | 1D | ✅ | ✅ |
| GS1-128 | `gs128` | 1D | ✅ | as `code128` |
| ITF-14 | `itf14` | 1D | ✅ | as `itf` |
| ITF-16 | `itf16` | 1D | ✅ | as `itf` |
| ISBN | `isbn` | 1D | ✅ | as `ean13` |
| EAN-5 | `ean5` | 1D | ✅ | — |
| EAN-2 | `ean2` | 1D | ✅ | — |
| Telepen | `telepen` | 1D | ✅ | — |
| RM4SCC | `rm4scc` | 1D | ✅ | — |
| POSTNET | `postnet` | 1D | ✅ | — |

> **Scan column:** native scanners (ML Kit / Vision) have no dedicated detector
> for GS1-128, ITF-14/16, and ISBN, so a scan reports the parent symbology shown.
> EAN-5, EAN-2, Telepen, RM4SCC, and POSTNET are generate-only (—) — the engines
> cannot detect them. Use `BarcodeFormat.scannable` / `.generateOnly` to filter.

### Quick start

**(a) Generate a QR code as PNG bytes**

```dart
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';

const gen = BarcodeGenerator();

final bytes = await gen.generateBytes(
  const BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
  ),
);
```

**(b) Display a barcode inline with `BarcodeWidget`**

```dart
BarcodeWidget(
  data: 'https://karnival.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
)
```

**(c) Styled QR with rounded modules, circular eyes, and high error correction**

```dart
BarcodeWidget(
  data: 'https://karnival.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
  moduleShape: ModuleShape.rounded,
  eyeShape: EyeShape.circular,
  errorCorrectionLevel: ErrorCorrection.high,
)
```

### Output types

- `Uint8List` — PNG raster bytes (via `generateBytes`)
- `ui.Image` — Flutter image object (via `generateImage`)
- `String` — base64-encoded PNG (via `BarcodeGenResult.toBase64()`)
- `MemoryImage` / `ImageProvider` — drop-in widget image (via `BarcodeGenResult.toMemoryImage()`)
- `String` — SVG markup (via `generateSvg`)
- `Uint8List` — PDF bytes, single or batch grid layout (via `generatePdf`)

### Guides

- [doc/generator/GENERATOR.md](doc/generator/GENERATOR.md) — overview and architecture
- [doc/generator/CUSTOMIZATION.md](doc/generator/CUSTOMIZATION.md) — module shapes, eye shapes, gradients, logos
- [doc/generator/EXPORT.md](doc/generator/EXPORT.md) — PNG/SVG/PDF export with print DPI
- [doc/generator/PERFORMANCE.md](doc/generator/PERFORMANCE.md) — batch generation, isolate offloading
- [doc/generator/MIGRATION.md](doc/generator/MIGRATION.md) — migrating from other generator packages

## License

See [LICENSE](LICENSE).
