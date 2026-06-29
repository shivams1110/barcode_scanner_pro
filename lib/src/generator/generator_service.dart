import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show PlatformException;

import '../domain/barcode_format.dart';
import '../error/barcode_gen_exception.dart';
import '../platform/barcode_scanner_platform.dart';
import 'batch/batch_generator.dart';
import 'batch/render_cache.dart';
import 'helpers/qr_payloads.dart';
import 'models/barcode_decode_result.dart';
import 'models/barcode_gen_result.dart';
import 'models/barcode_request.dart';
import 'models/export_options.dart';
import 'models/pdf_layout.dart';
import 'rendering/pdf_renderer.dart';
import 'rendering/raster_exporter.dart';
import 'rendering/svg_renderer.dart';
import 'validators/barcode_validator.dart';

/// Facade for generating barcodes/QR codes. Phase-1 methods are implemented;
/// methods belonging to later phases throw [UnimplementedError] but keep the
/// public surface stable.
class BarcodeGenerator {
  const BarcodeGenerator({
    RasterExporter exporter = const RasterExporter(),
    SvgRenderer svgRenderer = const SvgRenderer(),
    PdfRenderer pdfRenderer = const PdfRenderer(),
  })  : _exporter = exporter,
        _svgRenderer = svgRenderer,
        _pdfRenderer = pdfRenderer;

  final RasterExporter _exporter;
  final SvgRenderer _svgRenderer;
  final PdfRenderer _pdfRenderer;

  /// Generates a barcode and returns PNG bytes, the live image, and metadata.
  Future<BarcodeGenResult> generate(BarcodeRequest request) async {
    if (request.data.isEmpty) {
      throw const BarcodeGenException('data must not be empty');
    }
    final out = await _exporter.rasterize(request);
    return BarcodeGenResult(
      pngBytes: out.png,
      uiImage: out.image,
      pixelSize: out.pixelSize,
      format: request.format,
      request: request,
    );
  }

  /// PNG bytes only.
  Future<Uint8List> generateBytes(BarcodeRequest request) async =>
      (await generate(request)).pngBytes;

  /// Live [ui.Image] only.
  Future<ui.Image> generateImage(BarcodeRequest request) async =>
      (await generate(request)).uiImage;

  /// Base64-encoded PNG.
  Future<String> toBase64(BarcodeRequest request) async =>
      (await generate(request)).toBase64();

  /// Writes PNG to [path] and returns the file.
  Future<File> saveAsPNG(BarcodeRequest request, String path) async {
    final bytes = await generateBytes(request);
    return _writeBytes(path, bytes);
  }

  Future<File> _writeBytes(String path, Uint8List bytes) async {
    try {
      await _ensureParentDir(path);
      return File(path).writeAsBytes(bytes);
    } on FileSystemException catch (e) {
      throw BarcodeGenException('Failed to write "$path": ${e.message}');
    }
  }

  Future<File> _writeString(String path, String contents) async {
    try {
      await _ensureParentDir(path);
      return File(path).writeAsString(contents);
    } on FileSystemException catch (e) {
      throw BarcodeGenException('Failed to write "$path": ${e.message}');
    }
  }

  Future<void> _ensureParentDir(String path) async {
    final dir = File(path).parent;
    if (!dir.existsSync()) await dir.create(recursive: true);
  }

  // ---- Later-phase surface (stable signatures, not yet implemented) ----

  Future<String> generateSvg(
    BarcodeRequest request, {
    BarcodeExportOptions options = const BarcodeExportOptions(),
  }) =>
      _svgRenderer.render(request, options: options);

  Future<Uint8List> generatePdf(
    List<BarcodeRequest> requests, {
    BarcodePdfLayout layout = const BarcodePdfLayout.single(),
    BarcodeExportOptions options = const BarcodeExportOptions(),
  }) =>
      _pdfRenderer.render(requests, layout, options: options);

