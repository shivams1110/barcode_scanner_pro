/// Lifecycle states of the native scanner, surfaced to Flutter via a
/// [ValueNotifier] on the controller.
enum ScannerState {
  /// Created but [initialize] has not completed.
  uninitialized,

  /// Camera and analyzer are being configured.
  initializing,

  /// Ready, but not actively decoding (camera may be previewing).
  ready,

  /// Actively previewing and decoding frames.
  scanning,

  /// Preview/decoding temporarily halted; camera session retained.
  paused,

  /// Fully stopped; camera session released.
  stopped,

  /// A non-recoverable error occurred. Inspect the controller error stream.
  error;

  static ScannerState fromIndex(int i) =>
      i >= 0 && i < values.length ? values[i] : uninitialized;
}
