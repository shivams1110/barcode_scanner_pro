# Barcode generator — core usage guide

All types are exported from `package:barcode_scanner_pro/barcode_scanner_pro.dart`.

---

## 1. Construction and `generate`

`BarcodeGenerator` is a `const`-constructible facade. Instantiate it once and
reuse it — all state lives in the immutable `BarcodeRequest`.

```dart
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';

const gen = BarcodeGenerator();

final result = await gen.generate(
  const BarcodeRequest(
    data: '4006381333931',
    format: BarcodeFormat.ean13,
  ),
);
// result.pngBytes  — Uint8List PNG
// result.uiImage   — ui.Image (dispose when done)
// result.pixelSize — Size in device pixels
// result.format    — BarcodeFormat.ean13
```

`BarcodeRequest` fields:

| Field | Type | Default |
|-------|------|---------|
| `data` | `String` | required |
| `format` | `BarcodeFormat` | required |
| `style` | `BarcodeStyle` | `const BarcodeStyle()` |
| `options` | `BarcodeOptions` | `const BarcodeOptions()` |

`generate` throws `BarcodeGenException` when `data` is empty.

---

## 2. Output methods

### PNG bytes

```dart
final Uint8List bytes = await gen.generateBytes(
  const BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
  ),
);
```

### `ui.Image`

```dart
import 'dart:ui' as ui;

final ui.Image img = await gen.generateImage(
  const BarcodeRequest(data: 'HELLO', format: BarcodeFormat.code128),
);
// remember to call img.dispose() when done
```

### Base64

```dart
final String b64 = await gen.toBase64(
  const BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
);
// useful for embedding in HTML: 'data:image/png;base64,$b64'
```

### `BarcodeGenResult` convenience conversions

```dart
final result = await gen.generate(
  const BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
);

final String base64     = result.toBase64();
final MemoryImage mi    = result.toMemoryImage();
final ImageProvider ip  = result.toImageProvider(); // equivalent MemoryImage, typed as ImageProvider
```

Use `toMemoryImage()` / `toImageProvider()` to feed the PNG directly into
Flutter image widgets without an extra copy:

```dart
Image(image: result.toImageProvider())
```

---

## 3. `BarcodeWidget` — in-tree rendering

`BarcodeWidget` is a `StatelessWidget` that paints the barcode via a
`CustomPainter`. It avoids the async round-trip of `generate` and repaints only
when the resolved `BarcodeRequest` changes.

```dart
BarcodeWidget(
  data: 'https://karnival.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
  moduleShape: ModuleShape.rounded,
  eyeShape: EyeShape.circular,
  errorCorrectionLevel: ErrorCorrection.high,
)
```

Key props:

| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `data` | `String` | required | |
| `format` | `BarcodeFormat` | required | |
| `width` / `height` | `double?` | 200 / auto | QR defaults square; linear defaults 120 h |
| `foregroundColor` | `Color` | `Colors.black` | |
| `backgroundColor` | `Color` | `Colors.white` | |
| `moduleShape` | `ModuleShape` | `square` | QR only: `square/rounded/circular/diamond/classy` |
| `eyeShape` | `EyeShape` | `square` | QR only: `square/rounded/circular/leaf` |
| `errorCorrectionLevel` | `ErrorCorrection` | `medium` | QR only: `low/medium/quartile/high` |
| `quietZone` | `double` | `4` | modules of margin |
| `gradient` | `Gradient?` | `null` | Flutter `LinearGradient`, `RadialGradient`, or `SweepGradient` |
| `logo` | `ui.Image?` | `null` | QR only |
| `logoSize` | `double` | `0.2` | fraction of QR side |
| `showText` | `bool` | `false` | human-readable text below barcode |
| `animation` | `Duration?` | `null` | fade-in on first render |
| `padding` | `EdgeInsets` | `EdgeInsets.zero` | |

For full styling details see [CUSTOMIZATION.md](CUSTOMIZATION.md).

---

## 4. Named QR-payload helpers

All nine helpers are `static` methods on `BarcodeGenerator` that return a
`BarcodeRequest` with `format: BarcodeFormat.qr`.

### `url`

```dart
final req = BarcodeGenerator.url('https://karnival.com');
// data: 'https://karnival.com'
```

### `text`

