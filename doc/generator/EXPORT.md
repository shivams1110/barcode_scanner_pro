# Barcode generator — export guide

All types are exported from `package:barcode_scanner_pro/barcode_scanner_pro.dart`.

---

## 1. PNG export

### `generateBytes` / `saveAsPNG`

`generateBytes` returns a `Uint8List` containing encoded PNG bytes.
`saveAsPNG` writes those bytes to a file and returns the `File`.

```dart
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';

const gen = BarcodeGenerator();

// In-memory PNG bytes
final Uint8List bytes = await gen.generateBytes(
  const BarcodeRequest(
    data: '4006381333931',
    format: BarcodeFormat.ean13,
  ),
);

// Write to file
final File file = await gen.saveAsPNG(
  const BarcodeRequest(
    data: '4006381333931',
    format: BarcodeFormat.ean13,
  ),
  '/output/ean13.png',
);
```

### Resolution — DPI and pixel size

The physical dimensions of the rasterized image are controlled by three
`BarcodeOptions` fields: `size`, `dpi`, and `scale`. The resulting pixel
dimension is:

```
pixelSize = size * (dpi / 96) * scale
```

`size` is the logical edge length in points (base-96 reference density). `dpi`
scales that to the target print resolution. `scale` is an additional multiplier
(useful for device-pixel-ratio overrides).

| Use case | `dpi` value | Example: `size = 200` |
|----------|-------------|----------------------|
| Screen display | `96` (default) | 200 px |
| Standard print | `300` | 625 px |
| High-quality print | `600` | 1 250 px |
| Archival / prepress | `1200` | 2 500 px |

```dart
// 300 DPI print-ready PNG
final Uint8List printPng = await gen.generateBytes(
  const BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
    options: BarcodeOptions(
      size: 200,
      dpi: 300,   // pixelSize = 200 * (300/96) * 1.0 = 625 px
    ),
  ),
);

// 600 DPI for high-resolution printing
final Uint8List hiResPng = await gen.generateBytes(
  const BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
    options: BarcodeOptions(
      size: 200,
      dpi: 600,   // pixelSize = 200 * (600/96) * 1.0 = 1 250 px
    ),
  ),
);
```

### Transparent background

Set `transparentBackground: true` in `BarcodeOptions` to produce a PNG with an
alpha-0 background. Modules are drawn on a fully transparent canvas.

```dart
final Uint8List transparent = await gen.generateBytes(
  const BarcodeRequest(
    data: '012345678905',
    format: BarcodeFormat.upcA,
    options: BarcodeOptions(
      dpi: 300,
      transparentBackground: true,
    ),
  ),
);
```

### Rotation

`rotationDegrees` rotates the rendered barcode clockwise. Accepted values are
typically `0`, `90`, `180`, or `270`.

```dart
final Uint8List rotated = await gen.generateBytes(
  const BarcodeRequest(
    data: 'HELLO',
    format: BarcodeFormat.code128,
    options: BarcodeOptions(rotationDegrees: 90),
  ),
);
```

---

## 2. SVG export

### `generateSvg` / `saveAsSVG`

`generateSvg` returns the SVG markup as a `String`.
`saveAsSVG` writes that string to a file and returns the `File`.

```dart
const gen = BarcodeGenerator();

// SVG markup string
final String svg = await gen.generateSvg(
  const BarcodeRequest(
    data: '012345678905',
    format: BarcodeFormat.upcA,
  ),
);

// Write to file
final File svgFile = await gen.saveAsSVG(
  const BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
  ),
  '/output/qr.svg',
);
```

### Vector vs. embedded-PNG

**Linear codes** (Code 128, EAN-13, UPC-A, Code 39, etc.) produce **true
vector** SVG. Every bar and quiet-zone rectangle is an SVG `<rect>` element;
the output scales without any pixellation at any zoom level.

**QR codes** embed a **high-DPI PNG** inside the SVG `<image>` element rather
than emitting vector paths. This is intentional: QR modules carry fine styling
(rounded shapes, eye variants, gradients, logos) that is computed by Flutter's
`Canvas` layer. Re-encoding that styling as path-per-module SVG would produce
files an order of magnitude larger and would lose fidelity for gradient and
logo overlays. Embedding a high-DPI raster preserves the visual quality while
keeping the file compact.

### `BarcodeExportOptions.svgDpi` — embedded-QR resolution

`svgDpi` controls the resolution of the PNG embedded inside a QR SVG. The
default is `300`, which is sufficient for most display and moderate print uses.
Raise it for high-resolution print output.

```dart
// Higher-DPI embedded PNG for a QR SVG destined for print
final String printSvg = await gen.generateSvg(
  const BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
    options: BarcodeOptions(size: 200),
  ),
  options: const BarcodeExportOptions(svgDpi: 600),
);
```

`svgDpi` has no effect on linear-code SVG (which is always pure vector).

---

## 3. PDF export

### `generatePdf` / `saveAsPDF`

