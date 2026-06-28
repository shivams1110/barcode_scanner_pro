import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'widgets/code_preview.dart';
import 'widgets/section_scaffold.dart';

/// Demonstrates saving a barcode as PNG, SVG, or PDF via [BarcodeGenerator].
class SaveSection extends StatefulWidget {
  const SaveSection({super.key});

  @override
  State<SaveSection> createState() => _SaveSectionState();
}

class _SaveSectionState extends State<SaveSection> {
  static const _req = BarcodeRequest(
    data: 'https://karnival.com',
    format: BarcodeFormat.qr,
  );
  static const _gen = BarcodeGenerator();

  bool _busy = false;

  Future<void> _savePng() async {
    setState(() => _busy = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = await _gen.saveAsPNG(_req, '${dir.path}/demo_qr.png');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PNG saved: ${file.path}')),
      );
    } on BarcodeGenException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveSvg() async {
    setState(() => _busy = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = await _gen.saveAsSVG(_req, '${dir.path}/demo_qr.svg');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SVG saved: ${file.path}')),
      );
    } on BarcodeGenException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePdf() async {
    setState(() => _busy = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = await _gen.saveAsPDF([_req], '${dir.path}/demo_qr.pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved: ${file.path}')),
      );
    } on BarcodeGenException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'Save (PNG / SVG / PDF)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CodePreview(
            child: BarcodeWidget(
              data: 'https://karnival.com',
              format: BarcodeFormat.qr,
              width: 200,
              height: 200,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _busy ? null : _savePng,
            child: const Text('Save PNG'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _busy ? null : _saveSvg,
            child: const Text('Save SVG'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _busy ? null : _savePdf,
            child: const Text('Save PDF'),
          ),
        ],
      ),
    );
  }
}
