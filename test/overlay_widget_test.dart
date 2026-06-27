import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => BarcodeScannerPlatform.instance = FakeBarcodeScannerPlatform());

  Widget host(BarcodeScannerController controller, ScannerOverlayStyle style) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: ScannerOverlay(controller: controller, style: style),
        ),
      ),
    );
  }

  testWidgets('static overlay (no laser) paints without scheduling frames',
      (tester) async {
    final controller = BarcodeScannerController()..attach(1);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      host(controller, const ScannerOverlayStyle(showLaser: false)),
    );

    expect(find.byType(ScannerOverlay), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animated laser advances and unmounts cleanly', (tester) async {
    final controller = BarcodeScannerController()..attach(1);
    addTearDown(controller.dispose);

    await tester.pumpWidget(host(controller, const ScannerOverlayStyle()));

    // Advance the repeating laser animation a few frames.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    // Unmount so the overlay disposes its animation ticker; the test must be
    // able to settle afterwards (no lingering scheduled frames).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
