import AVFoundation
#if os(iOS)
import Flutter
import UIKit
typealias PlatformView = UIView
#elseif os(macOS)
import AppKit
import FlutterMacOS
typealias PlatformView = NSView
#endif

/// A platform view that keeps the `AVCaptureVideoPreviewLayer` sized to its bounds.
///
/// On iOS `UIView.layer` is implicit; on macOS the view must be layer-backed
/// (`wantsLayer`) and its layer is optional. `owner` gives the returned NSView a
/// strong reference back to its `ScannerPlatformView` controller on macOS, where
/// the factory hands Flutter only the view.
final class PreviewContainerView: PlatformView {
  private let previewLayer: AVCaptureVideoPreviewLayer
  var owner: AnyObject?

  init(previewLayer: AVCaptureVideoPreviewLayer) {
    self.previewLayer = previewLayer
    super.init(frame: .zero)
    #if os(iOS)
    layer.addSublayer(previewLayer)
    backgroundColor = .black
    #elseif os(macOS)
    wantsLayer = true
    layer?.backgroundColor = NSColor.black.cgColor
    layer?.addSublayer(previewLayer)
    #endif
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

  #if os(iOS)
  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer.frame = bounds
  }
  #elseif os(macOS)
  override func layout() {
    super.layout()
    previewLayer.frame = bounds
  }
  #endif
}

/// One native scanner instance hosted in a Flutter PlatformView. Wires the
/// per-view method/event channels and delegates camera work to `CameraManager`
/// and decoding to `FrameAnalyzer`.
final class ScannerPlatformView: NSObject {
  private let container: PreviewContainerView
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let events = EventDispatcher()

  private var config: ScannerConfig
  private var cameraManager: CameraManager?
  private var analyzer: FrameAnalyzer?
  private var feedback: FeedbackController?

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

    #if os(macOS)
    // Retain self through the view Flutter holds.
    container.owner = self
    #endif

    eventChannel.setStreamHandler(events)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
  }

  #if os(iOS)
  func view() -> UIView { container }
  #elseif os(macOS)
  var platformView: NSView { container }
  #endif

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
    let feedback = FeedbackController(
      soundEnabled: config.enableSound, vibrationEnabled: config.enableVibration)
    self.feedback = feedback

    // Rebuild the analyzer/manager with a config-bound emission closure.
    let analyzer = FrameAnalyzer(
      config: config,
      onBarcodes: { [weak self] list in
        self?.feedback?.onDetection()
        self?.events.send(["type": EventType.barcodeDetected, "barcodes": list])
      },
      onError: { [weak self] msg in
        self?.events.sendError(ErrorCode.decodingError, msg)
      })
    let manager = CameraManager(analyzer: analyzer, events: events)
    self.analyzer = analyzer
    self.cameraManager = manager
    #if os(iOS)
    container.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    container.layer.addSublayer(manager.previewLayer)
    #elseif os(macOS)
    container.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
    container.layer?.addSublayer(manager.previewLayer)
    #endif
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
    feedback = nil
    events.dispose()
    methodChannel.setMethodCallHandler(nil)
    eventChannel.setStreamHandler(nil)
    #if os(macOS)
    container.owner = nil
    #endif
  }

  deinit { disposeInternal() }
}

#if os(iOS)
// Conformance declared separately so the class header need not be split across
// a `#if`, which Swift disallows. `view()` is defined as an iOS member above.
extension ScannerPlatformView: FlutterPlatformView {}
#endif
