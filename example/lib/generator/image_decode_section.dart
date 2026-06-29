import 'dart:typed_data';

import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/section_scaffold.dart';

/// Demonstrates image decode round-trip:
/// 1. Generate a QR PNG from user text via [BarcodeGenerator.generateBytes].
/// 2. Decode the PNG back via [BarcodeGenerator.decodeImage] (native ML Kit /
///    Vision Framework).
///
/// Decoding requires a real device or simulator; it degrades gracefully
/// (shows an error message) in headless / unsupported contexts.
class ImageDecodeSection extends StatefulWidget {
  const ImageDecodeSection({super.key});

  @override
  State<ImageDecodeSection> createState() => _ImageDecodeSectionState();
}

class _ImageDecodeSectionState extends State<ImageDecodeSection> {
  late final TextEditingController _controller;

  bool _busy = false;
  Uint8List? _png;
  List<BarcodeDecodeResult>? _codes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'https://karnival.com');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateAndDecode() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _busy = true;
      _png = null;
      _codes = null;
      _error = null;
    });

    try {
      final gen = const BarcodeGenerator();
      final req = BarcodeRequest(data: text, format: BarcodeFormat.qr);

      final png = await gen.generateBytes(req);
      if (!mounted) return;

      List<BarcodeDecodeResult> codes;
      try {
        codes = await gen.decodeImage(png);
      } on BarcodeGenException catch (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _png = png;
          _error = 'Decode failed (BarcodeGenException): ${e.message}';
        });
        return;
      } on UnimplementedError catch (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _png = png;
          _error =
              'Decode not available on this platform (UnimplementedError): ${e.message}';
        });
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _png = png;
          _error = 'Decode error: $e';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _busy = false;
        _png = png;
        _codes = codes;
      });
    } on BarcodeGenException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Generate failed (BarcodeGenException): ${e.message}';
      });
    } on UnimplementedError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'Generate not available on this platform (UnimplementedError): ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'Image Decode',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Persistent info banner
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Image decode runs on the native scanner (ML Kit/Vision) — '
                'works on a real device/simulator. '
                'See doc/DECODE_VERIFICATION.md. '
                'iOS reports UPC-A as EAN-13.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Input field
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Data to encode',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Action button
          ElevatedButton(
            onPressed: _busy ? null : _generateAndDecode,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate & Decode'),
          ),

          // PNG preview
          if (_png != null) ...[
            const SizedBox(height: 20),
            Text(
              'Generated PNG',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Center(
              child: Image.memory(
                _png!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ],

          // Error display
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],

          // Decoded results
          if (_codes != null) ...[
            const SizedBox(height: 16),
            Text(
              'Decoded barcodes (${_codes!.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_codes!.isEmpty)
              const Text('No barcodes found in image.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _codes!.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final code = _codes![index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.qr_code),
                    title: Text(code.value),
                    subtitle: Text(code.format.name),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
