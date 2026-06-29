import 'package:barcode_scanner_pro_example/generator/validation_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidationSection', () {
    testWidgets('shows valid indicator for default EAN-13 4006381333931',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ValidationSection()));
      await tester.pump();

      // Default '4006381333931' is a valid EAN-13 — expect exact "valid" label.
      expect(find.text('valid'), findsOneWidget);
      expect(find.text('invalid'), findsNothing);
    });

    testWidgets('shows invalid indicator when check digit is wrong',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ValidationSection()));
      await tester.pump();

      // Replace with a bad check digit (last digit 0 instead of 1).
      await tester.enterText(find.byType(TextField), '4006381333930');
      await tester.pump();

      expect(find.text('invalid'), findsOneWidget);
    });
  });
}
