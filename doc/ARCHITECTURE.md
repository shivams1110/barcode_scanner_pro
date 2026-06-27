# Architecture

`barcode_scanner_pro` follows a layered, dependency-inverted design. The public
Flutter API depends on an **abstract platform interface**, never on a concrete
channel — which keeps the controller unit-testable and the transport swappable.

## Layers (Dart)

```
barcode_scanner_pro.dart            public barrel export
│
├── domain/         pure value types: BarcodeResult, formats, modes, states
├── config/         ScannerConfiguration, ScanArea  (+ toMap serialization)
├── error/          ScannerException sealed hierarchy + stable error codes
├── platform/       Channels, BarcodeScannerPlatform (abstract),
│                   MethodChannelBarcodeScanner (default impl), ScannerEvent
├── controller.dart BarcodeScannerController  (app-facing, reactive)
├── scanner_view.dart  BarcodeScannerView  (PlatformView host + gestures)
└── overlay/        ScannerOverlay + CustomPainters
```

**Dependency direction:** `controller → platform interface ← method channel`.
The controller receives a `BarcodeScannerPlatform` (default
`BarcodeScannerPlatform.instance`) by constructor injection. Tests inject a fake.

## Channel design

Channels are **scoped per PlatformView id** so multiple scanners never collide:

| Channel | Name | Purpose |
|---------|------|---------|
| Method (per view) | `…/methods/<id>` | commands: initialize, start, controls… |
| Event (per view)  | `…/events/<id>`  | stream: detections, lifecycle, control echoes |
| Method (global)   | `…/global`       | permission check/request (needs Activity) |

Names live in exactly one Dart file (`channels.dart`) and are mirrored verbatim
in `Constants.kt` / `Constants.swift`.

## Data flow

```
                 ┌─────────────── Flutter ───────────────┐
 BarcodeScannerView (PlatformView host)                  │
   │ creationParams = config.toMap()                     │
   ▼                                                     │
 native view created → controller.attach(viewId)         │
   │                                                     │
   ├── MethodChannel  ──► initialize/start/controls       │
   └── EventChannel    ◄── ScannerEvent stream            │
        │                                                 │
        ▼                                                 │
 controller fans out → barcodes Stream + ValueNotifiers   │
                 └─────────────────────────────────────────┘

 Native (per platform):
   Camera ► Analysis use case ► background queue ► detector
          ► frame-skip ► scan-area filter ► duplicate filter
          ► serialize ► EventChannel
```

## Event model

Native always sends a map with a `type` discriminator. `ScannerEvent.fromMap`
decodes it into a sealed type (`BarcodesEvent`, `FlashChangedEvent`,
`ErrorEvent`, …). The controller pattern-matches and updates its reactive
surface. Unknown types decode to `null` and are dropped defensively.

## Lifecycle

- **App background/foreground** — the controller is a `WidgetsBindingObserver`;
  it pauses decoding on background and resumes if it was scanning.
- **Native lifecycle** — Android binds CameraX to a self-driven `LifecycleOwner`
  on the PlatformView; iOS manages the `AVCaptureSession` on a serial queue and
  reacts to device-orientation notifications.
- **Dispose** — `controller.dispose()` cancels the event subscription, calls
  native `dispose` (releasing the camera), and disposes all notifiers/streams.

## SOLID notes

- **S** — one responsibility per class (`DuplicateFilter`, `CoordinateMapper`,
  `FrameAnalyzer`, `CameraManager`, `EventDispatcher` are all separate).
- **O/L** — `BarcodeScannerPlatform` is the extension point; alternative
  implementations substitute cleanly (used by tests).
- **D** — the controller depends on the abstraction, not the channel.
