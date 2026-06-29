# Barcode generator — performance guide

All types are exported from `package:barcode_scanner_pro/barcode_scanner_pro.dart`.

---

## 1. `BarcodeWidget` repaint discipline

`BarcodeWidget` uses a `CustomPainter` whose `shouldRepaint` compares the
resolved `BarcodeRequest` by **value equality**. A repaint is triggered only
when at least one of `data`, `format`, `style`, or `options` actually changes.
Rebuilds that produce an identical request — for example a parent widget
rebuilding with the same props — do not repaint the canvas.

```dart
// These two builds produce the same BarcodeRequest; the canvas never repaints.
BarcodeWidget(
  data: 'https://umda.com',
  format: BarcodeFormat.qr,
  width: 200,
  height: 200,
)
```

### `animation: null` — zero animation overhead

When `animation` is `null` (the default), no `AnimationController` is created
and no ticker is registered. The widget is entirely static after its first paint.
Only pass a `Duration` when you specifically want the fade-in entrance animation.

```dart
// No AnimationController, no ticker — pure static paint.
const BarcodeWidget(
  data: '4006381333931',
  format: BarcodeFormat.ean13,
)
```

### Internal `RepaintBoundary`

`BarcodeWidget` wraps its `CustomPaint` in a `RepaintBoundary`. Ancestor
rebuilds do not dirty the rasterized barcode layer. You do not need to add your
own `RepaintBoundary`.

---

## 2. Batch generation — `generateBatch`

`generateBatch` is designed for generating hundreds of barcodes at a time while
keeping the UI responsive.

```dart
const gen = BarcodeGenerator();

final List<BarcodeGenResult> results = await gen.generateBatch(
  requests,           // List<BarcodeRequest> — results are returned in input order
  concurrency: 8,     // optional; default is 4
);
```

### Bounded concurrency

`concurrency` (default `4`) controls how many renders run concurrently inside
each window. Raising it to `8` increases throughput on devices with spare CPU
headroom. Setting it below `1` is clamped to `1`.

### LRU cache — duplicate requests render once

A per-call `RenderCache` (capacity 256) is created automatically. If the same
`BarcodeRequest` appears more than once in `requests`, only the first occurrence
is rendered; subsequent occurrences are served from the cache. Cache lookup is
keyed by value equality on `BarcodeRequest`, so two structurally identical
requests always share a cached result.

Note: within a single concurrent window, two identical requests could both miss
the cache and render twice (best-effort de-dup, not a lock). If guaranteed
de-duplication is required, place duplicates in later positions in `requests` or
use a lower `concurrency`.

### Event-loop yield between groups

After each window of `concurrency` renders completes, `generateBatch` yields to
the event loop via `Future.delayed(Duration.zero)`. This allows Flutter to
schedule a frame and keep the UI responsive during long catalog runs.

### Result order

Results are always returned in **input order** regardless of which futures
resolve first.

---

## 3. DPI cost — pixel area scales with dpi²

The rasterized pixel dimension is calculated by `BarcodeOptions`:

```
pixelSize = size * (dpi / 96) * scale
```

Because the barcode is square (or approximately square for linear codes), the
total pixel **area** scales with the square of the DPI ratio:

| DPI | `pixelSize` (size=200) | Area relative to 96 DPI |
|-----|------------------------|--------------------------|
| 96 (default) | 200 px | 1× |
| 300 | 625 px | ~10× |
| 600 | 1 250 px | ~42× |
| 1200 | 2 500 px | ~168× |

Doubling DPI doubles the linear dimension and **quadruples** the pixel area.
300 → 600 DPI is a 4× increase in pixels, not 2×.

**Guidance:**

- Use `dpi: 300` for screen-sized print output and most label/receipt printers.
  It provides high visual quality at reasonable memory and encode time.
- Use `dpi: 600` only for high-quality print production (commercial printing,
  label stock with fine detail).
- Use `dpi: 1200` only for archival or large-format prepress work. Expect
  significantly higher memory allocation and encode time.
- Leave `dpi` at the default `96` for on-screen display — using `BarcodeWidget`
  or screen-resolution `generateBytes` is more appropriate anyway.

---

## 4. Vector vs. raster output

### Linear codes — true vector

SVG and PDF output for **linear codes** (Code 128, EAN-13, UPC-A, Code 39, EAN-8,
etc.) is fully vector. The `barcode` package's `toSvg` emits true vector
geometry (filled paths) with no raster allocation. The output scales to any
resolution without pixellation and is compact in file size.

Prefer SVG for linear codes whenever the output will be scaled or embedded in a
context that can render SVG.

### QR codes — single high-DPI PNG

QR SVG and PDF output embeds **one high-DPI PNG** (a single `ui.Image`
allocation) inside the vector container. This is intentional: QR modules carry
fine styling (rounded shapes, eye variants, gradients, logos) computed by
Flutter's `Canvas` layer that cannot be faithfully re-encoded as path-per-module
SVG without an order-of-magnitude size increase and fidelity loss.

The resolution of the embedded PNG is controlled by `BarcodeExportOptions.svgDpi`
(default `300`) for SVG and `BarcodeExportOptions.pdfDpi` (default `300`) for PDF.
Only one `ui.Image` is allocated per QR export regardless of the output container.

---

## 5. General guidance

| Scenario | Recommendation |
|----------|---------------|
| On-screen display | Use `BarcodeWidget` — no raster allocation, no async round-trip, repaints only on data change |
| Single PNG | `gen.generateBytes(req)` with `dpi: 300`; use `dpi: 96` for screen-only output |
| Large catalog (100+ codes) | `gen.generateBatch(requests, concurrency: 8)` — LRU cache, bounded concurrency, UI-responsive |
| Scalable linear output | `gen.generateSvg(req)` — vector, zero DPI concern |
| High-DPI QR print | `gen.generateSvg(req, options: BarcodeExportOptions(svgDpi: 600))` — one PNG at target DPI |
| Reusing the generator | `const BarcodeGenerator()` — stateless, safe to share; all state is in `BarcodeRequest` |

### Reuse `const BarcodeGenerator()`

`BarcodeGenerator` is stateless. Declare it once as a `const` field or top-level
constant and share it across the app. Creating a new instance per generation
call is harmless but unnecessary.

```dart
// Declare once
const gen = BarcodeGenerator();

// Use everywhere
final result = await gen.generate(req);
final List<BarcodeGenResult> batch = await gen.generateBatch(requests);
```

### Prefer `BarcodeWidget` over rasterizing for on-screen display

`generateBytes` + `Image.memory` allocates a PNG buffer, decodes it into a
texture, and uploads it to the GPU. `BarcodeWidget` paints directly to the
`Canvas` without any intermediate buffer. For live or frequently-updated
on-screen barcodes, `BarcodeWidget` is always the lower-overhead choice.

---

## See also

- [GENERATOR.md](./GENERATOR.md) — overview and architecture
- [CUSTOMIZATION.md](./CUSTOMIZATION.md) — module shapes, eye shapes, gradients, logos
- [EXPORT.md](./EXPORT.md) — PNG/SVG/PDF export with print DPI
- [MIGRATION.md](./MIGRATION.md) — migrating from other generator packages
- [README](../../README.md) — quick-start and installation
