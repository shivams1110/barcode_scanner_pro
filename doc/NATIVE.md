# Native implementation

Both platforms implement the same contract: host a native preview in a
`PlatformView`, run a capture pipeline on a background thread, decode at a capped
frame rate, filter by scan area + duplicates, and stream serialized results on a
per-view event channel.

## Android (Kotlin)

```
ProcessCameraProvider
   ├── Preview            → PreviewView (Hybrid Composition surface)
   └── ImageAnalysis      → background single-thread Executor
        (STRATEGY_KEEP_ONLY_LATEST)        │
                                           ▼
                                   FrameAnalyzer
                                     ├── frame skip (FPS cap)
                                     ├── ML Kit BarcodeScanner.process()
                                     ├── CoordinateMapper (scan-area filter)
                                     ├── ConfirmationGate (multi-frame vote)
                                     ├── DuplicateFilter
                                     └── BarcodeMapper → EventDispatcher
```

Key files (`android/src/main/kotlin/com/umda/barcode_scanner_pro/`):

| File | Role |
|------|------|
| `BarcodeScannerProPlugin.kt` | registers the view factory + global permission channel (`ActivityAware`) |
| `ScannerViewFactory.kt` | creates one `ScannerPlatformView` per `AndroidView` |
| `ScannerPlatformView.kt` | `PlatformView` + `MethodCallHandler` + self-driven `LifecycleOwner` |
| `CameraManager.kt` | CameraX setup + torch/zoom/exposure/focus/switch/capture |
| `FrameAnalyzer.kt` | the decode hot path (`ImageAnalysis.Analyzer`) |
| `ConfirmationGate.kt` | trusts a payload only once it outvotes competing reads across frames |
| `DuplicateFilter`, `CoordinateMapper`, `FormatMapper`, `BarcodeMapper`, `EventDispatcher` | focused helpers |

- **ML Kit** is the `com.google.mlkit:barcode-scanning` dependency (bundled
  model) — fully on-device, no Play Services download, works offline. The
  Flutter `google_mlkit_*` wrapper is **not** used.
- **Coordinates**: given an `InputImage` built with its rotation degrees, ML Kit
  reports geometry in the **upright** image. We forward the upright
  `imageWidth/Height` and `rotation = 0` (same as iOS), and scan-area filtering
  only normalizes each detection's center by the upright size (no per-frame
  bitmap allocation). Do not rotate these points again.
- **Auto-zoom**: with `enableAutoZoom`, the scanner is built with
  `ZoomSuggestionOptions`; the callback applies the suggested ratio through
  `CameraManager.setZoomRatio`, clamped to the lens maximum.
- **Permissions**: `requestPermission` on the global channel uses
  `ActivityCompat.requestPermissions` with a `RequestPermissionsResultListener`.

## iOS (Swift)

```
AVCaptureSession  (configured on a serial DispatchQueue)
   ├── AVCaptureVideoPreviewLayer → PreviewContainerView
   └── AVCaptureVideoDataOutput   → sample-buffer delegate (session queue)
                                           │  CMSampleBuffer
                                           ▼
                                   FrameAnalyzer
                                     ├── frame skip (FPS cap)
                                     ├── VNDetectBarcodesRequest (Vision)
                                     ├── CoordinateMapper (scan-area filter)
                                     ├── ConfirmationGate (multi-frame vote)
                                     ├── DuplicateFilter
                                     └── BarcodeMapper → EventDispatcher
```

Key files (`ios/Classes/`):

| File | Role |
|------|------|
| `BarcodeScannerProPlugin.swift` | registers the view factory + global permission channel |
| `ScannerViewFactory.swift` | creates one `ScannerPlatformView` per `UiKitView` |
| `ScannerPlatformView.swift` | `FlutterPlatformView` + method handler; hosts the preview layer |
| `CameraManager.swift` | session setup + controls + sample-buffer delegate |
| `FrameAnalyzer.swift` | the decode hot path (Vision) |
| helpers | mirror the Android `ConfirmationGate` / `DuplicateFilter` / `CoordinateMapper` / mappers |

- **Vision** runs fully offline. Frames are presented upright via
  `CGImagePropertyOrientation`, so detections come back in oriented space; we
  report `rotation = 0` and the oriented `imageSize`, converting Vision's
  normalized, bottom-left-origin coordinates to pixel, top-left-origin.
- **Threading**: configuration, control mutations, and frame delegation all run
  on a dedicated serial queue; the event sink is marshaled back to main.
- **UPC-A** maps through EAN-13 (Vision has no dedicated UPC-A symbology).

## Cross-platform parity

The confirmation vote, duplicate filter, frame-skip cadence, scan-area semantics,
coordinate convention (upright image, `rotation = 0`), error codes, and
event payload shapes are intentionally identical so the Dart layer is
platform-agnostic.
