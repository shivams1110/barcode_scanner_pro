import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config/scan_area.dart';
import '../controller.dart';
import '../domain/barcode_result.dart';
import 'overlay_painters.dart';

/// Visual style for [ScannerOverlay]. Pure data so it can be const-constructed
/// and themed (e.g. swapped for dark mode).
class ScannerOverlayStyle {
  const ScannerOverlayStyle({
    this.maskColor = const Color(0x99000000),
    this.borderColor = const Color(0xFFFFFFFF),
    this.laserColor = const Color(0xFFFF3B30),
    this.detectionColor = const Color(0xFF34C759),
    this.detectionFillColor = const Color(0x3334C759),
    this.borderRadius = 16,
    this.cornerLength = 28,
    this.cornerWidth = 4,
    this.showLaser = true,
    this.showCorners = true,
    this.showDetections = true,
    this.detectionLingerDuration = const Duration(milliseconds: 600),
  });

  final Color maskColor;
  final Color borderColor;
  final Color laserColor;
  final Color detectionColor;
  final Color detectionFillColor;
  final double borderRadius;
  final double cornerLength;
  final double cornerWidth;
  final bool showLaser;
  final bool showCorners;
  final bool showDetections;

  /// How long a detection highlight remains before fading out.
  final Duration detectionLingerDuration;
}

/// Composable overlay: dark mask + rounded window + corner indicators +
/// animated laser + live detection highlights.
///
/// Drop it into `BarcodeScannerView.overlayBuilder`. It listens to the
/// controller's barcode stream to render detection polygons and clears them
/// after [ScannerOverlayStyle.detectionLingerDuration].
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({
    super.key,
    required this.controller,
    this.scanArea,
    this.style = const ScannerOverlayStyle(),
  });

  final BarcodeScannerController controller;

  /// Defaults to the controller's configured scan area.
  final ScanArea? scanArea;
  final ScannerOverlayStyle style;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _laser;
  StreamSubscription<BarcodeResult>? _sub;
  List<BarcodeResult> _detections = const [];
  Timer? _clearTimer;

  ScanArea get _area =>
      widget.scanArea ?? widget.controller.configuration.scanArea;

  @override
  void initState() {
    super.initState();
    // Only run the (continuous) laser animation when it is actually drawn, so
    // the overlay schedules no ongoing frames when the laser is disabled.
    if (widget.style.showLaser) {
      _laser = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat(reverse: true);
    }

    if (widget.style.showDetections) {
      _sub = widget.controller.barcodes.listen(_onBarcode);
    }
  }

  void _onBarcode(BarcodeResult b) {
    if (!mounted) return;
    setState(() => _detections = [b]);
    _clearTimer?.cancel();
    _clearTimer = Timer(widget.style.detectionLingerDuration, () {
      if (mounted) setState(() => _detections = const []);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _clearTimer?.cancel();
    _laser?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: ScannerMaskPainter(
              scanArea: _area,
              maskColor: style.maskColor,
              borderColor: style.showCorners
                  ? style.borderColor
                  : const Color(0x00000000),
              borderRadius: style.borderRadius,
              cornerLength: style.cornerLength,
              cornerWidth: style.cornerWidth,
            ),
          ),
          if (style.showLaser && _laser != null)
            CustomPaint(
              painter: LaserPainter(
                scanArea: _area,
                progress: _laser!,
                color: style.laserColor,
              ),
            ),
          if (style.showDetections && _detections.isNotEmpty)
            CustomPaint(
              painter: DetectionPainter(
                barcodes: _detections,
                color: style.detectionColor,
                fillColor: style.detectionFillColor,
              ),
            ),
        ],
      ),
    );
  }
}
