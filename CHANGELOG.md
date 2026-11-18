## 0.5.0

**Auto-zoom**

* iOS: `enableAutoZoom` now works. Vision has no zoom suggestion, so a code
  covering under 25% of the frame is zoomed to about 50%, capped so an
  off-centre code is not pushed out of view.
* iOS: auto-zoom now also reaches codes too small to decode. Vision only
  reports codes it has already decoded — a far 1D code produced no signal, so
  auto-zoom never fired for it. While nothing is found in the scan area for
  1.5s, the camera now flips between 2x and the starting zoom. A manual zoom
  (pinch or slider) stops the flipping for the session.
* iOS: with `enableAutoZoom` on, capture is at least 1080p, so far codes have
  enough pixels per bar for Vision to decode.
* Android: ML Kit is now told the lens' max zoom ratio; without it zoom
  suggestions fired only sometimes.
* Android: auto-zoom refocuses on the centre right after zooming instead of
  waiting for continuous autofocus, so the zoomed code decodes sooner.
* Both: zoom resets on each start/resume (to 1x, or the iOS minimum zoom
  below), so a near code after a far one is not stuck over-zoomed.
* Both: auto-zoom now emits `zoomChanged`, so `controller.zoom` (and a zoom
  slider bound to it) follows auto-zoom and ML Kit's own reset to 1x.
* Android: the ML Kit scanner is now closed on dispose.
* Example: `frameRateLimit: 30` so auto-zoom and confirmations settle sooner.
* iOS: with `enableAutoZoom` on, autofocus is no longer restricted to near
  distances, so the distant codes auto-zoom targets can come into focus.

**Scan accuracy**

* Both: the scan area now matches what the user sees. The aspect-fill preview
  crops the camera frame (on a tall phone a 4:3 frame loses ~40% of its
  width), but detections were checked against the uncropped frame, so codes
  outside the drawn box, or off-screen, were accepted.
* Both: EAN-13, EAN-8, UPC-A and UPC-E now go through `confirmations` like
  other checksum-light symbologies. A single mod-10 check digit still lets
  misreads through (e.g. a partial EAN-13 decoded as UPC-E). Costs about one
  frame. QR, Data Matrix, Aztec, PDF417 and Code 128 still emit on first read.
* iOS: Vision is no longer pinned to request revision 3 on iOS 17+, which was
  a downgrade from the OS default.

**Focus (iOS)**

* Tap-to-focus no longer locks focus and exposure until the next restart; it
  re-centres on the tapped point and keeps tracking, so codes at other
  distances still come into focus.
* Close codes are sharp on lenses with a long minimum focus distance (iPhone
  13 Pro and later, ~20cm). Following Apple's AVCamBarcode approach, the back
  camera starts zoomed just enough that a code filling the scan area sits at
  the focus limit. Zoom value `0` (slider start) now means this minimum zoom.
  iOS 15+.

**Duplicate filtering**

* `duplicateTimeout` now restarts on every sighting: a code held in view emits
  once instead of re-emitting (and beeping) every timeout. Move it out of view
  for `duplicateTimeout` to scan it again.

**Stability (iOS)**

* Frames are decoded on their own queue, so torch, zoom and focus changes no
  longer wait behind a slow Vision pass.
* Camera settings (torch, exposure, zoom, focus) are skipped instead of
  applied when the device lock fails, which raised an Objective-C exception.

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
