import 'dart:ui' as ui;

import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/code_preview.dart';
import 'widgets/section_scaffold.dart';

const String _kData = 'https://karnival.com';

/// Demonstrates QR codes with an embedded center logo.
///
/// The logo is created entirely in-app via [ui.PictureRecorder] → [Canvas] →
/// [ui.Picture.toImage] — no asset files required.
///
/// An ECC-guard demo button shows that [BarcodeGenerator.generate] throws
/// [BarcodeGenException] when a logo is paired with medium (or lower) error
/// correction.
class LogoQrSection extends StatefulWidget {
  const LogoQrSection({super.key});

  @override
  State<LogoQrSection> createState() => _LogoQrSectionState();
}

class _LogoQrSectionState extends State<LogoQrSection> {
  ui.Image? _logo;
  String? _eccErrorMessage;

  @override
  void initState() {
    super.initState();
    _buildLogo().then((img) {
      if (mounted) setState(() => _logo = img);
    });
  }

  @override
  void dispose() {
    _logo?.dispose();
    super.dispose();
  }

  /// Paints a filled rounded square with a contrasting white star-like glyph
  /// using only [ui.PictureRecorder] + [Canvas] — no external assets.
  Future<ui.Image> _buildLogo() async {
    const double size = 128;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background: deep-indigo rounded square.
    final bgPaint = Paint()
      ..color = const Color(0xFF3F51B5)
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectXY(
        const Rect.fromLTWH(0, 0, size, size),
        24.0,
        24.0,
      ),
      bgPaint,
    );

    // Foreground glyph: a simple five-point star drawn via a Path.
    final starPaint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    const cx = size / 2.0;
    const cy = size / 2.0;
    const outerR = size * 0.36;
    const innerR = size * 0.15;
    const points = 5;

    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * 3.14159265 / points) - 3.14159265 / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * _cos(angle);
      final y = cy + r * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, starPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    picture.dispose();
    return image;
  }

  double _cos(double a) => _approxTrig(a, isCos: true);
  double _sin(double a) => _approxTrig(a, isCos: false);

  /// Uses [dart:math] via import alias to avoid a top-level import clash.
  double _approxTrig(double a, {required bool isCos}) {
    // ignore: avoid_multiple_declarations_per_line
    double x = a;
    // Normalize to [-pi, pi].
    const pi = 3.14159265358979;
    while (x > pi) {
      x -= 2 * pi;
    }
    while (x < -pi) {
      x += 2 * pi;
    }
    // Taylor approximation sufficient for drawing.
    if (isCos) {
      return 1 -
          (x * x) / 2 +
          (x * x * x * x) / 24 -
          (x * x * x * x * x * x) / 720;
    } else {
      return x -
          (x * x * x) / 6 +
          (x * x * x * x * x) / 120 -
          (x * x * x * x * x * x * x) / 5040;
    }
  }

  Future<void> _tryMediumEcc() async {
    final logo = _logo;
    if (logo == null) return;

    setState(() => _eccErrorMessage = null);

    try {
      await const BarcodeGenerator().generate(
        BarcodeRequest(
          data: _kData,
          format: BarcodeFormat.qr,
          style: BarcodeStyle(
            errorCorrection: ErrorCorrection.medium,
            logo: BarcodeLogo(image: logo),
          ),
        ),
      );
    } on BarcodeGenException catch (e) {
      if (!mounted) return;
      setState(() => _eccErrorMessage = e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logo = _logo;

    return SectionScaffold(
      title: 'Logo QR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'A logo requires error correction ≥ quartile (Q or H).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          if (logo == null)
            const Center(child: CircularProgressIndicator())
          else
            CodePreview(
              child: BarcodeWidget(
                data: _kData,
                format: BarcodeFormat.qr,
                logo: logo,
                logoSize: 0.2,
                errorCorrectionLevel: ErrorCorrection.high,
                width: 260,
                height: 260,
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: logo != null ? _tryMediumEcc : null,
            child: const Text('Try with medium ECC'),
          ),
          if (_eccErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _eccErrorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
