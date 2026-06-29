import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'platform/barcode_scanner_platform.dart';

/// Builds an overlay layered on top of the native camera preview.
typedef OverlayBuilder =
    Widget Function(BuildContext context, BarcodeScannerController controller);

/// Hosts the native camera preview via a [PlatformView] and never renders a
/// Flutter-side camera image. Flutter is responsible only for the overlay,
/// gestures, and configuration — all pixels come from the platform.
///
/// On Android the preview uses Hybrid Composition so the CameraX surface
/// composites correctly; on iOS a `UiKitView` hosts the `AVCaptureVideoPreviewLayer`.
class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({
    super.key,
    required this.controller,
    this.overlayBuilder,
    this.onScannerCreated,
  });

  final BarcodeScannerController controller;

  /// Optional overlay rendered above the preview (mask, laser, corners...).
  final OverlayBuilder? overlayBuilder;

  /// Invoked once the native view is created and the controller is attached.
  /// A good place to call `controller.initialize()` then `start()`.
  final void Function(BarcodeScannerController controller)? onScannerCreated;

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  double _zoomAtGestureStart = 0;

  BarcodeScannerController get _controller => widget.controller;

  String get _viewType => BarcodeScannerPlatform.instance.viewType;

  Map<String, dynamic> get _creationParams => _controller.configuration.toMap();

  void _onPlatformViewCreated(int id) {
    _controller.attach(id);
    widget.onScannerCreated?.call(_controller);
  }

  // --- Gestures --------------------------------------------------------------

  void _onScaleStart(ScaleStartDetails _) {
    _zoomAtGestureStart = _controller.zoom.value;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (!_controller.configuration.enablePinchZoom) return;
    // Map pinch scale (multiplicative) onto the normalized zoom range.
    final delta = (d.scale - 1.0) * 0.5;
    _controller.setZoom(_zoomAtGestureStart + delta);
  }

  void _onTapUp(TapUpDetails d, BoxConstraints constraints) {
    if (!_controller.configuration.enableTapFocus) return;
    final local = d.localPosition;
    final nx = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final ny = (local.dy / constraints.maxHeight).clamp(0.0, 1.0);
    _controller.setFocus(Offset(nx, ny));
  }

  Widget _buildPlatformView() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: _viewType,
        surfaceFactory: (context, controller) => AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        ),
        onCreatePlatformView: (params) {
          final controller = PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: _viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: _creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged(true),
          );
          controller
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
            ..create();
          return controller;
        },
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _viewType,
        creationParams: _creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return const _UnsupportedPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onTapUp: (d) => _onTapUp(d, constraints),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPlatformView(),
              if (widget.overlayBuilder != null)
                widget.overlayBuilder!(context, _controller),
            ],
          ),
        );
      },
    );
  }
}

class _UnsupportedPlatform extends StatelessWidget {
  const _UnsupportedPlatform();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF000000),
    child: Center(
      child: Text(
        'barcode_scanner_pro supports Android and iOS only.',
        textDirection: TextDirection.ltr,
        style: TextStyle(color: Color(0xFFFFFFFF)),
      ),
    ),
  );
}
