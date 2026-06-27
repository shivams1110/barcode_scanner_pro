import AVFoundation
import Flutter
import UIKit

/// Plugin entry point. Registers the platform-view factory for the camera
/// preview and a single global method channel for camera-permission handling.
/// All scanning traffic flows through per-view channels owned by
/// `ScannerPlatformView`; this class holds no scanner state.
public class BarcodeScannerProPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = ScannerViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: Channels.viewType)

    let channel = FlutterMethodChannel(
      name: Channels.global, binaryMessenger: registrar.messenger())
    let instance = BarcodeScannerProPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Method.checkPermission:
      result(AVCaptureDevice.authorizationStatus(for: .video) == .authorized)
    case Method.requestPermission:
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        result(true)
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async { result(granted) }
        }
      default:
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
