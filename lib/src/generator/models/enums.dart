/// Visual shape of QR data modules. Ignored by linear symbologies.
enum ModuleShape { square, rounded, circular, diamond, classy }

/// Visual shape of the three QR finder ("eye") patterns.
enum EyeShape { square, rounded, circular, leaf }

/// QR error-correction level. [qrLevel] is the integer constant used by the
/// `qr` package's `QrErrorCorrectLevel` (M=0, L=1, H=2, Q=3).
enum ErrorCorrection {
  low(1),
  medium(0),
  quartile(3),
  high(2);

  const ErrorCorrection(this.qrLevel);

  /// Raw level constant expected by the `qr` package.
  final int qrLevel;
}

/// Render/export container format.
enum ExportFormat { png, svg, pdf }

/// Foreground gradient style.
enum GradientType { none, linear, radial, sweep }
