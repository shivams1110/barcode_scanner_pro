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
  /// Frames are decoded here, so a slow Vision pass never delays torch, zoom
  /// or focus changes queued on `sessionQueue`.
  private let videoQueue = DispatchQueue(label: "com.umda.barcode_scanner_pro.video")
  private let videoOutput = AVCaptureVideoDataOutput()
  private let analyzer: FrameAnalyzer
  private let events: EventDispatcher
  private let ciContext = CIContext()

  private var device: AVCaptureDevice?
  private var position: AVCaptureDevice.Position = .back
  private var latestPixelBuffer: CVPixelBuffer?
  /// True while the zoom is where auto-zoom put it. Session queue only.
  private var autoZoomed = false
  /// Lowest zoom used (slider 0). Raised above 1 on lenses that can't focus
  /// close (iPhone 13 Pro and later) — see `minimumZoom`. Session queue only.
  private var baseZoom: CGFloat = 1
  /// Set once the user pinches or drags the slider; zoom search then stays
  /// out of their way for the rest of the session. Session queue only.
  private var userZoomed = false

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
        self.applyBaseZoom(config)
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

    if let preset = config.sessionPresets.first(where: session.canSetSessionPreset) {
      session.sessionPreset = preset
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
    videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    guard session.canAddOutput(videoOutput) else {
      throw ConfigError(code: ErrorCode.initializationFailed, message: "Cannot add video output")
    }
    session.addOutput(videoOutput)

    if config.enableAutoFocus, camera.isFocusModeSupported(.continuousAutoFocus),
      (try? camera.lockForConfiguration()) != nil
    {
      camera.focusMode = .continuousAutoFocus
      // Barcodes are usually held close: skip hunting through far focus
      // distances. Not with auto-zoom, which exists for distant codes.
      if camera.isAutoFocusRangeRestrictionSupported {
        camera.autoFocusRangeRestriction = config.enableAutoZoom ? .none : .near
      }
      camera.unlockForConfiguration()
    }
  }

  /// Zooms to the minimum zoom for the current lens; called after the session
  /// is configured so `activeFormat` reflects the chosen preset.
  private func applyBaseZoom(_ config: ScannerConfig) {
    guard let d = device else { return }
    baseZoom = position == .back ? Self.minimumZoom(for: d, areaWidth: config.scanArea.width) : 1
    autoZoomed = false
    if Self.setZoomFactor(d, baseZoom) {
      events.send(["type": EventType.zoomChanged, "zoom": 0.0])
    }
  }

  /// Apple's AVCamBarcode recipe (WWDC21): zoom in just enough that a code
  /// filling the scan area sits at or beyond the lens' minimum focus distance.
  /// Without it, Pro iPhones (~20cm minimum focus) show close codes blurry.
  // ponytail: assumes a ~20mm-wide code; tiny codes may still need manual zoom.
  static func minimumZoom(for device: AVCaptureDevice, areaWidth: Double) -> CGFloat {
    guard #available(iOS 15.0, *) else { return 1 }
    let minFocusMm = Float(device.minimumFocusDistance)
    guard minFocusMm > 0 else { return 1 }
    let halfFov = device.activeFormat.videoFieldOfView / 2 * .pi / 180
    let subjectMm = 20 / Float(max(areaWidth, 0.1)) / tan(halfFov)
    guard subjectMm < minFocusMm else { return 1 }
    return min(CGFloat(minFocusMm / subjectMm), device.activeFormat.videoMaxZoomFactor)
  }

  /// Highest zoom offered: 8x or the format limit, never below `baseZoom`.
  private func maxZoom(_ d: AVCaptureDevice) -> CGFloat {
    max(min(d.activeFormat.videoMaxZoomFactor, 8.0), baseZoom)
  }

  /// [factor] as the `[0,1]` value `setZoom` takes, so the Dart slider follows.
  private func linearZoom(_ factor: CGFloat, max maxFactor: CGFloat) -> Double {
    maxFactor > baseZoom ? Double((factor - baseZoom) / (maxFactor - baseZoom)) : 0
  }

  @discardableResult
  private static func setZoomFactor(_ d: AVCaptureDevice, _ factor: CGFloat) -> Bool {
    guard (try? d.lockForConfiguration()) != nil else { return false }
    d.videoZoomFactor = factor
    d.unlockForConfiguration()
    return true
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
      self.applyBaseZoom(config)
      self.events.send([
        "type": EventType.cameraChanged,
        "camera": self.position == .front ? 1 : 0,
      ])
    }
  }

  func pauseAnalysis() { analyzer.active = false }

  func resumeAnalysis() {
    // Start each scan wide again: auto-zoom only zooms in, so a near code
    // after a far one would otherwise overflow the frame.
    sessionQueue.async { [weak self] in
      guard let self = self, self.autoZoomed, let d = self.device else { return }
      Self.setZoomFactor(d, self.baseZoom)
      self.autoZoomed = false
      self.events.send(["type": EventType.zoomChanged, "zoom": 0.0])
    }
    analyzer.resetScanState()
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
      self?.videoQueue.async { self?.latestPixelBuffer = nil }
    }
  }

  // MARK: - Controls

  func setTorch(_ on: Bool) {
    sessionQueue.async { [weak self] in
      guard let d = self?.device, d.hasTorch, (try? d.lockForConfiguration()) != nil else { return }
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
      guard let self = self, let d = self.device else { return }
      self.userZoomed = true
      let maxFactor = self.maxZoom(d)
      let factor = self.baseZoom + CGFloat(max(0, min(1, value))) * (maxFactor - self.baseZoom)
      Self.setZoomFactor(d, factor)
      self.events.send(["type": EventType.zoomChanged, "zoom": value])
    }
  }

  /// Auto-zoom: multiplies the current zoom by [step], capped like `setZoom`.
  // ponytail: in continuous mode zoom stays until the next start/resume.
  func zoomIn(by step: CGFloat) {
    sessionQueue.async { [weak self] in
      guard let self = self, let d = self.device else { return }
      let maxFactor = self.maxZoom(d)
      let factor = min(d.videoZoomFactor * step, maxFactor)
      guard factor > d.videoZoomFactor, Self.setZoomFactor(d, factor) else { return }
      self.autoZoomed = true
      self.events.send([
        "type": EventType.zoomChanged, "zoom": self.linearZoom(factor, max: maxFactor),
      ])
    }
  }

  /// Zoom search (see `ZoomSearch`): 2x the starting zoom, or back to it.
  /// Ignored once the user has zoomed by hand.
  func searchZoom(_ zoomed: Bool) {
    sessionQueue.async { [weak self] in
      guard let self = self, !self.userZoomed, let d = self.device else { return }
      let maxFactor = self.maxZoom(d)
      let factor = zoomed ? min(self.baseZoom * 2, maxFactor) : self.baseZoom
      guard factor != d.videoZoomFactor, Self.setZoomFactor(d, factor) else { return }
      self.autoZoomed = factor != self.baseZoom
      self.events.send([
        "type": EventType.zoomChanged, "zoom": self.linearZoom(factor, max: maxFactor),
      ])
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
      guard (try? d.lockForConfiguration()) != nil else { return }
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
      guard let d = self?.device, (try? d.lockForConfiguration()) != nil else { return }
      // Continuous modes re-centre on the tapped point but keep tracking, so a
      // code at another distance still comes into focus afterwards. One-shot
      // `.autoFocus`/`.autoExpose` would lock there until the next restart.
      if d.isFocusPointOfInterestSupported, d.isFocusModeSupported(.continuousAutoFocus) {
        d.focusPointOfInterest = devicePoint
        d.focusMode = .continuousAutoFocus
      }
      if d.isExposurePointOfInterestSupported, d.isExposureModeSupported(.continuousAutoExposure) {
        d.exposurePointOfInterest = devicePoint
        d.exposureMode = .continuousAutoExposure
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
