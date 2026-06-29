import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/section_scaffold.dart';

/// Demonstrates [BarcodeGenerator.generateBatch] by generating a configurable
/// number of Code-128 barcodes concurrently and displaying the results in a
/// grid with elapsed time.
class BatchSection extends StatefulWidget {
  const BatchSection({super.key});

  @override
  State<BatchSection> createState() => BatchSectionState();
}

// Public so tests can resolve it via tester.state<BatchSectionState>().
class BatchSectionState extends State<BatchSection> {
  static const int _minCount = 10;
  static const int _maxCount = 500;
  static const int _divisions = 49; // one step per 10 barcodes

  double _count = _minCount.toDouble();
  bool _busy = false;
  int? _elapsedMs;
  List<BarcodeGenResult>? _results;
  String? _errorMessage;

  /// Stores the in-flight [_generate] future. Tests may await this to
  /// deterministically wait for rasterization without any fixed sleep.
  @visibleForTesting
  Future<void>? lastRun;

  void _startGenerate() => lastRun = _generate();

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _elapsedMs = null;
      _results = null;
      _errorMessage = null;
    });

    final count = _count.round();
    final requests = List.generate(
      count,
      (i) => BarcodeRequest(
        data: 'ITEM-${i.toString().padLeft(5, '0')}',
        format: BarcodeFormat.code128,
      ),
    );

    final stopwatch = Stopwatch()..start();
    try {
      final results = await const BarcodeGenerator().generateBatch(
        requests,
        concurrency: 8,
      );
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _elapsedMs = stopwatch.elapsedMilliseconds;
        _results = results;
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _count.round();

    return SectionScaffold(
      title: 'Batch Generation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Count: $count'),
          Slider(
            value: _count,
            min: _minCount.toDouble(),
            max: _maxCount.toDouble(),
            divisions: _divisions,
            label: '$count',
            onChanged: _busy ? null : (value) => setState(() => _count = value),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _busy ? null : _startGenerate,
            child: const Text('Generate'),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (_elapsedMs != null && _results != null) ...[
            const SizedBox(height: 12),
            Text(
              'Generated ${_results!.length} in $_elapsedMs ms',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 2,
              ),
              itemCount: _results!.length,
              itemBuilder: (context, index) {
                final result = _results![index];
                return Image(image: result.toMemoryImage());
              },
            ),
          ],
        ],
      ),
    );
  }
}
