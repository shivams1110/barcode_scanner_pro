/// Stable error codes shared with the native layer. Native `PlatformException`s
/// use these as their `code`, allowing a single mapping point in
/// [ScannerException.fromCode].
class ScannerErrorCode {
  ScannerErrorCode._();

  static const permissionDenied = 'CAMERA_PERMISSION_DENIED';
  static const cameraUnavailable = 'CAMERA_UNAVAILABLE';
  static const initializationFailed = 'CAMERA_INITIALIZATION_FAILED';
  static const scannerBusy = 'SCANNER_BUSY';
  static const decodingError = 'DECODING_ERROR';
  static const invalidConfiguration = 'INVALID_CONFIGURATION';
  static const unsupportedDevice = 'UNSUPPORTED_DEVICE';
}

/// Base class for all scanner errors. Catch this to handle any failure, or
/// switch on the concrete subtypes for specific recovery.
sealed class ScannerException implements Exception {
  const ScannerException(this.message, {this.details});

  final String message;
  final Object? details;

  /// Maps a native error [code] (see [ScannerErrorCode]) to the matching
  /// concrete exception. Unknown codes become a [DecodingError] so callers
  /// always receive a [ScannerException].
  factory ScannerException.fromCode(
    String code,
    String? message, [
    Object? details,
  ]) {
    final msg = message ?? code;
    return switch (code) {
      ScannerErrorCode.permissionDenied => CameraPermissionDenied(
        msg,
        details: details,
      ),
      ScannerErrorCode.cameraUnavailable => CameraUnavailable(
        msg,
        details: details,
      ),
      ScannerErrorCode.initializationFailed => CameraInitializationFailed(
        msg,
        details: details,
      ),
      ScannerErrorCode.scannerBusy => ScannerBusy(msg, details: details),
      ScannerErrorCode.invalidConfiguration => InvalidConfiguration(
        msg,
        details: details,
      ),
      ScannerErrorCode.unsupportedDevice => UnsupportedDevice(
        msg,
        details: details,
      ),
      _ => DecodingError(msg, details: details),
    };
  }

  @override
  String toString() => '$runtimeType: $message';
}

/// The user denied (or has not granted) camera permission.
class CameraPermissionDenied extends ScannerException {
  const CameraPermissionDenied(super.message, {super.details});
}

/// No usable camera is present, or it is held by another app.
class CameraUnavailable extends ScannerException {
  const CameraUnavailable(super.message, {super.details});
}

/// The camera session failed to configure or start.
class CameraInitializationFailed extends ScannerException {
  const CameraInitializationFailed(super.message, {super.details});
}

/// A conflicting operation is already in progress.
class ScannerBusy extends ScannerException {
  const ScannerBusy(super.message, {super.details});
}

/// A frame could not be decoded due to an internal detector error.
class DecodingError extends ScannerException {
  const DecodingError(super.message, {super.details});
}

/// The supplied [ScannerConfiguration] is invalid for this device.
class InvalidConfiguration extends ScannerException {
  const InvalidConfiguration(super.message, {super.details});
}

/// The device lacks a capability required by the scanner.
class UnsupportedDevice extends ScannerException {
  const UnsupportedDevice(super.message, {super.details});
}
