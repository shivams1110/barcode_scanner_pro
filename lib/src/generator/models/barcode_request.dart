import 'package:flutter/foundation.dart';

import '../../domain/barcode_format.dart';
import 'barcode_options.dart';
import 'barcode_style.dart';

/// An immutable request to generate one barcode.
@immutable
class BarcodeRequest {
  const BarcodeRequest({
    required this.data,
    required this.format,
    this.style = const BarcodeStyle(),
    this.options = const BarcodeOptions(),
  });

  final String data;
  final BarcodeFormat format;
  final BarcodeStyle style;
  final BarcodeOptions options;

  bool get isQr => format == BarcodeFormat.qr;

  BarcodeRequest copyWith({
    String? data,
    BarcodeFormat? format,
    BarcodeStyle? style,
    BarcodeOptions? options,
  }) {
    return BarcodeRequest(
      data: data ?? this.data,
      format: format ?? this.format,
      style: style ?? this.style,
      options: options ?? this.options,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BarcodeRequest &&
      other.data == data &&
      other.format == format &&
      other.style == style &&
      other.options == options;

  @override
  int get hashCode => Object.hash(data, format, style, options);
}
