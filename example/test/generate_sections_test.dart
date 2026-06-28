import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:barcode_scanner_pro_example/generator/generate_barcode_section.dart';
import 'package:barcode_scanner_pro_example/generator/generate_qr_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenerateQrSection', () {
    testWidgets('renders a TextField and a CustomPaint for default data',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GenerateQrSection()));
      expect(find.byType(TextField), findsOneWidget);
      // BarcodeWidget wraps CustomPaint; it paints synchronously so at least
      // one CustomPaint must be present for the non-empty default data.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('shows hint text when field is cleared', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GenerateQrSection()));
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Enter text to generate a QR code'), findsOneWidget);
    });
  });

  group('GenerateBarcodeSection', () {
    testWidgets(
        'shows Invalid validity line and Cannot encode for bad EAN-13',
        (tester) async {
      // Start on EAN-13 by tapping the dropdown and selecting it with pump()
      // (not pumpAndSettle — the FutureBuilder keeps microtasks alive).
      await tester.pumpWidget(
        const MaterialApp(home: GenerateBarcodeSection()),
      );

      // Open dropdown.
      await tester.tap(find.byType(DropdownButton<BarcodeFormat>));
      await tester.pump(); // trigger open
      await tester.pump(const Duration(milliseconds: 300)); // settle animation

      // Tap EAN-13 in the dropdown menu.
      final ean13Items = find.text('EAN-13');
      // The last occurrence is the menu item (first is the selected value label
      // in the button which may or may not be visible).
      await tester.tap(ean13Items.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The default EAN-13 value ('4006381333931') is valid.
      // Overwrite with a clearly invalid EAN-13.
      await tester.enterText(find.byType(TextField), '1234567890123');
      await tester.pump();

      // Validity line is synchronous — independent of FutureBuilder.
      expect(find.textContaining('Invalid'), findsOneWidget);
      // The skipRender guard fires, so "Cannot encode" appears in the preview.
      expect(find.textContaining('Cannot encode'), findsOneWidget);
    });

    testWidgets('shows Cannot encode for empty data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GenerateBarcodeSection()),
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.textContaining('Cannot encode'), findsOneWidget);
    });
  });
}
