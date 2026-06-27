/// barcode_scanner_pro — a high-performance, offline barcode scanner plugin
/// for Flutter, backed by CameraX + ML Kit (Android) and AVFoundation + Vision
/// (iOS), rendered through native PlatformViews.
///
/// See `BarcodeScannerView` + `BarcodeScannerController` to get started.
library;

// Domain
export 'src/domain/barcode_format.dart';
export 'src/domain/barcode_result.dart';
export 'src/domain/camera_facing.dart';
export 'src/domain/resolution_preset.dart';
export 'src/domain/scan_mode.dart';
export 'src/domain/scanner_state.dart';

// Configuration
export 'src/config/scan_area.dart';
export 'src/config/scanner_configuration.dart';

// Errors
export 'src/error/scanner_exception.dart';

// Public API
export 'src/controller.dart';
export 'src/scanner_view.dart';

// Overlay
export 'src/overlay/scanner_overlay.dart' show ScannerOverlay, ScannerOverlayStyle;

// Platform interface (exposed for advanced use / testing)
export 'src/platform/barcode_scanner_platform.dart';
export 'src/platform/scanner_event.dart';
