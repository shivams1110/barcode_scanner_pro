# Barcode generator — customization and styling guide

All types are exported from `package:barcode_scanner_pro/barcode_scanner_pro.dart`.

Styling is controlled by `BarcodeStyle`, which is passed as the `style` field of
`BarcodeRequest`. `BarcodeWidget` exposes the most common fields as direct props;
it builds an equivalent `BarcodeStyle` internally.

---

## 1. Foreground and background colors

### Via `BarcodeStyle` (for `generate`, `generateBytes`, etc.)

```dart
const gen = BarcodeGenerator();

final result = await gen.generate(
  const BarcodeRequest(
    data: 'https://umda.com',
    format: BarcodeFormat.qr,
    style: BarcodeStyle(
      foreground: Color(0xFF1A237E), // dark indigo modules
      background: Color(0xFFF5F5F5), // near-white background
    ),
  ),
);
```

### Via `BarcodeWidget` props

`BarcodeWidget` accepts `foregroundColor` and `backgroundColor` directly:

```dart
BarcodeWidget(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
  foregroundColor: Color(0xFF1A237E),
  backgroundColor: Color(0xFFF5F5F5),
)
```

Both map to the same `BarcodeStyle.foreground` / `BarcodeStyle.background` fields.

---

## 2. Gradients — `BarcodeGradient` and `GradientType`

`BarcodeGradient` applies a shader across the barcode bounds, replacing the flat
`foreground` color. Provide at least two `colors`; `stops` is optional.

### Via `BarcodeStyle`

```dart
const BarcodeRequest(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  style: BarcodeStyle(
    gradient: BarcodeGradient(
      type: GradientType.linear,
      colors: [Color(0xFF6200EA), Color(0xFF03DAC5)],
      stops: [0.0, 1.0], // optional; evenly distributed when omitted
    ),
  ),
)
```

Available `GradientType` values:

| Value | Effect |
|-------|--------|
| `GradientType.linear` | Left-to-right sweep across the full barcode bounds |
| `GradientType.radial` | Radiates from the centre outward |
| `GradientType.sweep` | Rotates around the centre (clock-hand sweep) |
| `GradientType.none` | Falls back to a linear shader; use `foreground` instead |

### Via `BarcodeWidget` — Flutter `Gradient`

`BarcodeWidget.gradient` accepts any Flutter `Gradient`. The widget maps it
internally:

- `RadialGradient` → `GradientType.radial`
- `SweepGradient` → `GradientType.sweep`
- Anything else (including `LinearGradient`) → `GradientType.linear`

```dart
BarcodeWidget(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
  gradient: const RadialGradient(
    colors: [Color(0xFF6200EA), Color(0xFF03DAC5)],
  ),
)
```

---

## 3. Module shape — `ModuleShape` (QR only)

`moduleShape` controls the visual appearance of each data module in a QR code.
Linear symbologies (Code 128, EAN-13, etc.) ignore this field.

```dart
const BarcodeRequest(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  style: BarcodeStyle(moduleShape: ModuleShape.rounded),
)
```

| Value | Visual appearance |
|-------|-------------------|
| `ModuleShape.square` | Default; sharp-cornered squares fill each cell |
| `ModuleShape.rounded` | Squares with rounded corners; familiar "soft QR" look |
| `ModuleShape.circular` | Each module is a filled circle inscribed in its cell |
| `ModuleShape.diamond` | Each module is a rotated square (45° diamond) |
| `ModuleShape.classy` | Rounded rectangles whose corner radius is controlled by `borderRadius` |

---

## 4. Eye shape and eye color — `EyeShape` (QR only)

The three finder patterns ("eyes") in the corners of a QR code can be styled
independently of the data modules. `eyeShape` and `eyeColor` are ignored by
linear symbologies.

```dart
const BarcodeRequest(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  style: BarcodeStyle(
    moduleShape: ModuleShape.circular,
    eyeShape: EyeShape.leaf,
    eyeColor: Color(0xFF6200EA), // defaults to foreground when omitted
  ),
)
```

| `EyeShape` value | Visual appearance |
|------------------|-------------------|
| `EyeShape.square` | Default; sharp-cornered square finder pattern |
| `EyeShape.rounded` | Finder pattern with rounded outer corners |
| `EyeShape.circular` | Fully circular outer ring |
| `EyeShape.leaf` | Asymmetric tear-drop / leaf silhouette |

`eyeColor` is nullable. When `null`, `BarcodeStyle.effectiveEyeColor` resolves to
`foreground`.

---

## 5. Logo overlay — `BarcodeLogo`

`BarcodeLogo` places a `ui.Image` in the centre of a QR code. It is a QR-only
feature.

```dart
import 'dart:ui' as ui;

// Load your image first, e.g. from assets:
// final ui.Image logoImage = ...

const BarcodeRequest(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  style: BarcodeStyle(
    errorCorrection: ErrorCorrection.quartile, // minimum required — see below
    logo: BarcodeLogo(
      image: logoImage,        // required ui.Image
      sizeRatio: 0.2,          // logo occupies 20% of QR width (default)
      padding: 4,              // logical pixels around the image (default)
      background: Color(0xFFFFFFFF), // plate color behind the logo (default)
    ),
  ),
)
```