  Future<File> save(BarcodeRequest request, String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return saveAsPNG(request, path);
    if (lower.endsWith('.svg')) return saveAsSVG(request, path);
    if (lower.endsWith('.pdf')) return saveAsPDF([request], path);
    throw BarcodeGenException(
        'Unsupported file extension for "$path" (use .png, .svg, or .pdf)');
  }

  Future<File> saveAsSVG(
    BarcodeRequest request,
    String path, {
    BarcodeExportOptions options = const BarcodeExportOptions(),
  }) async {
    final svg = await generateSvg(request, options: options);
    return _writeString(path, svg);
  }

  Future<File> saveAsPDF(
    List<BarcodeRequest> requests,
    String path, {
    BarcodePdfLayout layout = const BarcodePdfLayout.single(),
    BarcodeExportOptions options = const BarcodeExportOptions(),
  }) async {
    final bytes = await generatePdf(requests, layout: layout, options: options);
    return _writeBytes(path, bytes);
  }

  Future<List<BarcodeGenResult>> generateBatch(
    List<BarcodeRequest> requests, {
    int concurrency = 4,
  }) =>
      const BatchGenerator()
          .run(requests, generate, concurrency: concurrency, cache: RenderCache());

  /// Decodes all barcodes found in [bytes] (PNG/JPEG/bitmap) via the native
  /// scanner. Pass [formats] to restrict symbologies (null => all). Returns an
  /// empty list when the image contains no barcodes.
  Future<List<BarcodeDecodeResult>> decodeImage(
    Uint8List bytes, {
    Set<BarcodeFormat>? formats,
  }) async {
    if (bytes.isEmpty) {
      throw const BarcodeGenException('decodeImage requires non-empty image bytes');
    }
    final mask = formats == null ? 0 : BarcodeFormat.encode(formats);
    try {
      final maps = await BarcodeScannerPlatform.instance.decodeImage(bytes, mask);
      return maps.map(BarcodeDecodeResult.fromMap).toList();
    } on PlatformException catch (e) {
      throw BarcodeGenException(e.message ?? 'Failed to decode image');
    }
  }

  /// Returns whether [request] can be generated. QR/2D codes accept arbitrary
  /// data; linear numeric symbologies are checked against their format rules.
  bool validate(BarcodeRequest request) {
    switch (request.format) {
      case BarcodeFormat.ean13:
        return BarcodeValidator.isValidEAN13(request.data);
      case BarcodeFormat.ean8:
        return BarcodeValidator.isValidEAN8(request.data);
      case BarcodeFormat.upcA:
        return BarcodeValidator.isValidUPC(request.data);
      case BarcodeFormat.code128:
        return BarcodeValidator.isValidCode128(request.data);
      case BarcodeFormat.code39:
        return BarcodeValidator.isValidCode39(request.data);
      default:
        return request.data.isNotEmpty;
    }
  }

  // ---- Named QR-payload helpers (Phase 3) ----
  static BarcodeRequest url(String url) => _qr(QrPayloads.url(url));
  static BarcodeRequest text(String value) => _qr(QrPayloads.text(value));
  static BarcodeRequest phone(String number) => _qr(QrPayloads.phone(number));
  static BarcodeRequest sms(String number, {String? message}) =>
      _qr(QrPayloads.sms(number, message: message));
  static BarcodeRequest email(String to, {String? subject, String? body}) =>
      _qr(QrPayloads.email(to, subject: subject, body: body));
  static BarcodeRequest wifi({
    required String ssid,
    String? password,
    String security = 'WPA',
    bool hidden = false,
  }) =>
      _qr(QrPayloads.wifi(
          ssid: ssid, password: password, security: security, hidden: hidden));
  static BarcodeRequest contact(Map<String, String> fields) =>
      _qr(QrPayloads.contact(fields));
  static BarcodeRequest calendar(Map<String, String> fields) =>
      _qr(QrPayloads.calendar(fields));
  static BarcodeRequest location(double lat, double lng) =>
      _qr(QrPayloads.location(lat, lng));

  static BarcodeRequest _qr(String data) =>
      BarcodeRequest(data: data, format: BarcodeFormat.qr);
}
