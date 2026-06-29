import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../domain/barcode_format.dart';
import 'barcode_request.dart';

/// The product of [BarcodeGenerator.generate]: a rasterized PNG plus the live
/// [ui.Image] and metadata. Named distinctly from the scanner's `BarcodeResult`.
class BarcodeGenResult {
  const BarcodeGenResult({
    required this.pngBytes,
    required this.uiImage,
    required this.pixelSize,
    required this.format,
    required this.request,
  });

  /// Encoded PNG bytes.
  final Uint8List pngBytes;

  /// Live raster image (caller may dispose when done).
  final ui.Image uiImage;

  /// Rasterized dimensions in device pixels.
  final Size pixelSize;

  final BarcodeFormat format;
  final BarcodeRequest request;

  /// PNG encoded as a base64 string.
  String toBase64() => base64Encode(pngBytes);

  /// A [MemoryImage] backed by [pngBytes].
  MemoryImage toMemoryImage() => MemoryImage(pngBytes);

  /// Same as [toMemoryImage], typed as the broader [ImageProvider].
  ImageProvider toImageProvider() => MemoryImage(pngBytes);
}
