import Flutter
import Foundation

/// Thread-safe bridge to a Flutter `FlutterEventChannel`. Frame analysis runs on
/// a background queue, but the event sink must be invoked on the main thread —
/// this marshals every emission to main and tolerates the absence of a listener.
final class EventDispatcher: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(
    withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func send(_ payload: [String: Any?]) {
    guard let sink = sink else { return }
    if Thread.isMainThread {
      sink(payload)
    } else {
      DispatchQueue.main.async { [weak self] in self?.sink?(payload) }
    }
  }

  func sendError(_ code: String, _ message: String?) {
    send(["type": EventType.error, "code": code, "message": message as Any?])
  }

  func dispose() { sink = nil }
}
