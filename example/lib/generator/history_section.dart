import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/code_preview.dart';
import 'widgets/section_scaffold.dart';

/// Displays the in-memory list of [BarcodeRequest]s recorded during the session.
///
/// Note: history is in-memory only — it is cleared when the app restarts.
class HistorySection extends StatelessWidget {
  const HistorySection({super.key, required this.history});

  final List<BarcodeRequest> history;

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'In-memory only — cleared on app restart.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Center(child: Text('No codes yet — generate one.'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, i) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final req = history[i];
                return ListTile(
                  title: Text(req.data),
                  subtitle: Text(req.format.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pushDetail(context, req),
                );
              },
            ),
        ],
      ),
    );
  }

  void _pushDetail(BuildContext context, BarcodeRequest req) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SectionScaffold(
          title: req.data,
          child: CodePreview(
            child: BarcodeWidget(
              data: req.data,
              format: req.format,
              width: 240,
              height: 240,
            ),
          ),
        ),
      ),
    );
  }
}
