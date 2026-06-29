import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'generator/generate_barcode_section.dart';
import 'generator/generate_qr_section.dart';
import 'generator/gradient_qr_section.dart';
import 'generator/logo_qr_section.dart';
import 'generator/print_preview_section.dart';
import 'generator/batch_section.dart';
import 'generator/save_section.dart';
import 'generator/styled_qr_section.dart';
import 'generator/image_decode_section.dart';
import 'generator/history_section.dart';
import 'generator/validation_section.dart';
import 'scanner_page.dart';

/// Central navigation hub for the barcode_scanner_pro example app.
///
/// Owns the shared [BarcodeRequest] history, passed to generator sections via
/// [_remember]. Each tile routes to its section.
class DemoHubPage extends StatefulWidget {
  const DemoHubPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<DemoHubPage> createState() => _DemoHubPageState();
}

class _DemoHubPageState extends State<DemoHubPage> {
  final List<BarcodeRequest> _history = [];

  void _remember(BarcodeRequest req) {
    setState(() => _history.insert(0, req));
  }

  @override
  Widget build(BuildContext context) {
    // (title, onTap) pairs — keeps the build method DRY.
    final tiles = <(String, VoidCallback)>[
      (
        'Generate QR',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GenerateQrSection(onGenerated: _remember),
          ),
        ),
      ),
      (
        'Generate Barcode',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const GenerateBarcodeSection(),
          ),
        ),
      ),
      (
        'Styled QR',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const StyledQrSection()),
        ),
      ),
      (
        'Gradient QR',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GradientQrSection()),
        ),
      ),
      (
        'Logo QR',
        () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const LogoQrSection())),
      ),
      (
        'Save (PNG / SVG / PDF)',
        () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SaveSection())),
      ),
      (
        'Print Preview',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PrintPreviewSection()),
        ),
      ),
      (
        'Batch Generation',
        () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const BatchSection())),
      ),
      (
        'Validation',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ValidationSection()),
        ),
      ),
      (
        'Image Decode',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ImageDecodeSection()),
        ),
      ),
      (
        'History',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HistorySection(history: _history),
          ),
        ),
      ),
      (
        'Scanner',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ScannerPage(
              isDark: widget.isDark,
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('barcode_scanner_pro demo'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: tiles.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final (title, onTap) = tiles[i];
          return ListTile(
            title: Text(title),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          );
        },
      ),
    );
  }
}
