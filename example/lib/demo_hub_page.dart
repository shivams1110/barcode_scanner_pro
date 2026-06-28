import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'generator/generate_barcode_section.dart';
import 'generator/generate_qr_section.dart';
import 'generator/gradient_qr_section.dart';
import 'generator/styled_qr_section.dart';
import 'scanner_page.dart';

/// Central navigation hub for the barcode_scanner_pro example app.
///
/// Owns the shared [BarcodeRequest] history, passed to generator sections via
/// [_remember]. Each tile routes to its section; sections not yet built show a
/// placeholder scaffold.
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

  /// Pushes a placeholder scaffold for sections not yet implemented.
  void _pushPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(
            child: Text('Arrives in a later step'),
          ),
        ),
      ),
    );
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
              MaterialPageRoute<void>(
                builder: (_) => const StyledQrSection(),
              ),
            ),
      ),
      (
        'Gradient QR',
        () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GradientQrSection(),
              ),
            ),
      ),
      (
        'Logo QR',
        () => _pushPlaceholder(context, 'Logo QR'),
      ),
      (
        'Save (PNG / SVG / PDF)',
        () => _pushPlaceholder(context, 'Save (PNG / SVG / PDF)'),
      ),
      (
        'Print Preview',
        () => _pushPlaceholder(context, 'Print Preview'),
      ),
      (
        'Batch Generation',
        () => _pushPlaceholder(context, 'Batch Generation'),
      ),
      (
        'Validation',
        () => _pushPlaceholder(context, 'Validation'),
      ),
      (
        'Image Decode',
        () => _pushPlaceholder(context, 'Image Decode'),
      ),
      (
        'History',
        () => _pushPlaceholder(context, 'History'),
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
            icon: Icon(
              widget.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
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
