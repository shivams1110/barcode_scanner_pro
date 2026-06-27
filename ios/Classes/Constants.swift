import Foundation

/// Channel naming + identifiers. MUST mirror the Dart `Channels` definitions.
enum Channels {
  static let base = "com.karnival.barcode_scanner_pro"
  static let viewType = "\(base)/view"
  static let global = "\(base)/global"
  static func methods(_ id: Int64) -> String { "\(base)/methods/\(id)" }
  static func events(_ id: Int64) -> String { "\(base)/events/\(id)" }
}

enum Method {
  static let initialize = "initialize"
  static let start = "start"
  static let stop = "stop"
  static let pause = "pause"
  static let resume = "resume"
  static let dispose = "dispose"
  static let setFlash = "setFlash"
  static let toggleFlash = "toggleFlash"
  static let switchCamera = "switchCamera"
  static let setZoom = "setZoom"
  static let setExposure = "setExposure"
  static let setFocus = "setFocus"
  static let captureFrame = "captureFrame"
  static let decodeImage = "decodeImage"
  static let requestPermission = "requestPermission"
  static let checkPermission = "checkPermission"
}

enum EventType {
  static let barcodeDetected = "barcodeDetected"
  static let scannerStarted = "scannerStarted"
  static let scannerStopped = "scannerStopped"
  static let permissionDenied = "permissionDenied"
  static let error = "error"
  static let cameraChanged = "cameraChanged"
  static let flashChanged = "flashChanged"
  static let zoomChanged = "zoomChanged"
}

enum ErrorCode {
  static let permissionDenied = "CAMERA_PERMISSION_DENIED"
  static let cameraUnavailable = "CAMERA_UNAVAILABLE"
  static let initializationFailed = "CAMERA_INITIALIZATION_FAILED"
  static let scannerBusy = "SCANNER_BUSY"
  static let decodingError = "DECODING_ERROR"
  static let invalidConfiguration = "INVALID_CONFIGURATION"
  static let unsupportedDevice = "UNSUPPORTED_DEVICE"
}
