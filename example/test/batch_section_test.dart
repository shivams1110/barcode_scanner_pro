import 'package:barcode_scanner_pro_example/generator/batch_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatchSection', () {
    testWidgets(
        'shows elapsed-ms text and grid after Generate with small count',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BatchSection()));

      // The slider starts at 10 (min). No need to drag it — just tap Generate.
      final generateBtn = find.widgetWithText(ElevatedButton, 'Generate');
      expect(generateBtn, findsOneWidget);

      // generateBatch is real async (rasterizes); use runAsync so it completes.
      // Tap first so _startGenerate() runs and lastRun is assigned, then await
      // the actual future — no fixed sleep.
      await tester.runAsync(() async {
        await tester.tap(generateBtn);
        final state =
            tester.state<BatchSectionState>(find.byType(BatchSection));
        await state.lastRun;
      });

      // Pump frames so setState rebuilds land.
      await tester.pump();

      // Elapsed-ms text must appear: e.g. "Generated 10 in 42 ms"
      expect(find.textContaining('ms'), findsOneWidget);
      // Grid must be present.
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
