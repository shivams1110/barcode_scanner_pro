import AVFoundation
import CoreImage
import ImageIO
import UIKit

/// Owns the AVFoundation capture pipeline for one scanner view:
///
///   AVCaptureSession -> AVCaptureVideoDataOutput -> CMSampleBuffer -> Vision.
///
/// Session configuration and control run on a dedicated serial queue so the
/// main thread is never blocked. The most recent pixel buffer is retained for
/// `captureFrame`. Camera controls are delegated to the active `AVCaptureDevice`.
final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "com.umda.barcode_scanner_pro.session")
  private let videoOutput = AVCaptureVideoDataOutput()
  private let analyzer: FrameAnalyzer
  private let events: EventDispatcher
  private let ciContext = CIContext()

  private var device: AVCaptureDevice?
  private var position: AVCaptureDevice.Position = .back
  private var latestPixelBuffer: CVPixelBuffer?

  let previewLayer: AVCaptureVideoPreviewLayer

  init(analyzer: FrameAnalyzer, events: EventDispatcher) {
    self.analyzer = analyzer
    self.events = events
    self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
    super.init()
    self.previewLayer.videoGravity = .resizeAspectFill
    NotificationCenter.default.addObserver(
      self, selector: #selector(orientationChanged),
      name: UIDevice.orientationDidChangeNotification, object: nil)
    updateOrientation()
  }

  // MARK: - Lifecycle

  func start(
    config: ScannerConfig, onReady: @escaping () -> Void,
    onError: @escaping (String, String) -> Void
  ) {
    position = config.devicePosition
    sessionQueue.async { [weak self] in
      guard let self = self else { return }
      do {
        try self.configureSession(config)
        self.session.startRunning()
        DispatchQueue.main.async(execute: onReady)
      } catch let e as ConfigError {
        DispatchQueue.main.async { onError(e.code, e.message) }
      } catch {
        DispatchQueue.main.async {
          onError(ErrorCode.initializationFailed, error.localizedDescription)
        }
      }
    }
  }

  private struct ConfigError: Error { let code: String; let message: String }

  private func configureSession(_ config: ScannerConfig) throws {
    session.beginConfiguration()
    defer { session.commitConfiguration() }

    if session.canSetSessionPreset(config.sessionPreset) {
      session.sessionPreset = config.sessionPreset
    }

    // Remove any previous I/O (e.g. on camera switch).
    session.inputs.forEach { session.removeInput($0) }
    session.outputs.forEach { session.removeOutput($0) }

    guard let camera = Self.device(for: position) else {
      throw ConfigError(code: ErrorCode.cameraUnavailable, message: "No camera for position")
    }
    device = camera
    let input = try AVCaptureDeviceInput(device: camera)
    guard session.canAddInput(input) else {
      throw ConfigError(code: ErrorCode.initializationFailed, message: "Cannot add camera input")
    }
    session.addInput(input)

    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    guard session.canAddOutput(videoOutput) else {
      throw ConfigError(code: ErrorCode.initializationFailed, message: "Cannot add video output")
    }
    session.addOutput(videoOutput)

    if config.enableAutoFocus, camera.isFocusModeSupported(.continuousAutoFocus) {
      try? camera.lockForConfiguration()
      camera.focusMode = .continuousAutoFocus
      camera.unlockForConfiguration()
    }
  }

  private static func device(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: .video, position: position
    ).devices.first
  }

  func switchCamera(config: ScannerConfig) {
    position = (position == .back) ? .front : .back
    sessionQueue.async { [weak self] in
      guard let self = self else { return }
      try? self.configureSession(config)
      self.events.send([
        "type": EventType.cameraChanged,
        "camera": self.position == .front ? 1 : 0,
      ])
    }
  }

  func pauseAnalysis() { analyzer.active = false }

  func resumeAnalysis() {
    analyzer.resetDuplicates()
    analyzer.active = true
  }

  func stop() {
    analyzer.active = false
    sessionQueue.async { [weak self] in self?.session.stopRunning() }
  }

  func dispose() {
    NotificationCenter.default.removeObserver(self)
    stop()
    sessionQueue.async { [weak self] in
      self?.videoOutput.setSampleBufferDelegate(nil, queue: nil)
      self?.latestPixelBuffer = nil
    }
  }

  // MARK: - Controls

  func setTorch(_ on: Bool) {
    sessionQueue.async { [weak self] in
      guard let d = self?.device, d.hasTorch else { return }
      try? d.lockForConfiguration()
      d.torchMode = on ? .on : .off
      d.unlockForConfiguration()
      self?.events.send(["type": EventType.flashChanged, "enabled": on])
    }
  }

  func toggleTorch() -> Bool {
    let on = device?.torchMode == .on
    setTorch(!on)
    return !on
  }

  /// [value] normalized in `[0,1]`.
  func setZoom(_ value: Double) {
    sessionQueue.async { [weak self] in
      guard let d = self?.device else { return }
      let maxFactor = min(d.activeFormat.videoMaxZoomFactor, 8.0)
      let factor = 1.0 + CGFloat(max(0, min(1, value))) * (maxFactor - 1.0)
      try? d.lockForConfiguration()
      d.videoZoomFactor = factor
      d.unlockForConfiguration()
      self?.events.send(["type": EventType.zoomChanged, "zoom": value])
    }
  }

  /// [value] in `[-1,1]` mapped onto the device exposure-bias range.
  func setExposure(_ value: Double) {
    sessionQueue.async { [weak self] in
      guard let d = self?.device else { return }
      let bias: Float =
        value >= 0
        ? Float(value) * d.maxExposureTargetBias
        : Float(-value) * d.minExposureTargetBias
      try? d.lockForConfiguration()
      d.setExposureTargetBias(bias, completionHandler: nil)
      d.unlockForConfiguration()
    }
  }

  /// [nx]/[ny] normalized `[0,1]` in preview space. Conversion to device space
  /// uses the preview layer and therefore runs on the main thread first.
  func focusAt(nx: Double, ny: Double) {
    let layerPoint = CGPoint(
      x: nx * previewLayer.bounds.width, y: ny * previewLayer.bounds.height)
    let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
    sessionQueue.async { [weak self] in
      guard let d = self?.device else { return }
      try? d.lockForConfiguration()
      if d.isFocusPointOfInterestSupported {
        d.focusPointOfInterest = devicePoint
        d.focusMode = .autoFocus
      }
      if d.isExposurePointOfInterestSupported {
        d.exposurePointOfInterest = devicePoint
        d.exposureMode = .autoExpose
      }
      d.unlockForConfiguration()
    }
  }

  /// Captures the latest frame as JPEG bytes (best-effort).
  func captureFrame() -> Data? {
    guard let pb = latestPixelBuffer else { return nil }
    let ci = CIImage(cvPixelBuffer: pb)
    guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return nil }
    return UIImage(cgImage: cg).jpegData(compressionQuality: 0.85)
  }

  // MARK: - Orientation

  @objc private func orientationChanged() { updateOrientation() }

  private func updateOrientation() {
    let orientation = UIDevice.current.orientation
    let cg: CGImagePropertyOrientation
    let video: AVCaptureVideoOrientation
    switch orientation {
    case .landscapeLeft: cg = .up; video = .landscapeRight
    case .landscapeRight: cg = .down; video = .landscapeLeft
    case .portraitUpsideDown: cg = .left; video = .portraitUpsideDown
    default: cg = .right; video = .portrait
    }
    analyzer.orientation = cg
    if let conn = previewLayer.connection, conn.isVideoOrientationSupported {
      conn.videoOrientation = video
    }
  }

  // MARK: - Sample buffer delegate

  func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    latestPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    analyzer.analyze(sampleBuffer)
  }
}
