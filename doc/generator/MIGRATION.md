# Barcode generator — migration guide

All types are exported from `package:barcode_scanner_pro/barcode_scanner_pro.dart`.

This guide covers switching to `barcode_scanner_pro`'s built-in barcode generator
from three commonly used packages: `qr_flutter`, `barcode_widget`, and
`pretty_qr_code`. For each package the guide provides a property-mapping table and
before/after code snippets.

---

## Why migrate?

`barcode_scanner_pro` is a **single package** that covers the full barcode
workflow: camera scanning, widget rendering, and image/vector export. Packages
such as `qr_flutter`, `barcode_widget`, and `pretty_qr_code` address only the
rendering half and offer no export formats beyond in-tree painting.

| Capability | `qr_flutter` | `barcode_widget` | `pretty_qr_code` | `barcode_scanner_pro` |
|---|---|---|---|---|
| QR generation | Yes | Yes | Yes | Yes |
| Linear symbologies | No | Yes | No | Yes (Code 128, EAN-13, UPC-A, …) |
| Camera scanning | No | No | No | Yes |
| PNG export | No | No | No | Yes |
| SVG export | No | No | No | Yes |
| PDF export | No | No | No | Yes |
| Static image decode | No | No | No | Yes |

---

## 1. Migrating from `qr_flutter`

### Property mapping

| `qr_flutter` (`QrImageView`) | `barcode_scanner_pro` (`BarcodeWidget`) | Notes |
|---|---|---|
| `data` | `data` | Identical |
| `version` | — | No equivalent; version is selected automatically |
| `errorCorrectionLevel: QrErrorCorrectLevel.L` | `errorCorrectionLevel: ErrorCorrection.low` | See table below |
| `errorCorrectionLevel: QrErrorCorrectLevel.M` | `errorCorrectionLevel: ErrorCorrection.medium` | Default |
| `errorCorrectionLevel: QrErrorCorrectLevel.Q` | `errorCorrectionLevel: ErrorCorrection.quartile` | |
| `errorCorrectionLevel: QrErrorCorrectLevel.H` | `errorCorrectionLevel: ErrorCorrection.high` | |
| `size` | `width` / `height` | Pass the same value to both for a square QR |
| `foregroundColor` | `foregroundColor` | Identical |
| `backgroundColor` | `backgroundColor` | Identical |
| `embeddedImage` | `logo` | Type changes: `ImageProvider` → `ui.Image`; see note below |
| `embeddedImageStyle` | `logoSize` | Pass `embeddedImageStyle.size.width / qrSize` as the `logoSize` fraction |
| `eyeStyle` | `eyeShape` (+ `BarcodeStyle.eyeColor`) | Shape via `EyeShape` enum; eye color via `BarcodeStyle` only |
| `dataModuleStyle` | `moduleShape` | Shape via `ModuleShape` enum |
| `padding` | `padding` | Identical |
| `gapless` | — | No direct equivalent; adjust `quietZone` on `BarcodeWidget` |

#### `QrErrorCorrectLevel` → `ErrorCorrection`

| `qr_flutter` | `barcode_scanner_pro` | Recovery capacity |
|---|---|---|
| `QrErrorCorrectLevel.L` | `ErrorCorrection.low` | ~7% |
| `QrErrorCorrectLevel.M` | `ErrorCorrection.medium` | ~15% (default) |
| `QrErrorCorrectLevel.Q` | `ErrorCorrection.quartile` | ~25% |
| `QrErrorCorrectLevel.H` | `ErrorCorrection.high` | ~30% |

#### Logo / embedded image

`qr_flutter` accepts an `ImageProvider` for `embeddedImage`.
`BarcodeWidget.logo` requires a `dart:ui` `ui.Image`. Load the image from your
asset bundle first, then pass it in:

```dart
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

Future<ui.Image> loadUiImage(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  return (await codec.getNextFrame()).image;
}
```

A logo requires `ErrorCorrection.quartile` or higher. Using a lower level
throws `BarcodeGenException` at generation time.

#### Eye color

`qr_flutter` lets you set eye color directly on `QrEyeStyle`. In
`barcode_scanner_pro` the eye color is a `BarcodeStyle` field (`eyeColor`),
**not** a direct prop of `BarcodeWidget`. Use `BarcodeStyle` + `BarcodeRequest`
via `BarcodeGenerator` when you need an independent eye color:

