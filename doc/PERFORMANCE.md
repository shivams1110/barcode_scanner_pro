# Performance guide

Targets: **preview ~60 FPS**, **decode ≤ 15 FPS** (configurable), UI thread never
blocked.

## Techniques used

### 1. Decouple preview from decode
The preview use case (`Preview` / `AVCaptureVideoPreviewLayer`) runs at the
camera's native rate. Decoding is a *separate* path that throttles itself.

### 2. Frame skipping
`FrameAnalyzer` records the timestamp of the last decoded frame and drops any
frame arriving within `1000 / frameRateLimit` ms. Dropped frames are released
immediately (Android `imageProxy.close()`, iOS early `return`) so buffers recycle.

```dart
const ScannerConfiguration(frameRateLimit: 10); // decode at most 10 fps
```

### 3. Latest-frame backpressure
Android uses `ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST`; iOS sets
`alwaysDiscardsLateVideoFrames = true`. The analyzer always sees the freshest
frame and never builds a backlog.

### 4. No per-frame allocation on the hot path
- The detector (`BarcodeScanner` / `VNDetectBarcodesRequest`) is created **once**
  and reused.
- Scan-area containment is computed with arithmetic on the detection's center —
  **no cropped bitmap is allocated per frame**.
- The duplicate filter is a single map keyed by `format:value`, lazily pruned.

### 5. Background execution
Decoding runs on a dedicated single-thread executor (Android) / serial dispatch
queue (iOS). Results are marshaled to the main thread only to cross the event
channel.

### 6. Duplicate filtering
Identical detections within `duplicateTimeout` are suppressed natively, so the
event channel and your Dart code aren't spammed in continuous mode.

```dart
const ScannerConfiguration(duplicateTimeout: Duration(milliseconds: 1500));
```

### 7. Scan-area cropping
Restricting `scanArea` makes the analyzer ignore detections outside the window —
fewer events, no accidental scans, and the user gets a clear target.

## Tuning cheatsheet

| Goal | Setting |
|------|---------|
| Lower battery / heat | `frameRateLimit: 8–10`, `resolution: ResolutionPreset.low` |
| Dense / small codes (PDF417) | `resolution: ResolutionPreset.high` |
| Fewer repeat events | raise `duplicateTimeout` |
| Snappier continuous UX | lower `duplicateTimeout`, `frameRateLimit: 20` |
| Tight target box | `scanArea: ScanArea.centeredSquare(fraction: 0.6)` |

## Measuring

`flutter test test/benchmark/parse_benchmark.dart` measures Dart-side event
decode throughput (a regression guard). For end-to-end FPS, profile on a real
device with the platform's GPU/CPU tools — emulators do not reflect camera
throughput.
