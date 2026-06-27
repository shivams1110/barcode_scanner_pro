import AVFoundation
import Flutter
import UIKit
import Vision

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
    case Method.decodeImage:
      decodeImage(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func decodeImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let data = (args["bytes"] as? FlutterStandardTypedData)?.data,
      !data.isEmpty,
      let image = UIImage(data: data)?.cgImage
    else {
      result(FlutterError(code: ErrorCode.decodingError,
                          message: "Could not decode image bytes", details: nil))
      return
    }
    let mask = (args["formats"] as? Int) ?? 0
    let request = VNDetectBarcodesRequest()
    if mask != 0 {
      request.symbologies = FormatMapper.toSymbologies(mask)
    }
    let width = CGFloat(image.width)
    let height = CGFloat(image.height)
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
        let observations = request.results ?? []
        let maps: [[String: Any?]] = observations.map { obs in
          // Vision normalized coords: origin bottom-left, 0...1. Convert to
          // top-left image pixels to match the Android/Dart convention.
          let corners = [obs.topLeft, obs.topRight, obs.bottomRight, obs.bottomLeft].map {
            ["x": Double($0.x * width), "y": Double((1 - $0.y) * height)]
          }
          return [
            "value": obs.payloadStringValue ?? "",
            "format": FormatMapper.toBit(obs.symbology),
            "rawBytes": nil,
            "cornerPoints": corners,
          ]
        }
        DispatchQueue.main.async { result(maps) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: ErrorCode.decodingError,
                              message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
