import 'package:barcode_scanner_pro_example/generator/styled_qr_section.dart';
import 'package:barcode_scanner_pro_example/generator/gradient_qr_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StyledQrSection', () {
    testWidgets('renders ModuleShape chips and BarcodeWidget without exception',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StyledQrSection()),
      );

      // All ModuleShape labels should be present as chips.
      expect(find.text('square'), findsWidgets);
      expect(find.text('rounded'), findsWidgets);
      expect(find.text('circular'), findsWidgets);
      expect(find.text('diamond'), findsOneWidget);
      expect(find.text('classy'), findsOneWidget);

      // BarcodeWidget renders synchronously via CustomPaint — no exception.
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a ModuleShape chip updates state without exception',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StyledQrSection()),
      );

      // Tap the "rounded" ModuleShape chip (first occurrence in module row).
      final roundedChips = find.text('rounded');
      await tester.tap(roundedChips.first);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('tapping an EyeShape chip updates state without exception',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StyledQrSection()),
      );

      // Tap the "leaf" EyeShape chip.
      await tester.tap(find.text('leaf'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('GradientQrSection', () {
    testWidgets('renders gradient type chips and BarcodeWidget without exception',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GradientQrSection()),
      );

      expect(find.text('linear'), findsOneWidget);
      expect(find.text('radial'), findsOneWidget);
      expect(find.text('sweep'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping radial chip updates state without exception',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GradientQrSection()),
      );

      await tester.tap(find.text('radial'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
