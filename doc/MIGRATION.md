# Migration guide

How `barcode_scanner_pro` differs from common scanner packages, and how to port.

## Core differences

| Concept | Typical packages | barcode_scanner_pro |
|---------|------------------|---------------------|
| Preview | Flutter texture / camera widget | **Native `PlatformView`** (no Flutter camera image) |
| Result delivery | callback or future | `Stream<BarcodeResult>` + typed `ValueNotifier`s |
| Errors | strings / generic exceptions | `sealed ScannerException` hierarchy |
| Controls | mixed | unified `BarcodeScannerController` |
| Backend | varies | CameraX+ML Kit (Android), AVFoundation+Vision (iOS), offline |

## From `mobile_scanner`

```dart
// Before
final controller = MobileScannerController();
MobileScanner(
  controller: controller,
  onDetect: (capture) {
    for (final b in capture.barcodes) print(b.rawValue);
  },
);

// After
final controller = BarcodeScannerController(
  configuration: const ScannerConfiguration(scanMode: ScanMode.continuous),
);
BarcodeScannerView(
  controller: controller,
  onScannerCreated: (c) async { await c.initialize(); await c.start(); },
);
controller.barcodes.listen((b) => print(b.value));
```

Mapping:

| mobile_scanner | barcode_scanner_pro |
|----------------|---------------------|
| `controller.toggleTorch()` | `controller.toggleFlash()` |
| `controller.switchCamera()` | `controller.switchCamera()` |
| `Barcode.rawValue` | `BarcodeResult.value` |
| `BarcodeFormat.qrCode` | `BarcodeFormat.qr` |
| `onDetect` callback | `controller.barcodes` stream |
| `MobileScannerController(formats: [...])` | `ScannerConfiguration(formats: {...})` |

## From `qr_code_scanner` / `flutter_barcode_scanner`

Those render their own preview and return via callback/future. Replace the
widget with `BarcodeScannerView`, drive lifecycle through the controller, and
read results from `controller.barcodes`. For a one-shot scan use
`ScanMode.single` and take `controller.barcodes.first`.

## Permissions

Call `BarcodeScannerPlatform.instance.requestPermission()` before
`initialize()`. iOS additionally requires `NSCameraUsageDescription` in
`Info.plist`; Android's `CAMERA` permission is merged from the plugin manifest.

## Scan area & coordinates

Scan area is normalized `[0,1]` over the **upright preview**. `BarcodeResult`
geometry is in image pixels with `imageSize` + `rotation`; use them (as the
bundled overlay does) to map detections to widget space.
