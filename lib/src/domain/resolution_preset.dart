/// Target capture resolution for the analysis pipeline.
///
/// Higher resolutions improve detection of small/dense codes (e.g. dense
/// PDF417) at the cost of throughput and memory. The native layer maps these
/// to the closest supported size.
enum ResolutionPreset {
  /// 480p — lowest latency, best battery.
  low,

  /// 720p — balanced default.
  medium,

  /// 1080p — better for dense/small codes.
  high,

  /// Highest available — maximum detail, highest cost.
  max;

  static ResolutionPreset fromIndex(int i) =>
      i >= 0 && i < values.length ? values[i] : medium;
}
