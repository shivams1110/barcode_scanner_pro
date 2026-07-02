#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import AppKit
import FlutterMacOS
#endif

/// Creates a `ScannerPlatformView` per Flutter platform view, capturing the
/// messenger so each view opens id-scoped method/event channels.
///
/// The `FlutterPlatformViewFactory` protocol differs across Darwin platforms:
/// on iOS `create` returns a `FlutterPlatformView` wrapper, while on macOS it
/// returns the backing `NSView` directly.
final class ScannerViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  #if os(iOS)
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?)
    -> FlutterPlatformView
  {
    ScannerPlatformView(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
  #elseif os(macOS)
  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    let scanner = ScannerPlatformView(
      frame: .zero, viewId: viewId, args: args, messenger: messenger)
    // The returned NSView owns the controller so it outlives this factory call.
    return scanner.platformView
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }
  #endif
}
