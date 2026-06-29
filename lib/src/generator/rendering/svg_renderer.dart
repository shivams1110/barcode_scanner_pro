import 'dart:convert';

import 'package:barcode/barcode.dart' as bc;

import '../../domain/barcode_format.dart';
import '../../error/barcode_gen_exception.dart';
import '../models/barcode_request.dart';
import '../models/export_options.dart';
import 'linear_painter.dart' show barcodeFor;
import 'raster_exporter.dart';

/// Renders a [BarcodeRequest] to a standalone SVG document string.
///
/// Linear and non-QR 2D codes are emitted as true vector via the `barcode`
/// package's [bc.Barcode.toSvg]; QR codes embed the high-DPI PNG raster as a
/// base64 `<image>` element to preserve all QR styling.
///
/// API note (barcode 2.2.9): [bc.Barcode.toSvg] accepts a native [int] `color`
/// parameter (`0xRRGGBB`, default `0x000000`). The SVG it emits uses
/// `style="fill: #rrggbb"` — NOT `fill="black"`. The native `color` param is
/// therefore used directly rather than post-processing the SVG string.
class SvgRenderer {
  const SvgRenderer();

  static const RasterExporter _exporter = RasterExporter();

  /// Returns a standalone SVG string for [request].
  ///
  /// For QR codes, [options.svgDpi] controls the raster resolution of the
  /// embedded PNG image.
  Future<String> render(
    BarcodeRequest request, {
    BarcodeExportOptions options = const BarcodeExportOptions(),
  }) async {
    if (request.format == BarcodeFormat.qr) {
      return _qrSvg(request, options);
    }
    return _linearSvg(request);
  }

  String _linearSvg(BarcodeRequest request) {
    final symbology = barcodeFor(request.format);
    final style = request.style;
    final size = request.options.size;
    // barcode 2.2.9: toSvg accepts `int color` in 0xRRGGBB form.
    // Color.toARGB32() returns 0xAARRGGBB; mask off the alpha byte.
    final colorInt = style.foreground.toARGB32() & 0xFFFFFF;
    try {
      return symbology.toSvg(
        request.data,
        width: size,
        height: size / 2.5,
        drawText: style.showText,
        color: colorInt,
      );
    } on bc.BarcodeException catch (e) {
      throw BarcodeGenException(e.message, format: request.format);
    }
  }

  Future<String> _qrSvg(
    BarcodeRequest request,
    BarcodeExportOptions options,
  ) async {
    final dpiRequest = request.copyWith(
      options: request.options.copyWith(dpi: options.svgDpi),
    );
    final out = await _exporter.rasterize(dpiRequest);
    final b64 = base64Encode(out.png);
    final side = request.options.size;
    return '<svg xmlns="http://www.w3.org/2000/svg" width="$side" '
        'height="$side" viewBox="0 0 $side $side">'
        '<image href="data:image/png;base64,$b64" '
        'width="$side" height="$side"/></svg>';
  }
}