`BarcodeLogo` fields:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `image` | `ui.Image` | required | Dispose when no longer needed |
| `sizeRatio` | `double` | `0.2` | Fraction of QR width (0–1) |
| `padding` | `double` | `4` | Logical pixels of padding around the image |
| `background` | `Color` | `Color(0xFFFFFFFF)` | Rounded plate drawn behind the logo |

### Error-correction requirement

A logo occludes part of the QR data. The generator **must** be able to recover
that data via error correction. Setting a logo with `errorCorrection` below
`ErrorCorrection.quartile` throws `BarcodeGenException` at generation time.

```dart
// Throws BarcodeGenException — errorCorrection.medium is below quartile
const BarcodeRequest(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  style: BarcodeStyle(
    errorCorrection: ErrorCorrection.medium, // too low
    logo: BarcodeLogo(image: logoImage),
  ),
)

// Correct — use quartile (Q) or high (H)
const BarcodeRequest(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  style: BarcodeStyle(
    errorCorrection: ErrorCorrection.quartile,
    logo: BarcodeLogo(image: logoImage),
  ),
)
```

Via `BarcodeWidget`, set `errorCorrectionLevel: ErrorCorrection.quartile` (or
`ErrorCorrection.high`) whenever `logo` is non-null.

---

## 6. Quiet zone, error correction, and text rendering

### `quietZone`

The number of QR module widths of blank margin surrounding the barcode. The QR
specification requires a minimum of four; values below four are accepted but may
reduce scanner reliability.

```dart
const BarcodeStyle(quietZone: 4) // default; four modules of margin
```

### `ErrorCorrection`

Controls what fraction of a QR code's data can be reconstructed if modules are
damaged or occluded.

| Enum value | Level label | Recovery capacity |
|------------|-------------|-------------------|
| `ErrorCorrection.low` | L | ~7% |
| `ErrorCorrection.medium` | M | ~15% (default) |
| `ErrorCorrection.quartile` | Q | ~25% |
| `ErrorCorrection.high` | H | ~30% |

Higher correction produces a denser QR code for the same payload. Use
`ErrorCorrection.quartile` or `ErrorCorrection.high` when embedding a logo.

```dart
const BarcodeStyle(errorCorrection: ErrorCorrection.high)
```

In `BarcodeWidget` the equivalent prop is `errorCorrectionLevel`:

```dart
BarcodeWidget(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
  errorCorrectionLevel: ErrorCorrection.high,
)
```

### `showText`, `fontSize`, `fontWeight`

Renders the barcode's human-readable payload as text below the image.

```dart
const BarcodeStyle(
  showText: false,              // default; set true to show the payload string
  fontSize: 12,                 // logical pixels (default)
  fontWeight: FontWeight.normal, // default
)
```

---

## 7. `borderRadius` — classy module rounding (QR only)

`borderRadius` controls the corner radius of the `ModuleShape.classy` module
shape. It does **not** draw a frame or border around the barcode; it only
affects the individual QR module rectangles when `moduleShape` is `classy`.
The field is ignored for all other module shapes and for linear symbologies.

```dart
const BarcodeRequest(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  style: BarcodeStyle(
    moduleShape: ModuleShape.classy,
    borderRadius: 6, // corner radius in logical pixels applied to each module
  ),
)
```

Setting `borderRadius` without `moduleShape: ModuleShape.classy` has no visible
effect.

---

## Field reference

| `BarcodeStyle` field | Type | Default | Effect | QR only? |
|----------------------|------|---------|--------|----------|
| `foreground` | `Color` | `Color(0xFF000000)` | Module/bar color | No |
| `background` | `Color` | `Color(0xFFFFFFFF)` | Canvas fill color | No |
| `gradient` | `BarcodeGradient?` | `null` | Shader replacing flat foreground | No |
| `moduleShape` | `ModuleShape` | `square` | Shape of each data module | Yes |
| `eyeShape` | `EyeShape` | `square` | Shape of finder-pattern eyes | Yes |
| `eyeColor` | `Color?` | `null` (→ `foreground`) | Independent eye color | Yes |
| `borderRadius` | `double` | `0` | Corner radius for `classy` modules only | Yes |
| `quietZone` | `double` | `4` | Modules of blank margin | No |
| `errorCorrection` | `ErrorCorrection` | `medium` | QR error-recovery level; must be ≥ `quartile` when a logo is set | Yes |
| `logo` | `BarcodeLogo?` | `null` | Centre logo overlay | Yes |
| `showText` | `bool` | `false` | Render payload text below barcode | No |
| `fontSize` | `double` | `12` | Text size in logical pixels | No |
| `fontWeight` | `FontWeight` | `FontWeight.normal` | Text weight | No |

---

## See also

- [GENERATOR.md](./GENERATOR.md) — overview and architecture
- [EXPORT.md](./EXPORT.md) — PNG/SVG/PDF export with print DPI
- [PERFORMANCE.md](./PERFORMANCE.md) — batch generation, isolate offloading
- [MIGRATION.md](./MIGRATION.md) — migrating from other generator packages
- [README](../../README.md) — quick-start and installation
