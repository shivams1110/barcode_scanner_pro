import CoreMedia
import ImageIO
import Vision

/// The decoding hot path on iOS. Invoked per video frame on the capture queue.
///
///  - **skips frames** to honor the FPS cap (preview is unaffected);
///  - reuses a single `VNDetectBarcodesRequest` (no per-frame allocation);
///  - filters detections to the configured **scan area**;
///  - requires **multi-frame confirmation** before a payload is trusted;
///  - applies the **duplicate filter** and honors the **scan mode**.
///
/// Results are emitted via [onBarcodes] as already-serialized dictionaries.
final class FrameAnalyzer {
  private let config: ScannerConfig
  private let request: VNDetectBarcodesRequest
  private let dupFilter: DuplicateFilter
  private let confirmGate: ConfirmationGate
  private let onBarcodes: ([[String: Any?]]) -> Void
  private let onError: (String) -> Void

  private var lastAnalyzed: CFTimeInterval = 0
  private var lastZoom: CFTimeInterval = 0

  private var zoomSearch = ZoomSearch()

  /// Auto-zoom hook, set when `enableAutoZoom` is on: called with a relative
  /// zoom multiplier (> 1) when a located code is too small to read reliably.
  var onZoomSuggestion: ((CGFloat) -> Void)?

  /// Auto-zoom hook, set when `enableAutoZoom` is on: called with `true` to
  /// zoom in and `false` to zoom back out while nothing is found (see
  /// `ZoomSearch`).
  var onZoomSearch: ((Bool) -> Void)?

  /// Gate toggled by start/pause/stop.
  var active: Bool = false

  /// Orientation used to present frames upright to Vision. Updated by the
  /// camera manager on device-orientation changes.
  var orientation: CGImagePropertyOrientation = .right

  /// Size of the aspect-fill preview, so the scan area can be matched against
  /// the visible part of the frame. Set on main by the platform view.
  // ponytail: unsynchronized CGSize read on the capture queue; it only changes
  // on layout, so a torn read just costs one frame's area check.
  var previewSize: CGSize = .zero

  init(
    config: ScannerConfig,
    onBarcodes: @escaping ([[String: Any?]]) -> Void,
    onError: @escaping (String) -> Void
  ) {
    self.config = config
    self.dupFilter = DuplicateFilter(timeoutMs: config.duplicateTimeoutMs)
    self.confirmGate = ConfirmationGate(required: config.confirmations)
    self.onBarcodes = onBarcodes
    self.onError = onError
    self.request = VNDetectBarcodesRequest()
    // Revision left at the default: Vision picks the newest the OS ships.
    self.request.symbologies = FormatMapper.toSymbologies(config.formatMask)
  }

  /// Clears per-scan state; called on start/resume.
  func resetScanState() {
    dupFilter.reset()
    confirmGate.reset()
    zoomSearch.reset()
  }

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
    let view = previewSize
    let inArea = (request.results ?? []).filter {
      CoordinateMapper.isInside(
        box: $0.boundingBox, area: config.scanArea, imageSize: oriented, viewSize: view)
    }
    if let search = onZoomSearch, let zoomed = zoomSearch.update(found: !inArea.isEmpty, now: now) {
      search(zoomed)
    }
    if inArea.isEmpty { return }
    suggestZoom(inArea, now: now)
    handle(inArea, orientedSize: oriented, now: now)
  }

  /// Vision has no zoom suggestion like ML Kit's, so size it ourselves. The
  /// cooldown lets the lens settle and refocus before the next step.
  private func suggestZoom(_ results: [VNBarcodeObservation], now: CFTimeInterval) {
    guard let zoom = onZoomSuggestion, now - lastZoom > 0.3,
      let step = results.compactMap({ Self.zoomStep(for: $0.boundingBox) }).min()
    else { return }
    lastZoom = now
    zoom(step)
  }

  /// Relative zoom that grows [box] (normalized) from under 25% of the frame
  /// to about 50%, capped so it stays in frame — zoom scales about the centre,
  /// so an off-centre code would otherwise be pushed out. nil = leave as is.
  // ponytail: fixed 25%/50% thresholds; expose them if dense codes need more.
  static func zoomStep(for box: CGRect) -> CGFloat? {
    let size = max(box.width, box.height)
    guard size > 0, size < 0.25 else { return nil }
    let reach = max(
      abs(box.minX - 0.5), abs(box.maxX - 0.5), abs(box.minY - 0.5), abs(box.maxY - 0.5))
    let fit = reach > 0 ? 0.45 / reach : .greatestFiniteMagnitude
    let step = min(0.5 / size, fit)
    return step >= 1.25 ? step : nil
  }

  /// Symbologies whose decode is already verified by ECC or a strong checksum.
  /// EAN/UPC are deliberately absent: a single mod-10 digit still lets misreads
  /// through (e.g. a partial EAN-13 decoded as UPC-E).
  static let selfChecking: Set<VNBarcodeSymbology> = [
    .qr, .dataMatrix, .aztec, .pdf417, .code128,
  ]

  /// [inArea]: detections already filtered to the scan area.
  private func handle(
    _ inArea: [VNBarcodeObservation], orientedSize: CGSize, now: CFTimeInterval
  ) {
    guard active else { return }

    // Trust a payload only once it has out-voted competing reads across
    // frames; see ConfirmationGate. Must run before the duplicate filter, which
    // would otherwise swallow the repeats that confirm a code.
    // Codes with a built-in checksum emit on the first decode; only the
    // checksum-free symbologies wait for votes.
    let confirmed = inArea.filter {
      Self.selfChecking.contains($0.symbology)
        || confirmGate.confirm(BarcodeMapper.dedupKey($0), now: now)
    }
    let fresh = confirmed.filter {
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

/// Blind zoom for codes Vision can't see yet. Vision reports only codes it has
/// decoded (unlike ML Kit, it never locates an unreadable one), so a far 1D
/// code gives no signal to zoom toward. Instead, after [interval] with nothing
/// in the scan area, flip between zoomed in and the starting zoom.
// ponytail: fixed 1.5s/2x cadence; expose it if users find the flipping too eager.
struct ZoomSearch {
  var interval: CFTimeInterval = 1.5
  private(set) var zoomed = false
  /// Start of the current empty stretch, or of the last flip within it.
  private var since: CFTimeInterval?

  /// Feeds one analyzed frame; returns the new zoomed state when it flips.
  mutating func update(found: Bool, now: CFTimeInterval) -> Bool? {
    if found {
      since = nil
      return nil
    }
    guard let start = since else {
      since = now
      return nil
    }
    guard now - start >= interval else { return nil }
    since = now
    zoomed.toggle()
    return zoomed
  }

  mutating func reset() {
    zoomed = false
    since = nil
  }
}
