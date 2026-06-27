import CoreMedia
import ImageIO
import Vision

/// The decoding hot path on iOS. Invoked per video frame on the capture queue.
///
///  - **skips frames** to honor the FPS cap (preview is unaffected);
///  - reuses a single `VNDetectBarcodesRequest` (no per-frame allocation);
///  - filters detections to the configured **scan area**;
///  - applies the **duplicate filter** and honors the **scan mode**.
///
/// Results are emitted via [onBarcodes] as already-serialized dictionaries.
final class FrameAnalyzer {
  private let config: ScannerConfig
  private let request: VNDetectBarcodesRequest
  private let dupFilter: DuplicateFilter
  private let onBarcodes: ([[String: Any?]]) -> Void
  private let onError: (String) -> Void

  private var lastAnalyzed: CFTimeInterval = 0

  /// Gate toggled by start/pause/stop.
  var active: Bool = false

  /// Orientation used to present frames upright to Vision. Updated by the
  /// camera manager on device-orientation changes.
  var orientation: CGImagePropertyOrientation = .right

  init(
    config: ScannerConfig,
    onBarcodes: @escaping ([[String: Any?]]) -> Void,
    onError: @escaping (String) -> Void
  ) {
    self.config = config
    self.dupFilter = DuplicateFilter(timeoutMs: config.duplicateTimeoutMs)
    self.onBarcodes = onBarcodes
    self.onError = onError
    self.request = VNDetectBarcodesRequest()
    self.request.symbologies = FormatMapper.toSymbologies(config.formatMask)
    if #available(iOS 17.0, *) {
      // Hint Vision toward low-latency single-frame decoding.
      self.request.revision = VNDetectBarcodesRequestRevision3
    }
  }

  func resetDuplicates() { dupFilter.reset() }

  func analyze(_ sampleBuffer: CMSampleBuffer) {
    guard active else { return }
    let now = CACurrentMediaTime()
    if now - lastAnalyzed < config.frameInterval { return }  // frame skip
    lastAnalyzed = now

    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let oriented = CoordinateMapper.orientedSize(
      width: width, height: height, orientation: orientation)

    let handler = VNImageRequestHandler(
      cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
    do {
      try handler.perform([request])
    } catch {
      onError(error.localizedDescription)
      return
    }
    guard let results = request.results, !results.isEmpty else { return }
    handle(results, orientedSize: oriented, now: now)
  }

  private func handle(
    _ results: [VNBarcodeObservation], orientedSize: CGSize, now: CFTimeInterval
  ) {
    guard active else { return }

    let inArea = results.filter {
      CoordinateMapper.isInside(box: $0.boundingBox, area: config.scanArea)
    }
    let fresh = inArea.filter {
      dupFilter.shouldEmit(BarcodeMapper.dedupKey($0), now: now)
    }
    if fresh.isEmpty { return }

    let epochMs = Int64(Date().timeIntervalSince1970 * 1000)
    func map(_ o: VNBarcodeObservation) -> [String: Any?] {
      BarcodeMapper.toMap(o, orientedSize: orientedSize, timestampMs: epochMs)
    }

    switch config.scanMode {
    case 0:  // single
      active = false
      if let first = fresh.first { onBarcodes([map(first)]) }
    case 2:  // multi
      onBarcodes(fresh.map(map))
    default:  // continuous
      if !config.continuousScanning { active = false }
      onBarcodes(fresh.map(map))
    }
  }
}
