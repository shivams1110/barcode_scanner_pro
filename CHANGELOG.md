## Unreleased

**Barcode & QR Code Generator module**

* Offline generation of all 13 symbologies (`BarcodeFormat` — QR, Code128,
  Code39, Code93, EAN-8, EAN-13, UPC-A, UPC-E, PDF417, Aztec, DataMatrix,
  ITF, Codabar).
* Styled QR codes: five module shapes (`ModuleShape`), four eye shapes
  (`EyeShape`), four error-correction levels (`ErrorCorrection`), foreground
  gradients (`GradientType`), and embedded logo support (`BarcodeLogo`).
* Export to PNG raster (`generateBytes`, `generateImage`), SVG vector
  (`generateSvg`), and multi-page print-ready PDF (`generatePdf`) at
  300/600/1200 DPI with configurable grid or label layouts.
* Batch generation via `generateBatch` for high-throughput label pipelines.
* Input validation helpers (`BarcodeValidator`) for EAN-13, EAN-8, UPC-A,
  UPC-E, and other checksum-bearing symbologies.
* Named QR payload helpers on `BarcodeGenerator`: `url`, `text`, `phone`,
  `sms`, `email`, `wifi`, `contact`, `calendar`, and `location`.
* Native image decode contract (`BarcodeDecodeResult`) — Phase 3b native body
  to follow.
* `BarcodeWidget` — drop-in Flutter widget for inline barcode display with
  full style support.

## 0.1.0

Initial release.

* Native camera preview via `PlatformView` on Android (CameraX + ML Kit, bundled
  offline model) and iOS (AVFoundation + Vision). No commercial or third-party
  camera/scanner SDKs.
* 13 symbologies: QR, Code128/39/93, EAN-8/13, UPC-A/E, PDF417, Aztec,
  DataMatrix, ITF, Codabar.
* Scan modes: single, continuous, multi-barcode.
* Camera controls: flash/torch, camera switch, pinch-to-zoom, tap-to-focus,
  exposure, frame capture.
* Performance: frame skipping (decode FPS cap), latest-frame backpressure,
  duplicate filtering, scan-area cropping, background decoding, reused detector.
* Reactive `BarcodeScannerController` (`Stream` + `ValueNotifier`s), sealed
  `ScannerException` hierarchy, automatic app-lifecycle handling.
* Configurable Flutter overlay (mask, rounded window, corners, animated laser,
  live detection highlights).
* Example app, unit/widget/integration tests, parse benchmark, and full docs.
