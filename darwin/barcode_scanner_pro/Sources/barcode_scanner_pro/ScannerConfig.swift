import AVFoundation
import Foundation

/// Normalized scan-area rectangle in [0,1] preview space.
struct ScanAreaConfig {
  let left: Double
  let top: Double
  let width: Double
  let height: Double

  var isFull: Bool { left == 0 && top == 0 && width == 1 && height == 1 }
}

/// Type-safe representation of the configuration sent from Dart
/// (`ScannerConfiguration.toMap`).
struct ScannerConfig {
  let cameraFacing: Int
  let resolution: Int
  let formatMask: Int
  let scanMode: Int
  let scanArea: ScanAreaConfig
  let continuousScanning: Bool
  let duplicateTimeoutMs: Double
  let enableAutoFocus: Bool
  let enableSound: Bool
  let enableVibration: Bool
  let frameRateLimit: Int
  let returnImage: Bool
  let detectInverted: Bool

  var devicePosition: AVCaptureDevice.Position {
    cameraFacing == 1 ? .front : .back
  }

  /// Session preset mapped from the resolution enum.
  var sessionPreset: AVCaptureSession.Preset {
    switch resolution {
    case 0: return .vga640x480
    case 1: return .hd1280x720
    case 2: return .hd1920x1080
    default: return .hd1920x1080
    }
  }

  /// Minimum interval (seconds) between decoded frames from the FPS cap.
  var frameInterval: CFTimeInterval {
    1.0 / Double(max(frameRateLimit, 1))
  }

  static func from(_ map: [String: Any?]) -> ScannerConfig {
    let area = map["scanArea"] as? [String: Any?] ?? [:]
    func d(_ v: Any??, _ def: Double) -> Double { (v as? NSNumber)?.doubleValue ?? def }
    func i(_ v: Any??, _ def: Int) -> Int { (v as? NSNumber)?.intValue ?? def }
    func b(_ v: Any??, _ def: Bool) -> Bool { (v as? NSNumber)?.boolValue ?? def }
    return ScannerConfig(
      cameraFacing: i(map["camera"], 0),
      resolution: i(map["resolution"], 1),
      formatMask: i(map["formats"], 0),
      scanMode: i(map["scanMode"], 1),
      scanArea: ScanAreaConfig(
        left: d(area["left"], 0), top: d(area["top"], 0),
        width: d(area["width"], 1), height: d(area["height"], 1)
      ),
      continuousScanning: b(map["continuousScanning"], true),
      duplicateTimeoutMs: d(map["duplicateTimeoutMs"], 1000),
      enableAutoFocus: b(map["enableAutoFocus"], true),
      enableSound: b(map["enableSound"], true),
      enableVibration: b(map["enableVibration"], true),
      frameRateLimit: i(map["frameRateLimit"], 15),
      returnImage: b(map["returnImage"], false),
      detectInverted: b(map["detectInverted"], false)
    )
  }
}
