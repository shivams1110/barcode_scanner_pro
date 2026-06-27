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