```dart
const BarcodeRequest(
  data: 'https://example.com',
  format: BarcodeFormat.qr,
  style: BarcodeStyle(
    eyeColor: Color(0xFF6200EA), // independent eye color
    eyeShape: EyeShape.rounded,
    moduleShape: ModuleShape.circular,
  ),
)
```

### Before / after snippets

**Before (qr_flutter)**

```dart
import 'package:qr_flutter/qr_flutter.dart';

QrImageView(
  data: 'https://example.com',
  version: QrVersions.auto,
  errorCorrectionLevel: QrErrorCorrectLevel.H,
  size: 200,
  foregroundColor: Color(0xFF1A237E),
  eyeStyle: QrEyeStyle(
    eyeShape: QrEyeShape.circle,
    color: Color(0xFF6200EA),
  ),
  dataModuleStyle: QrDataModuleStyle(
    dataModuleShape: QrDataModuleShape.circle,
    color: Color(0xFF1A237E),
  ),
  embeddedImage: AssetImage('assets/logo.png'),
  embeddedImageStyle: QrEmbeddedImageStyle(size: Size(40, 40)),
)
```

**After (barcode_scanner_pro)**

```dart
import 'dart:ui' as ui;
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';

// logo must be a ui.Image loaded before rendering (see above)
// Eye color requires BarcodeStyle; use BarcodeGenerator.generate() for
// that specific field, or omit it and let eye color default to foregroundColor.

BarcodeWidget(
  data: 'https://example.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
  foregroundColor: Color(0xFF1A237E),
  errorCorrectionLevel: ErrorCorrection.high,
  moduleShape: ModuleShape.circular,
  eyeShape: EyeShape.circular,
  logo: logoImage,           // ui.Image loaded at startup
  logoSize: 0.2,             // 20% of QR width (default)
)
```

---

## 2. Migrating from `barcode_widget`

The `barcode_widget` package exports a widget also named `BarcodeWidget`. The
primary structural difference is that `barcode_widget` selects the symbology via
a factory object (`Barcode.code128()`), while `barcode_scanner_pro` uses the
`BarcodeFormat` enum.

### Property mapping

| `barcode_widget` (`BarcodeWidget`) | `barcode_scanner_pro` (`BarcodeWidget`) | Notes |
|---|---|---|
| `barcode: Barcode.code128()` | `format: BarcodeFormat.code128` | See format table below |
| `data` | `data` | Identical |
| `width` / `height` | `width` / `height` | Identical |
| `color` | `foregroundColor` | |
| `background` | `backgroundColor` | |
| `drawText` | `showText` | |
| `textStyle` | `fontSize` / `fontWeight` | No full `TextStyle`; font size and weight only |
| `margin` (double) | `padding` (EdgeInsets) | Wrap a uniform margin in `EdgeInsets.all(margin)` |
| — | `moduleShape` | New — QR only |
| — | `eyeShape` | New — QR only |
| — | `gradient` | New — any Flutter `Gradient` |
| — | `logo` | New — QR only |

#### `Barcode.*` → `BarcodeFormat.*`

| `barcode_widget` factory | `BarcodeFormat` |
|---|---|
| `Barcode.code128()` | `BarcodeFormat.code128` |
| `Barcode.code39()` | `BarcodeFormat.code39` |
| `Barcode.code93()` | `BarcodeFormat.code93` |
| `Barcode.ean13()` | `BarcodeFormat.ean13` |
| `Barcode.ean8()` | `BarcodeFormat.ean8` |
| `Barcode.upcA()` | `BarcodeFormat.upcA` |
| `Barcode.upcE()` | `BarcodeFormat.upcE` |
| `Barcode.itf()` | `BarcodeFormat.itf` |
| `Barcode.codabar()` | `BarcodeFormat.codabar` |
| `Barcode.pdf417()` | `BarcodeFormat.pdf417` |
| `Barcode.aztec()` | `BarcodeFormat.aztec` |
| `Barcode.dataMatrix()` | `BarcodeFormat.dataMatrix` |
| `Barcode.qrCode()` | `BarcodeFormat.qr` |

> **Note:** `barcode_widget` supports several symbologies not yet supported by
> the `barcode_scanner_pro` generator (e.g. ISBN, Telepen, RM4SCC). For those
> formats there is currently no equivalent. Continue using `barcode_widget` for
> those specific formats until support is added.