`generatePdf` accepts a **list** of `BarcodeRequest`s and returns `Uint8List`
PDF bytes. `saveAsPDF` writes those bytes to a file and returns the `File`.

```dart
const gen = BarcodeGenerator();

// Single QR, default layout (single per A4 page)
final Uint8List pdfBytes = await gen.generatePdf(
  const [BarcodeRequest(data: 'https://karnival.com', format: BarcodeFormat.qr)],
);

// Write to file
final File pdfFile = await gen.saveAsPDF(
  const [BarcodeRequest(data: '4006381333931', format: BarcodeFormat.ean13)],
  '/output/ean13.pdf',
);
```

### Layout — `BarcodePdfLayout`

The `layout` parameter controls how codes are arranged across pages.
`BarcodePdfLayout` has **six** named constructors:

#### `single()` — one code centred on an A4 page

```dart
final Uint8List pdf = await gen.generatePdf(
  const [BarcodeRequest(data: 'https://karnival.com', format: BarcodeFormat.qr)],
  layout: const BarcodePdfLayout.single(),
);
```

#### `grid({columns, rows})` — columns×rows grid flowed across A4 pages

Default is 3 columns × 4 rows. Pass the `requests` list with more items than
`columns * rows` to flow across multiple pages automatically.

```dart
final Uint8List pdf = await gen.generatePdf(
  const [
    BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
    BarcodeRequest(data: '4006381333931', format: BarcodeFormat.ean13),
    BarcodeRequest(data: 'HELLO', format: BarcodeFormat.code128),
  ],
  layout: const BarcodePdfLayout.grid(columns: 2, rows: 4),
);
```

#### `label({widthMm, heightMm})` — one code per physical label

Creates a page sized to exact millimetre dimensions — one barcode per page.
Useful when printing to dedicated label stock where each page is one label.

```dart
final Uint8List pdf = await gen.generatePdf(
  const [BarcodeRequest(data: '96385074', format: BarcodeFormat.ean8)],
  // 62 mm × 29 mm label (e.g. Brother DK-11209)
  layout: BarcodePdfLayout.label(widthMm: 62, heightMm: 29),
);
```

Note: `label()` is not `const` because the mm-to-points arithmetic is computed
at runtime.

#### `thermal()` — standard 58 mm thermal roll (const)

The zero-argument form produces a 58 mm × 58 mm page with 2 mm margins —
suitable for most standard thermal receipt printers.

```dart
final Uint8List pdf = await gen.generatePdf(
  const [BarcodeRequest(data: 'https://karnival.com', format: BarcodeFormat.qr)],
  layout: const BarcodePdfLayout.thermal(),
);
```

#### `thermalWide({widthMm})` — thermal roll with custom width

When the roll width is not 58 mm, use `thermalWide`. The page height matches
the width (square page) with 2 mm margins.

```dart
final Uint8List pdf = await gen.generatePdf(
  const [BarcodeRequest(data: 'HELLO', format: BarcodeFormat.code128)],
  layout: BarcodePdfLayout.thermalWide(widthMm: 80), // 80 mm wide roll
);
```

Note: `thermalWide()` is not `const` for the same reason as `label()`.

#### `a4({columns, rows})` — grid tuned for A4 label sheets

Default is 3 columns × 8 rows (24 labels per sheet). The page format is A4.

```dart
final Uint8List pdf = await gen.generatePdf(
  skus, // List<BarcodeRequest>
  layout: const BarcodePdfLayout.a4(columns: 3, rows: 8),
);
```

#### `custom({pageFormat, columns, rows})` — caller-supplied format and grid

Supply any `PdfPageFormat` (re-exported from `package:pdf`). `columns` and
`rows` default to 1.

```dart
import 'package:pdf/pdf.dart';

final Uint8List pdf = await gen.generatePdf(
  requests,
  layout: const BarcodePdfLayout.custom(
    pageFormat: PdfPageFormat.letter, // US Letter
    columns: 3,
    rows: 5,
  ),
);
```

### Layout constructor reference

| Constructor | `const`? | Page format | Columns | Rows |
|-------------|----------|-------------|---------|------|
| `single()` | Yes | A4 | 1 | 1 |
| `grid({columns, rows})` | Yes | A4 | 3 (default) | 4 (default) |
| `label({widthMm, heightMm})` | No | exact mm | 1 | 1 |
| `thermal()` | Yes | 58×58 mm | 1 | 1 |
| `thermalWide({widthMm})` | No | widthMm×widthMm | 1 | 1 |
| `a4({columns, rows})` | Yes | A4 | 3 (default) | 8 (default) |
| `custom({pageFormat, columns, rows})` | Yes | caller-supplied | 1 (default) | 1 (default) |

### Vector vs. embedded-PNG in PDF

Consistent with SVG export:

- **Linear codes** are rendered as vector `pw.BarcodeWidget` elements inside
  the PDF. They scale without pixellation.
- **QR codes** are embedded as a PNG raster inside the PDF page.

### `BarcodeExportOptions.pdfDpi` and `cellPadding`

