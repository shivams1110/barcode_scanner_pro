## 0.4.0

**Misread protection**

* Added `ScannerConfiguration.confirmations` (default `2`): a payload must
  decode that many times within about a second, and more often than all
  competing readings combined, before it is emitted. When the decoder flips
  between values with no majority, nothing is emitted.
  Fixes wrong values from checksum-free symbologies (Code 39, Code 93, ITF,
  Codabar), where a blurred or clipped frame decodes into a structurally valid
  but incorrect payload — a substituted character, or another enabled
  symbology matching part of the bar pattern.
* The gate runs ahead of the duplicate filter and ahead of `ScanMode.single`'s
  stop, so a wrong first decode no longer ends the scan.
* New `ConfirmationGate` on Android (Kotlin, unit-tested) and iOS (Swift).

**Auto-zoom (Android)**

* `enableAutoZoom` was accepted but had no effect. It now enables ML Kit zoom
  suggestions, zooming in on codes that are located but too small to decode.
  iOS ignores the flag.

**Fixes**

* Android: detections were dropped when a `scanArea` was set. ML Kit reports
  geometry in the upright image, and the scan-area check rotated it a second
  time, so a centered code on a portrait device fell outside the area. Android
  now reports upright image dimensions and `rotation = 0`, matching iOS.
* Overlay: detection highlights were stretched to the widget instead of
  following the preview's fill-and-crop, so they were offset from the code.
  They are also mirrored for the front camera now.
* iOS: the preview layer created by `initialize` was never resized with its
  view and could stay at zero size.

**`ResolutionPreset.max` now means highest available**

* `max` previously resolved to 1080p — identical to `high` — on both platforms.
  Android now uses `ResolutionStrategy.HIGHEST_AVAILABLE_STRATEGY`; iOS tries
  `.hd4K3840x2160` and falls back to 1080p when the session refuses it.
* Matters for checksum-free 1D symbologies: too few pixels per narrow bar makes
  the decoder shift a wide-element boundary onto its neighbour, producing a
  valid-but-wrong payload instead of a failed scan.

## 0.3.0

**Scan-accept feedback**

* Added on-device beep + haptic tick fired on each accepted barcode
  detection, via a native `FeedbackController` on Android and iOS.
* Throttled to 200ms to avoid pile-ups in continuous/multi-barcode modes.
* Wired into the platform-view emission path and disposed with the view.
* `enableSound` now defaults to `true` across Dart/Android/iOS config.
* Android manifest now declares the `VIBRATE` permission.

**Licensing**

* Added MIT license.

## 0.2.0

**Expanded symbology support — 22 formats**

* Added 9 symbologies to `BarcodeFormat`: GS1-128, ITF-14, ITF-16, EAN-5,
  EAN-2, ISBN, Telepen, RM4SCC, and POSTNET (was 13, now 22).
* All new formats are supported for **generation** across PNG, SVG, and PDF
  export paths.
* Native scanners (ML Kit / Vision): GS1-128, ITF-14, ITF-16, and ISBN are
  detected via their parent symbology (Code128, ITF, EAN-13 respectively), so
  a scan reports the parent format. EAN-2, EAN-5, Telepen, RM4SCC, and POSTNET
  are **generate-only** — the engines cannot detect them.
* New `BarcodeFormat.scannable`, `BarcodeFormat.generateOnly`, and
  `isScannable` so consumers can distinguish scannable from generate-only
  formats.

**Tooling**

* Added GitHub Actions CI: strict `dart format`, `flutter analyze`,
  `flutter test` with coverage, plus Android and iOS example builds on every
  push and pull request.

**Barcode & QR Code Generator module**

* Offline generation of all linear/2D symbologies (`BarcodeFormat`).
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
