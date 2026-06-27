/// A normalized region of the preview within which decoding is performed.
///
/// Coordinates are fractions in `[0, 1]` relative to the preview's logical
/// size (origin top-left). Restricting the scan area lets the native layer crop
/// frames before decoding, which both reduces CPU cost and prevents accidental
/// scans of codes outside the user's intended target.
class ScanArea {
  const ScanArea({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  })  : assert(left >= 0 && left <= 1),
        assert(top >= 0 && top <= 1),
        assert(width > 0 && left + width <= 1.0000001),
        assert(height > 0 && top + height <= 1.0000001);

  final double left;
  final double top;
  final double width;
  final double height;

  /// The full preview — no cropping.
  static const ScanArea full = ScanArea(left: 0, top: 0, width: 1, height: 1);

  /// A centered square occupying [fraction] of the smaller dimension.
  factory ScanArea.centeredSquare({double fraction = 0.7}) {
    final inset = (1 - fraction) / 2;
    return ScanArea(
      left: inset,
      top: inset,
      width: fraction,
      height: fraction,
    );
  }

  bool get isFull =>
      left == 0 && top == 0 && width == 1 && height == 1;

  Map<String, double> toMap() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };
}