### Before / after snippets

**Before (barcode_widget)**

```dart
import 'package:barcode_widget/barcode_widget.dart';

BarcodeWidget(
  barcode: Barcode.code128(),
  data: 'Hello-123',
  width: 300,
  height: 100,
  color: Colors.black,
  drawText: true,
  margin: 8,
)
```

**After (barcode_scanner_pro)**

```dart
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';

BarcodeWidget(
  format: BarcodeFormat.code128,
  data: 'Hello-123',
  width: 300,
  height: 100,
  foregroundColor: Colors.black,
  showText: true,
  padding: EdgeInsets.all(8),
)
```

---

## 3. Migrating from `pretty_qr_code`

`pretty_qr_code` is a styling-focused QR renderer. Its visual options map
closely to `BarcodeStyle` in `barcode_scanner_pro`.

### Property mapping

| `pretty_qr_code` | `barcode_scanner_pro` | Notes |
|---|---|---|
| `PrettyQrView(qrImage:, decoration:)` | `BarcodeWidget(data:, format: BarcodeFormat.qr, …)` | No separate image object |
| `PrettyQrDecoration(shape:)` | `moduleShape` / `eyeShape` on `BarcodeWidget` | See shape table below |
| `PrettyQrDecoration(image:)` | `logo` | Type changes: `PrettyQrDecorationImage` → `ui.Image` via `logo` + `logoSize` |
| `PrettyQrDecoration(gradient:)` | `gradient` | Pass any Flutter `Gradient` to `BarcodeWidget.gradient` |
| `PrettyQrRoundedSymbol` | `ModuleShape.rounded` or `ModuleShape.circular` | Closest visual match |
| `PrettyQrSmoothSymbol` | `ModuleShape.rounded` | Closest visual match |
| `PrettyQrDecoration` eye color | `BarcodeStyle.eyeColor` | Via `BarcodeStyle` only, not a direct `BarcodeWidget` prop |
| — | `eyeShape` | `EyeShape.square / rounded / circular / leaf` |

> **Parity note:** `pretty_qr_code` allows separate gradient colors for eyes vs.
> data modules. `barcode_scanner_pro` applies a single gradient across the full
> barcode bounds and colors eyes independently via `BarcodeStyle.eyeColor`. There
> is no per-region gradient split equivalent.

### Before / after snippets

**Before (pretty_qr_code)**

```dart
import 'package:pretty_qr_code/pretty_qr_code.dart';

PrettyQrView.data(
  data: 'https://example.com',
  decoration: PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      color: Color(0xFF1A237E),
    ),
    image: PrettyQrDecorationImage(
      image: AssetImage('assets/logo.png'),
    ),
  ),
)
```

**After (barcode_scanner_pro)**

```dart
import 'dart:ui' as ui;
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';

// logo must be a ui.Image (see section 1 for loading helper)

BarcodeWidget(
  data: 'https://example.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
  foregroundColor: Color(0xFF1A237E),
  moduleShape: ModuleShape.rounded,
  errorCorrectionLevel: ErrorCorrection.quartile, // required when logo is set
  logo: logoImage,
)
```

**Styled QR with gradient (before)**

```dart
PrettyQrView.data(
  data: 'https://example.com',
  decoration: PrettyQrDecoration(
    shape: PrettyQrRoundedSymbol(),
    gradient: LinearGradient(
      colors: [Color(0xFF6200EA), Color(0xFF03DAC5)],
    ),
  ),
)
```

**Styled QR with gradient (after)**

```dart
BarcodeWidget(
  data: 'https://example.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
  moduleShape: ModuleShape.rounded,
  gradient: LinearGradient(
    colors: [Color(0xFF6200EA), Color(0xFF03DAC5)],
  ),
)
```

---

## See also

- [GENERATOR.md](GENERATOR.md) — construction, output methods, named helpers, validation
- [CUSTOMIZATION.md](CUSTOMIZATION.md) — colors, gradients, module shapes, logos, animation
- [EXPORT.md](EXPORT.md) — SVG, PDF, batch, and file-save APIs
- [doc/PERFORMANCE.md](../PERFORMANCE.md) — scanner and generator tuning
- [README](../../README.md) — quick-start and installation