```dart
final req = BarcodeGenerator.text('Hello, world!');
// data: 'Hello, world!'
```

### `phone`

```dart
final req = BarcodeGenerator.phone('+14155552671');
// data: 'tel:+14155552671'
```

### `sms`

```dart
final req = BarcodeGenerator.sms('+14155552671', message: 'On my way');
// data: 'SMSTO:+14155552671:On my way'
```

### `email`

```dart
final req = BarcodeGenerator.email(
  'hi@example.com',
  subject: 'Hello',
  body: 'Nice to meet you',
);
// data: 'mailto:hi@example.com?subject=Hello&body=Nice%20to%20meet%20you'
```

### `wifi`

`password` is optional — omit it (or pass `null`) for open networks.

```dart
// Password-protected network
final req = BarcodeGenerator.wifi(
  ssid: 'MyNetwork',
  password: 'secret',
  security: 'WPA',   // default
  hidden: false,     // default
);
// data: 'WIFI:T:WPA;S:MyNetwork;P:secret;H:false;;'

// Open network (no password)
final open = BarcodeGenerator.wifi(ssid: 'Guest', security: 'nopass');
// data: 'WIFI:T:nopass;S:Guest;P:;H:false;;'
```

### `contact` (vCard 3.0)

```dart
final req = BarcodeGenerator.contact({
  'name':    'Jane Doe',
  'org':     'Acme Corp',
  'phone':   '+14155552671',
  'email':   'jane@acme.com',
  'url':     'https://acme.com',
  'address': '123 Main St',
});
// data starts with 'BEGIN:VCARD\nVERSION:3.0\n...\nEND:VCARD'
```

Supported field keys: `name`, `org`, `title`, `phone`, `email`, `url`, `address`.

### `calendar` (iCalendar VEVENT)

```dart
final req = BarcodeGenerator.calendar({
  'summary':     'Team standup',
  'location':    'Room 4B',
  'start':       '20260701T090000Z',
  'end':         '20260701T093000Z',
  'description': 'Daily sync',
});
// data starts with 'BEGIN:VEVENT\n...\nEND:VEVENT'
```

Supported field keys: `summary`, `location`, `start`, `end`, `description`.

### `location`

```dart
final req = BarcodeGenerator.location(37.7749, -122.4194);
// data: 'geo:37.7749,-122.4194'
```

---

## 5. `BarcodeValidator`

`BarcodeValidator` is an `abstract final` class — all methods are `static`.

```dart
// EAN / UPC structural validation (length + all-digits + check digit)
BarcodeValidator.isValidEAN13('4006381333931'); // true
BarcodeValidator.isValidEAN8('96385074');       // true
BarcodeValidator.isValidUPC('012345678905');    // true

// Charset validation (delegates to the barcode package)
BarcodeValidator.isValidCode128('Hello 123');   // true
BarcodeValidator.isValidCode39('HELLO-123');    // true (uppercase only)
BarcodeValidator.isValidCode39('hello');        // false (lowercase not in Code 39)
```

### `calculateChecksum`

Returns the single check digit (0–9) for the **data portion** (all digits
before the check digit) of an EAN-13, EAN-8, or UPC-A barcode.

```dart
// EAN-13: pass the first 12 digits, get back the 13th
final int check = BarcodeValidator.calculateChecksum(
  BarcodeFormat.ean13,
  '400638133393', // 12-digit data, no check digit
);
// check == 1  →  full barcode: '4006381333931'
```

**Important:** `calculateChecksum` only supports the GS1 mod-10 numeric family
(`ean13`, `ean8`, `upcA`). Calling it for any other format — including
`code128`, `code39`, or `qr` — throws `BarcodeGenException`:

```dart
// throws BarcodeGenException: 'No standalone numeric checksum for code128'
BarcodeValidator.calculateChecksum(BarcodeFormat.code128, 'ABC');
```

---

## 6. `decodeImage` — static image decode

`decodeImage` is an instance method on `BarcodeGenerator`:

```dart
// BarcodeGenerator.decodeImage(Uint8List bytes, {Set<BarcodeFormat>? formats})
final gen = BarcodeGenerator();
final codes = await gen.decodeImage(bytes);
```

