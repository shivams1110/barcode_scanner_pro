import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/code_preview.dart';
import 'widgets/section_scaffold.dart';

/// Demonstrates live QR code generation from user-entered text.
///
/// Accepts an optional [onGenerated] callback so the parent hub can record
/// each saved request into its history list.
class GenerateQrSection extends StatefulWidget {
  const GenerateQrSection({super.key, this.onGenerated});

  final void Function(BarcodeRequest)? onGenerated;

  @override
  State<GenerateQrSection> createState() => _GenerateQrSectionState();
}

class _GenerateQrSectionState extends State<GenerateQrSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'https://karnival.com');
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _text => _controller.text;

  void _saveToHistory() {
    widget.onGenerated?.call(
      BarcodeRequest(data: _text, format: BarcodeFormat.qr),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to history')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'Generate QR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Data',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          CodePreview(
            child: _text.isEmpty
                ? const SizedBox(
                    width: 240,
                    height: 240,
                    child: Center(child: Text('Enter text to generate a QR code')),
                  )
                : BarcodeWidget(
                    data: _text,
                    format: BarcodeFormat.qr,
                    width: 240,
                    height: 240,
                  ),
          ),
          ElevatedButton(
            onPressed: _text.isEmpty ? null : _saveToHistory,
            child: const Text('Save to history'),
          ),
        ],
      ),
    );
  }
}