`pdfDpi` controls the resolution of QR PNG images embedded in the PDF
(default: `300`). `cellPadding` adds logical-pixel padding around each barcode
within its layout cell (default: `8`).

```dart
final Uint8List pdf = await gen.generatePdf(
  requests,
  layout: const BarcodePdfLayout.grid(columns: 3, rows: 4),
  options: const BarcodeExportOptions(
    pdfDpi: 600,        // higher-DPI QR raster for print quality
    cellPadding: 12,    // extra spacing around each code
  ),
);
```

### Multi-barcode pagination

Pass a list longer than `columns * rows` (available via `layout.perPage`) and
the renderer automatically flows codes across multiple pages.

```dart
// 24 barcodes on a 3×8 A4 sheet → 1 page; 25 barcodes → 2 pages
final List<BarcodeRequest> batch = List.generate(
  50,
  (i) => BarcodeRequest(data: 'ITEM-${i.toString().padLeft(4, '0')}', format: BarcodeFormat.code128),
);

final Uint8List pdf = await gen.generatePdf(
  batch,
  layout: const BarcodePdfLayout.a4(columns: 3, rows: 8), // perPage = 24
);
// pdf contains 3 pages (50 codes / 24 per page, rounded up)
```

---

## 4. Extension-dispatch save

`save(request, path)` inspects the file extension and dispatches to the
appropriate export method. It accepts a single `BarcodeRequest`.

```dart
const gen = BarcodeGenerator();

// Dispatches by extension:
await gen.save(req, '/output/code.png');  // → saveAsPNG
await gen.save(req, '/output/code.svg');  // → saveAsSVG
await gen.save(req, '/output/code.pdf');  // → saveAsPDF([req])
```

An unrecognised extension throws `BarcodeGenException`:

```dart
// Throws BarcodeGenException: 'Unsupported file extension for "code.bmp" (use .png, .svg, or .pdf)'
await gen.save(req, '/output/code.bmp');
```

Extension matching is case-insensitive (`.PNG`, `.Svg`, `.PDF` all work).

---

## 5. Other output forms

### Base64

`toBase64` generates a barcode and returns the PNG bytes encoded as a base64
string. Useful for embedding in HTML `<img>` tags or JSON payloads.

```dart
final String b64 = await gen.toBase64(
  const BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
  ),
);
// Embed in HTML:
// <img src="data:image/png;base64,$b64" />
```

`BarcodeGenResult.toBase64()` performs the same encoding on an already-generated
result without a second network/disk round-trip:

```dart
final result = await gen.generate(req);
final String base64 = result.toBase64();
```

### `MemoryImage` / `ImageProvider`

`BarcodeGenResult` provides two convenience conversions that produce Flutter
`ImageProvider` objects backed by the in-memory PNG bytes — no file I/O needed.

```dart
final result = await gen.generate(
  const BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA),
);

final MemoryImage mi   = result.toMemoryImage();
final ImageProvider ip = result.toImageProvider(); // same MemoryImage, typed as ImageProvider

// Use directly in an Image widget:
Image(image: result.toImageProvider())
```

Both methods return a `MemoryImage` backed by `result.pngBytes`. They differ
only in their declared return type.

---

## Which format when

| Scenario | Recommended format | Reason |
|----------|-------------------|--------|
| On-screen widget / UI display | `BarcodeWidget` (in-tree) or PNG via `generateBytes` | Fast, no disk I/O, resolves at device DPI |
| Web embed / JSON payload | Base64 PNG via `toBase64` | Single string, no file handle required |
| Flutter image widget (`Image`) | `MemoryImage` via `toMemoryImage()` | No file round-trip; compatible with `Image(image:)` |
| Print — general purpose | PNG at `dpi: 300` or `600` | Raster is universal across printers and RIPs |
| Print — scalable / future-proof | SVG (linear codes) | True vector; scales to any resolution without re-generation |
| Print — QR at high quality | SVG with `BarcodeExportOptions(svgDpi: 600)` | High-DPI PNG embedded in SVG container |
| Multi-code label sheets | PDF with `BarcodePdfLayout.a4` or `.grid` | Page flow and margin handling built in |
| Individual label stock | PDF with `BarcodePdfLayout.label(widthMm:, heightMm:)` | Exact physical dimensions per label |
| Thermal receipt printer | PDF with `BarcodePdfLayout.thermal()` or `.thermalWide(widthMm:)` | Roll-width page format; automatic pagination |
| Archival / pre-press | PNG at `dpi: 1200` | Maximum raster fidelity; broadly supported |

---

## See also

- [GENERATOR.md](GENERATOR.md) — construction, output methods, named helpers, validation
- [CUSTOMIZATION.md](CUSTOMIZATION.md) — colors, gradients, module shapes, logos, animation
- [doc/PERFORMANCE.md](../PERFORMANCE.md) — scanner and generator tuning
- [doc/MIGRATION.md](../MIGRATION.md) — version upgrade notes
- [README](../../README.md) — quick-start and installation
