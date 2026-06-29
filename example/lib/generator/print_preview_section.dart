import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'widgets/section_scaffold.dart';

/// Sample requests used for the print preview: two QR codes and two linear
/// codes to demonstrate mixed-symbology grid layout.
const _requests = <BarcodeRequest>[
  BarcodeRequest(data: 'https://karnival.com', format: BarcodeFormat.qr),
  BarcodeRequest(data: 'HELLO-WORLD', format: BarcodeFormat.code128),
  BarcodeRequest(data: 'https://flutter.dev', format: BarcodeFormat.qr),
  BarcodeRequest(data: '0123456789', format: BarcodeFormat.code39),
];

/// Demonstrates PDF print/preview via the OS printing sheet.
///
/// Taps [Printing.layoutPdf] with a 2-column × 4-row grid layout built from
/// [_requests].  The [LayoutCallback] receives a [PdfPageFormat] on each
/// invocation (e.g. when the user changes paper size in the OS dialog) and
/// returns the re-rendered PDF bytes.
class PrintPreviewSection extends StatefulWidget {
  const PrintPreviewSection({super.key});

  @override
  State<PrintPreviewSection> createState() => _PrintPreviewSectionState();
}

class _PrintPreviewSectionState extends State<PrintPreviewSection> {
  bool _busy = false;

  Future<void> _printPreview() async {
    setState(() => _busy = true);
    try {
      // LayoutCallback = FutureOr<Uint8List> Function(PdfPageFormat)
      // generatePdf returns Future<Uint8List> — satisfies LayoutCallback.
      // The `format` parameter is forwarded to generatePdf so the renderer
      // can respect the paper size chosen in the OS print dialog.
      await Printing.layoutPdf(
        onLayout: (_) => const BarcodeGenerator().generatePdf(
          _requests,
          layout: const BarcodePdfLayout.grid(columns: 2, rows: 4),
        ),
        name: 'Barcode Print Preview',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Print error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'Print Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Opens the OS print / preview sheet with a 2-column × 4-row grid '
            'of four sample barcodes (two QR codes and two linear codes). '
            'The PDF is regenerated each time the user changes paper size or '
            'orientation in the OS dialog.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _busy ? null : _printPreview,
            icon: const Icon(Icons.print),
            label: Text(_busy ? 'Opening…' : 'Print / Preview'),
          ),
        ],
      ),
    );
  }
}
