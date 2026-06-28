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
    _controller =
        TextEditingController(text: _defaultData[_format] ?? 'ABC-123');
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
    setState(() {
      _format = value;
      _controller.text = _defaultData[value] ?? '';
    });
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

    final canRender = switch (validity) {
      _Valid() => true,
      _NoChecksum() => true,
      _Invalid() => false,
    };

    final Widget preview;
    if (!canRender) {
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
      preview = BarcodeWidget(
        data: _text,
        format: _format,
        width: 280,
        height: 120,
        showText: true,
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
