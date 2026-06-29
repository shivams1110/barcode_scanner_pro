import 'package:barcode_scanner_pro_example/generator/logo_qr_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogoQrSection', () {
    testWidgets('renders without exception once the ui.Image resolves',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: LogoQrSection()),
        );

        // Allow the ui.Image future (PictureRecorder -> toImage) to complete.
        await tester.pumpAndSettle();
      });

      // After runAsync the widget tree has been built; pump once more to
      // flush any pending frames from setState after image resolves.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Logo QR'), findsOneWidget);
    });

    testWidgets('shows the ECC note and the medium-ECC demo button',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: LogoQrSection()),
        );
        await tester.pumpAndSettle();
      });

      await tester.pump();

      expect(
        find.textContaining('error correction'),
        findsAtLeast(1),
      );
      expect(find.text('Try with medium ECC'), findsOneWidget);
    });
  });
}
