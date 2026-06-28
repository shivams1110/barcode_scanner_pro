import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/section_scaffold.dart';

/// Formats supported by [BarcodeValidator], shown in the dropdown.
const List<BarcodeFormat> _validatorFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
];

String _formatLabel(BarcodeFormat f) => switch (f) {
      BarcodeFormat.ean13 => 'EAN-13',
      BarcodeFormat.ean8 => 'EAN-8',
      BarcodeFormat.upcA => 'UPC-A',
      BarcodeFormat.code128 => 'Code 128',
      BarcodeFormat.code39 => 'Code 39',
      _ => f.name,
    };

bool _validate(BarcodeFormat format, String data) => switch (format) {
      BarcodeFormat.ean13 => BarcodeValidator.isValidEAN13(data),
      BarcodeFormat.ean8 => BarcodeValidator.isValidEAN8(data),
      BarcodeFormat.upcA => BarcodeValidator.isValidUPC(data),
      BarcodeFormat.code128 => BarcodeValidator.isValidCode128(data),
      BarcodeFormat.code39 => BarcodeValidator.isValidCode39(data),
      _ => false,
    };

/// Demonstrates [BarcodeValidator]: live validity check + checksum for the
/// five symbologies the validator supports (EAN-13, EAN-8, UPC-A, Code 128,
/// Code 39).
class ValidationSection extends StatefulWidget {
  const ValidationSection({super.key});

  @override
  State<ValidationSection> createState() => _ValidationSectionState();
}

class _ValidationSectionState extends State<ValidationSection> {
  BarcodeFormat _format = BarcodeFormat.ean13;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '4006381333931');
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _data => _controller.text;

  void _onFormatChanged(BarcodeFormat? value) {
    if (value == null) return;
    setState(() => _format = value);
  }

  /// Calls [BarcodeValidator.calculateChecksum] with the payload minus its
  /// trailing check digit, then displays the computed value alongside the
  /// digit the user actually entered. Catches [BarcodeGenException] for
  /// formats (Code 128, Code 39) that have no standalone numeric checksum.
  String _checksumLine() {
    if (_data.isEmpty) return 'no standalone checksum for this format';
    try {
      // calculateChecksum expects the digits BEFORE the check digit.
      final body = _data.length > 1
          ? _data.substring(0, _data.length - 1)
          : _data;
      final computed = BarcodeValidator.calculateChecksum(_format, body);
      final entered = _data[_data.length - 1];
      return 'Computed check digit: $computed'
          ' (entered last digit: $entered)';
    } on BarcodeGenException {
      return 'no standalone checksum for this format';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _validate(_format, _data);

    return SectionScaffold(
      title: 'Validation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<BarcodeFormat>(
            isExpanded: true,
            value: _format,
            items: _validatorFormats
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(_formatLabel(f)),
                  ),
                )
                .toList(),
            onChanged: _onFormatChanged,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Barcode data',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.cancel,
                color: isValid ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isValid ? 'valid' : 'invalid',
                style: TextStyle(
                  color: isValid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _checksumLine(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
