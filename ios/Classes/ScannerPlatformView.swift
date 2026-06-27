import AVFoundation
import Flutter
import UIKit

/// A `UIView` that keeps the `AVCaptureVideoPreviewLayer` sized to its bounds.
final class PreviewContainerView: UIView {
  private let previewLayer: AVCaptureVideoPreviewLayer
  init(previewLayer: AVCaptureVideoPreviewLayer) {
    self.previewLayer = previewLayer
    super.init(frame: .zero)
    layer.addSublayer(previewLayer)
    backgroundColor = .black
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }
  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer.frame = bounds
  }
}

/// One native scanner instance hosted in a Flutter PlatformView. Wires the
/// per-view method/event channels and delegates camera work to `CameraManager`
/// and decoding to `FrameAnalyzer`.
final class ScannerPlatformView: NSObject, FlutterPlatformView {
  private let container: PreviewContainerView
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let events = EventDispatcher()

  private var config: ScannerConfig
  private var cameraManager: CameraManager?
  private var analyzer: FrameAnalyzer?

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    let params = (args as? [String: Any?]) ?? [:]
    self.config = ScannerConfig.from(params)
    self.methodChannel = FlutterMethodChannel(
      name: Channels.methods(viewId), binaryMessenger: messenger)
    self.eventChannel = FlutterEventChannel(
      name: Channels.events(viewId), binaryMessenger: messenger)

    let analyzer = FrameAnalyzer(
      config: config,
      onBarcodes: { _ in },  // replaced below once events is captured
      onError: { _ in })
    let manager = CameraManager(analyzer: analyzer, events: events)
    self.analyzer = analyzer
    self.cameraManager = manager
    self.container = PreviewContainerView(previewLayer: manager.previewLayer)
    super.init()

    eventChannel.setStreamHandler(events)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
  }

  func view() -> UIView { container }

  private func hasPermission() -> Bool {
    AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case Method.initialize: initialize(call, result)
    case Method.start:
      cameraManager?.resumeAnalysis()
      events.send(["type": EventType.scannerStarted])
      result(nil)
    case Method.stop:
      cameraManager?.stop()
      events.send(["type": EventType.scannerStopped])
      result(nil)
    case Method.pause:
      cameraManager?.pauseAnalysis()
      result(nil)
    case Method.resume:
      cameraManager?.resumeAnalysis()
      result(nil)
    case Method.setFlash:
      let on = ((call.arguments as? [String: Any])?["enabled"] as? Bool) ?? false
      cameraManager?.setTorch(on)
      result(nil)
    case Method.toggleFlash:
      result(cameraManager?.toggleTorch() ?? false)
    case Method.switchCamera:
      cameraManager?.switchCamera(config: config)
      result(nil)
    case Method.setZoom:
      let z = ((call.arguments as? [String: Any])?["zoom"] as? NSNumber)?.doubleValue ?? 0
      cameraManager?.setZoom(z)
      result(nil)
    case Method.setExposure:
      let e = ((call.arguments as? [String: Any])?["exposure"] as? NSNumber)?.doubleValue ?? 0
      cameraManager?.setExposure(e)
      result(nil)
    case Method.setFocus:
      let a = call.arguments as? [String: Any]
      let x = (a?["x"] as? NSNumber)?.doubleValue ?? 0.5
      let y = (a?["y"] as? NSNumber)?.doubleValue ?? 0.5
      cameraManager?.focusAt(nx: x, ny: y)
      result(nil)
    case Method.captureFrame:
      if let data = cameraManager?.captureFrame() {
        result(FlutterStandardTypedData(bytes: data))
      } else {
        result(nil)
      }
    case Method.dispose:
      disposeInternal()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func initialize(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    if let params = call.arguments as? [String: Any?] {
      config = ScannerConfig.from(params)
    }
    guard hasPermission() else {
      events.send(["type": EventType.permissionDenied])
      result(FlutterError(
        code: ErrorCode.permissionDenied, message: "Camera permission not granted",
        details: nil))
      return
    }
    // Rebuild the analyzer/manager with a config-bound emission closure.
    let analyzer = FrameAnalyzer(
      config: config,
      onBarcodes: { [weak self] list in
        self?.events.send(["type": EventType.barcodeDetected, "barcodes": list])
      },
      onError: { [weak self] msg in
        self?.events.sendError(ErrorCode.decodingError, msg)
      })
    let manager = CameraManager(analyzer: analyzer, events: events)
    self.analyzer = analyzer
    self.cameraManager = manager
    container.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    container.layer.addSublayer(manager.previewLayer)
    manager.previewLayer.frame = container.bounds

    manager.start(
      config: config,
      onReady: { result(nil) },
      onError: { code, msg in
        self.events.sendError(code, msg)
        result(FlutterError(code: code, message: msg, details: nil))
      })
  }

  private func disposeInternal() {
    cameraManager?.dispose()
    cameraManager = nil
    analyzer = nil
    events.dispose()
    methodChannel.setMethodCallHandler(nil)
    eventChannel.setStreamHandler(nil)
  }

  deinit { disposeInternal() }
}
