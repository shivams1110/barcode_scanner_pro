import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../error/barcode_gen_exception.dart';
import '../models/barcode_request.dart';
import 'barcode_renderer.dart';

/// Rasterizes a [BarcodeRequest] to a [ui.Image] and PNG bytes at the request's
/// DPI-scaled pixel size. Allocates exactly one image at the target resolution.
class RasterExporter {
  const RasterExporter();

  static const BarcodeRenderer _renderer = BarcodeRenderer();

  Future<({ui.Image image, Uint8List png, Size pixelSize})> rasterize(
    BarcodeRequest request,
  ) async {
    final edge = request.options.pixelSize;
    final pixels = Size(edge, edge);
    final w = edge.floor();
    final h = edge.floor();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _renderer.paint(canvas, pixels, request);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    picture.dispose();

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw BarcodeGenException('Failed to encode PNG', format: request.format);
    }
    return (
      image: image,
      png: byteData.buffer.asUint8List(),
      pixelSize: pixels,
    );
  }
}