Decodes all barcodes found in a PNG or JPEG buffer using the native ML Kit
(Android) or Vision (iOS) framework. Returns an empty list when no codes are
found.

```dart
import 'dart:typed_data';
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';

const gen = BarcodeGenerator();

// Generate a QR, then decode it back
final png = await gen.generateBytes(
  BarcodeGenerator.url('https://karnival.com'),
);
final List<BarcodeDecodeResult> codes = await gen.decodeImage(png);

print(codes.first.value);  // 'https://karnival.com'
print(codes.first.format); // BarcodeFormat.qr
```

Restrict to a subset of symbologies with the `formats` filter:

```dart
// Only look for EAN-13; QR codes in the same image are ignored
final codes = await gen.decodeImage(
  png,
  formats: {BarcodeFormat.ean13},
);
```

`BarcodeDecodeResult` fields:

| Field | Type | Notes |
|-------|------|-------|
| `value` | `String` | decoded payload |
| `format` | `BarcodeFormat` | reported symbology |
| `rawBytes` | `Uint8List?` | raw bytes from native (may be null) |
| `cornerPoints` | `List<Offset>?` | image-pixel coordinates (may be null) |

**Error cases:**

- Empty `bytes` → throws `BarcodeGenException('decodeImage requires non-empty image bytes')`.
- Image contains no barcodes → returns an empty list (no exception).

**Platform caveats:**

- **iOS UPC-A**: iOS Vision has no dedicated UPC-A symbology. A physical UPC-A
  barcode in an image will decode with `format == BarcodeFormat.ean13` on iOS;
  Android ML Kit reports `BarcodeFormat.upcA` correctly.
- **Codabar on iOS**: requires iOS 15+.

See [doc/DECODE_VERIFICATION.md](../DECODE_VERIFICATION.md) for the manual
on-device verification checklist.

---

## 7. Supported formats

| Symbology | `BarcodeFormat` | Type | Generator | `decodeImage` |
|-----------|-----------------|------|-----------|---------------|
| QR Code | `qr` | 2D | Yes | Yes |
| Code 128 | `code128` | 1D | Yes | Yes |
| Code 39 | `code39` | 1D | Yes | Yes |
| Code 93 | `code93` | 1D | — | Yes |
| EAN-8 | `ean8` | 1D | Yes | Yes |
| EAN-13 | `ean13` | 1D | Yes | Yes |
| UPC-A | `upcA` | 1D | Yes | Yes* |
| UPC-E | `upcE` | 1D | — | Yes |
| PDF417 | `pdf417` | 2D | — | Yes |
| Aztec | `aztec` | 2D | — | Yes |
| Data Matrix | `dataMatrix` | 2D | — | Yes |
| ITF | `itf` | 1D | — | Yes |
| Codabar | `codabar` | 1D | — | Yes** |

\* iOS Vision reports UPC-A as `ean13`; see [section 6](#6-decodeimage--static-image-decode).
\*\* Codabar decoding on iOS requires iOS 15+.

### Output-types matrix

| Method | Returns | Format |
|--------|---------|--------|
| `generate` | `BarcodeGenResult` | PNG + `ui.Image` + metadata |
| `generateBytes` | `Uint8List` | PNG |
| `generateImage` | `ui.Image` | raster (dispose when done) |
| `toBase64` | `String` | base64-encoded PNG |
| `BarcodeGenResult.toBase64()` | `String` | base64-encoded PNG |
| `BarcodeGenResult.toMemoryImage()` | `MemoryImage` | Flutter `ImageProvider` |
| `BarcodeGenResult.toImageProvider()` | `ImageProvider` | Flutter `ImageProvider` |
| `generateSvg` | `String` | SVG markup |
| `generatePdf` | `Uint8List` | PDF bytes |
| `save` / `saveAsPNG` / `saveAsSVG` / `saveAsPDF` | `File` | file on disk |

---

## See also

- [CUSTOMIZATION.md](./CUSTOMIZATION.md) — module shapes, eye shapes, gradients, logos
- [EXPORT.md](./EXPORT.md) — PNG/SVG/PDF export with print DPI
- [PERFORMANCE.md](./PERFORMANCE.md) — batch generation, isolate offloading
- [MIGRATION.md](./MIGRATION.md) — migrating from other generator packages
- [README](../../README.md) — quick-start and installation
