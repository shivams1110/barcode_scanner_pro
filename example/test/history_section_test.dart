import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:barcode_scanner_pro_example/generator/history_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistorySection', () {
    testWidgets('shows entry when history is non-empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HistorySection(
            history: [
              BarcodeRequest(data: 'x', format: BarcodeFormat.qr),
            ],
          ),
        ),
      );
      expect(find.text('x'), findsOneWidget);
    });

    testWidgets('shows empty-state text when history is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HistorySection(history: const []),
        ),
      );
      expect(find.text('No codes yet — generate one.'), findsOneWidget);
    });
  });
}
