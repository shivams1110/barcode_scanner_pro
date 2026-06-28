import 'dart:typed_data';

import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/code_preview.dart';
import 'widgets/section_scaffold.dart';

/// Default sample data per format — guaranteed to be valid so the preview
/// shows something sensible on first load and after a format switch.
const Map<BarcodeFormat, String> _defaultData = {
  BarcodeFormat.code128: 'ABC-123',
  BarcodeFormat.code39: 'ABC-123',
  BarcodeFormat.code93: 'ABC-123',
  BarcodeFormat.ean8: '73513537',
  BarcodeFormat.ean13: '4006381333931',
  BarcodeFormat.upcA: '012345678905',
  BarcodeFormat.upcE: '01234565',
  BarcodeFormat.itf: '12345678901234',
  BarcodeFormat.codabar: 'A123456A',
  BarcodeFormat.pdf417: 'PDF417 DATA',
  BarcodeFormat.aztec: 'AZTEC DATA',
  BarcodeFormat.dataMatrix: 'DATAMATRIX',
};

String _defaultFor(BarcodeFormat f) => _defaultData[f] ?? 'ABC-123';

/// Ordered list of the 12 non-QR formats shown in the dropdown.
const List<BarcodeFormat> _linearFormats = [
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.ean8,
  BarcodeFormat.ean13,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.itf,
  BarcodeFormat.codabar,
  BarcodeFormat.pdf417,
  BarcodeFormat.aztec,
  BarcodeFormat.dataMatrix,
];

/// Returns a human-readable label for a [BarcodeFormat].
String _label(BarcodeFormat f) {
  return switch (f) {
    BarcodeFormat.code128 => 'Code 128',
    BarcodeFormat.code39 => 'Code 39',
    BarcodeFormat.code93 => 'Code 93',
    BarcodeFormat.ean8 => 'EAN-8',
    BarcodeFormat.ean13 => 'EAN-13',
    BarcodeFormat.upcA => 'UPC-A',
    BarcodeFormat.upcE => 'UPC-E',
    BarcodeFormat.itf => 'ITF',
    BarcodeFormat.codabar => 'Codabar',
    BarcodeFormat.pdf417 => 'PDF 417',
    BarcodeFormat.aztec => 'Aztec',
    BarcodeFormat.dataMatrix => 'Data Matrix',
    _ => f.name,
  };
}

/// Result of checking whether [data] is encodable in [format].
sealed class _Validity {
  const _Validity();
}

final class _Valid extends _Validity {
  const _Valid();
}

final class _Invalid extends _Validity {
  const _Invalid(this.reason);
  final String reason;
}

final class _NoChecksum extends _Validity {
  const _NoChecksum();
}

/// Validates [data] against [format] using [BarcodeValidator] where available.
_Validity _validate(BarcodeFormat format, String data) {
  if (data.isEmpty) return const _Invalid('data is empty');
  return switch (format) {
    BarcodeFormat.ean13 => BarcodeValidator.isValidEAN13(data)
        ? const _Valid()
        : const _Invalid('must be 13 digits with valid check digit'),
    BarcodeFormat.ean8 => BarcodeValidator.isValidEAN8(data)
        ? const _Valid()
        : const _Invalid('must be 8 digits with valid check digit'),
    BarcodeFormat.upcA => BarcodeValidator.isValidUPC(data)
        ? const _Valid()
        : const _Invalid('must be 12 digits with valid check digit'),
    BarcodeFormat.code128 => BarcodeValidator.isValidCode128(data)
        ? const _Valid()
        : const _Invalid('contains characters not encodable in Code 128'),
    BarcodeFormat.code39 => BarcodeValidator.isValidCode39(data)
        ? const _Valid()
        : const _Invalid(
            'must be uppercase A-Z, digits, or -, ., \$, /, +, %, space'),
    _ => const _NoChecksum(),
  };
}

/// Demonstrates live linear/2D barcode generation for the 12 non-QR formats.
///
/// The preview uses [BarcodeGenerator.generateBytes] inside a [FutureBuilder]
/// so that any [BarcodeGenException] thrown during encoding is caught in the
/// async future (via [AsyncSnapshot.hasError]) rather than inside
/// [CustomPainter.paint], where exceptions would crash the frame.
class GenerateBarcodeSection extends StatefulWidget {
  const GenerateBarcodeSection({super.key});

  @override
  State<GenerateBarcodeSection> createState() => _GenerateBarcodeSectionState();
}

class _GenerateBarcodeSectionState extends State<GenerateBarcodeSection> {
  BarcodeFormat _format = BarcodeFormat.code128;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _defaultFor(_format));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _text => _controller.text;

  void _onFormatChanged(BarcodeFormat? value) {
    if (value == null) return;
    _format = value;
    _controller.text = _defaultFor(value);
    // setState is triggered by the controller listener above.
  }

  @override
  Widget build(BuildContext context) {
    final validity = _validate(_format, _text);

    final validityLine = switch (validity) {
      _Valid() => const Text(
          'Valid',
          style: TextStyle(color: Colors.green),
        ),
      _Invalid(:final reason) => Text(
          'Invalid: $reason',
          style: const TextStyle(color: Colors.red),
        ),
      _NoChecksum() => const Text(
          'No checksum validation for this format',
          style: TextStyle(color: Colors.grey),
        ),
    };

    // Formats with a validator: only attempt render when valid.
    // Formats without a validator (NoChecksum): always attempt render,
    // but catch any BarcodeGenException in the async future so it never
    // reaches a CustomPainter.paint call.
    final bool skipRender = switch (validity) {
      _Invalid() => true,
      _ => false,
    };

    Widget preview;
    if (skipRender) {
      final reason = (validity as _Invalid).reason;
      preview = SizedBox(
        width: 280,
        height: 120,
        child: Center(
          child: Text(
            'Cannot encode: $reason',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } else {
      // Capture local copies for the closure so setState rebuilds produce a
      // fresh future rather than reusing a stale one.
      final capturedText = _text;
      final capturedFormat = _format;
      preview = FutureBuilder<Uint8List>(
        future: const BarcodeGenerator().generateBytes(
          BarcodeRequest(data: capturedText, format: capturedFormat),
        ),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
              width: 280,
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            final e = snap.error;
            final msg =
                e is BarcodeGenException ? e.message : '$e';
            return SizedBox(
              width: 280,
              height: 120,
              child: Center(
                child: Text(
                  'Cannot encode: $msg',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          return Image.memory(
            snap.data!,
            width: 280,
            height: 120,
            fit: BoxFit.contain,
          );
        },
      );
    }

    return SectionScaffold(
      title: 'Generate Barcode',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<BarcodeFormat>(
            isExpanded: true,
            value: _format,
            items: _linearFormats
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(_label(f)),
                  ),
                )
                .toList(),
            onChanged: _onFormatChanged,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Data',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          validityLine,
          const SizedBox(height: 8),
          CodePreview(child: preview),
        ],
      ),
    );
  }
}
