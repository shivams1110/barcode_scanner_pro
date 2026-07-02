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
/// composites correctly; on iOS a `UiKitView` and on macOS an `AppKitView`
/// host the `AVCaptureVideoPreviewLayer`. On web an `HtmlElementView` hosts a
/// `<video>` element driven by `getUserMedia` + the `BarcodeDetector` API.
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
  ///
  /// On Windows/Linux the view drives `controller.initialize()` itself before
  /// invoking this callback (it needs the texture id to render the preview),
  /// so on those platforms `onScannerCreated` should call `start()` only —
  /// calling `initialize()` again is redundant.
  final void Function(BarcodeScannerController controller)? onScannerCreated;

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  double _zoomAtGestureStart = 0;

  // Desktop (Windows/Linux) has no PlatformView and no
  // `onPlatformViewCreated` callback, so the view itself must allocate a
  // view id and drive `initialize()` to obtain a texture id before it can
  // build a `Texture` widget. `_desktopViewIdSeq` is a process-wide
  // monotonic counter used as the view id in lieu of one assigned by an
  // embedder-side platform view registry.
  static int _desktopViewIdSeq = 0;
  int? _desktopTextureId;
  bool _desktopInitStarted = false;

  BarcodeScannerController get _controller => widget.controller;

  String get _viewType => BarcodeScannerPlatform.instance.viewType;

  Map<String, dynamic> get _creationParams => _controller.configuration.toMap();

  void _onPlatformViewCreated(int id) {
    _controller.attach(id);
    widget.onScannerCreated?.call(_controller);
  }

  /// Desktop-only init flow: allocate a view id, attach the controller, then
  /// drive `initialize()` through the controller so the full state machine
  /// runs (`state` → ready, `initialized` → true) and `controller.textureId`
  /// is populated — matching mobile behavior exactly. The resolved texture id
  /// is needed to build a `Texture` widget. Unlike the mobile/web paths,
  /// `onScannerCreated` is NOT expected to call `initialize()` again — it
  /// already happened here. Callers' `onScannerCreated` should call `start()`
  /// instead.
  ///
  /// If `controller.initialize()` throws a `ScannerException`, it is
  /// rethrown here (and surfaced via the controller's `errors` stream); we
  /// leave `_desktopInitStarted` set so init is not silently retried on every
  /// rebuild — a retry would need the view to be recreated.
  Future<void> _initDesktop() async {
    final id = _desktopViewIdSeq++;
    _controller.attach(id);
    await _controller.initialize();
    if (!mounted) return;
    setState(() => _desktopTextureId = _controller.textureId);
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
    if (kIsWeb) {
      return HtmlElementView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
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
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return AppKitView(
        viewType: _viewType,
        creationParams: _creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      if (!_desktopInitStarted) {
        _desktopInitStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _initDesktop());
      }
      final id = _desktopTextureId;
      if (id == null) {
        return const ColoredBox(color: Color(0xFF000000));
      }
      return Texture(textureId: id);
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
        'barcode_scanner_pro does not support this platform.',
        textDirection: TextDirection.ltr,
        style: TextStyle(color: Color(0xFFFFFFFF)),
      ),
    ),
  );
}
