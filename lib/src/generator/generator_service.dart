import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../error/barcode_gen_exception.dart';
import 'models/barcode_gen_result.dart';
import 'models/barcode_request.dart';
import 'models/pdf_layout.dart';
import 'rendering/pdf_renderer.dart';
import 'rendering/raster_exporter.dart';
import 'rendering/svg_renderer.dart';

const _phase2 = 'arrives in Phase 2';
const _phase3 = 'arrives in Phase 3';

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

  Future<String> generateSvg(BarcodeRequest request) =>
      _svgRenderer.render(request);

  Future<Uint8List> generatePdf(
    List<BarcodeRequest> requests, {
    BarcodePdfLayout layout = const BarcodePdfLayout.single(),
  }) =>
      _pdfRenderer.render(requests, layout);

  Future<File> save(BarcodeRequest request, String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return saveAsPNG(request, path);
    if (lower.endsWith('.svg')) return saveAsSVG(request, path);
    if (lower.endsWith('.pdf')) return saveAsPDF([request], path);
    throw BarcodeGenException(
        'Unsupported file extension for "$path" (use .png, .svg, or .pdf)');
  }

  Future<File> saveAsSVG(BarcodeRequest request, String path) async {
    final svg = await generateSvg(request);
    return _writeString(path, svg);
  }

  Future<File> saveAsPDF(
    List<BarcodeRequest> requests,
    String path, {
    BarcodePdfLayout layout = const BarcodePdfLayout.single(),
  }) async {
    final bytes = await generatePdf(requests, layout: layout);
    return _writeBytes(path, bytes);
  }

  Future<List<BarcodeGenResult>> generateBatch(List<BarcodeRequest> requests) =>
      throw UnimplementedError('generateBatch $_phase2');

  Future<Object> decodeImage(Uint8List bytes) =>
      throw UnimplementedError('decodeImage $_phase3');

  bool validate(BarcodeRequest request) =>
      throw UnimplementedError('validate $_phase3');

  // ---- Named QR-payload helpers (Phase 3) ----
  static BarcodeRequest url(String url) =>
      throw UnimplementedError('url() $_phase3');
  static BarcodeRequest email(String to, {String? subject, String? body}) =>
      throw UnimplementedError('email() $_phase3');
  static BarcodeRequest phone(String number) =>
      throw UnimplementedError('phone() $_phase3');
  static BarcodeRequest sms(String number, {String? message}) =>
      throw UnimplementedError('sms() $_phase3');
  static BarcodeRequest wifi(
          {required String ssid, String? password, String security = 'WPA'}) =>
      throw UnimplementedError('wifi() $_phase3');
  static BarcodeRequest contact(Map<String, String> fields) =>
      throw UnimplementedError('contact() $_phase3');
  static BarcodeRequest calendar(Map<String, String> fields) =>
      throw UnimplementedError('calendar() $_phase3');
  static BarcodeRequest location(double lat, double lng) =>
      throw UnimplementedError('location() $_phase3');
  static BarcodeRequest text(String value) =>
      throw UnimplementedError('text() $_phase3');
}
