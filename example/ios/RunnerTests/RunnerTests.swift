import Flutter
import UIKit
import XCTest


@testable import barcode_scanner_pro

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testGetPlatformVersion() {
    let plugin = BarcodeScannerProPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testAutoZoomStep() {
    // Big code: no zoom.
    XCTAssertNil(FrameAnalyzer.zoomStep(for: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.2)))
    // Small centred code: grow to ~50%.
    let centred = FrameAnalyzer.zoomStep(for: CGRect(x: 0.45, y: 0.45, width: 0.1, height: 0.05))
    XCTAssertEqual(centred!, 5, accuracy: 0.001)
    // Small code near the edge: capped so it stays in frame (reach 0.4 -> 1.125 < 1.25).
    XCTAssertNil(FrameAnalyzer.zoomStep(for: CGRect(x: 0.8, y: 0.45, width: 0.1, height: 0.05)))
    // Off-centre but zoomable: reach 0.25 -> capped at 1.8.
    let off = FrameAnalyzer.zoomStep(for: CGRect(x: 0.65, y: 0.45, width: 0.1, height: 0.05))
    XCTAssertEqual(off!, 1.8, accuracy: 0.001)
  }

  func testZoomSearchFlipsOnlyWhileNothingIsFound() {
    var s = ZoomSearch()
    XCTAssertNil(s.update(found: false, now: 0))  // empty stretch starts
    XCTAssertNil(s.update(found: false, now: 1.4))
    XCTAssertEqual(s.update(found: false, now: 1.5), true)  // zoom in
    XCTAssertNil(s.update(found: false, now: 2.9))
    XCTAssertEqual(s.update(found: false, now: 3.0), false)  // back out
    XCTAssertEqual(s.update(found: false, now: 4.5), true)
    // A code in view holds the current zoom, however long it stays.
    XCTAssertNil(s.update(found: true, now: 5))
    XCTAssertNil(s.update(found: true, now: 9))
    // Once it leaves, the timer restarts from the next empty frame.
    XCTAssertNil(s.update(found: false, now: 10))
    XCTAssertNil(s.update(found: false, now: 11))
    XCTAssertEqual(s.update(found: false, now: 11.5), false)
    s.reset()
    XCTAssertFalse(s.zoomed)
  }

  func testScanAreaAccountsForAspectFillCrop() {
    // 720x1280 upright frame in a 390x844 view: only the middle ~82% of the
    // width is visible.
    let area = ScanAreaConfig(left: 0.125, top: 0.125, width: 0.75, height: 0.75)
    let image = CGSize(width: 720, height: 1280)
    let view = CGSize(width: 390, height: 844)
    func box(_ x: CGFloat) -> CGRect { CGRect(x: x - 0.01, y: 0.49, width: 0.02, height: 0.02) }
    XCTAssertTrue(CoordinateMapper.isInside(box: box(0.5), area: area, imageSize: image, viewSize: view))
    // x = 0.15 of the frame is inside the area uncropped, but only ~7% across the view.
    XCTAssertFalse(CoordinateMapper.isInside(box: box(0.15), area: area, imageSize: image, viewSize: view))
    XCTAssertTrue(CoordinateMapper.isInside(box: box(0.15), area: area, imageSize: image, viewSize: .zero))
  }

}
