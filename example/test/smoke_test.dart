import 'package:barcode_scanner_pro_example/demo_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Consolidated smoke test: pumps DemoHubPage, navigates each headlessly-safe
/// section, and asserts no exception is thrown. IO/native sections (Save /
/// Print Preview / Image Decode / Scanner) are only asserted to exist in the
/// hub tile list — not navigated into.
void main() {
  Widget buildHub() => MaterialApp(
        home: DemoHubPage(isDark: true, onToggleTheme: () {}),
      );

  // ---------------------------------------------------------------------------
  // IO / native tiles: assert they exist (include off-screen items).
  // ---------------------------------------------------------------------------

  testWidgets('hub shows IO/native tiles without navigating them',
      (tester) async {
    await tester.pumpWidget(buildHub());
    // Use skipOffstage: false so tiles scrolled off the initial viewport count.
    expect(find.text('Save (PNG / SVG / PDF)', skipOffstage: false),
        findsOneWidget);
    expect(find.text('Print Preview', skipOffstage: false), findsOneWidget);
    expect(find.text('Image Decode', skipOffstage: false), findsOneWidget);
    expect(find.text('Scanner', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------------
  // Headlessly-safe sections: navigate in, assert, navigate back.
  // ---------------------------------------------------------------------------

  testWidgets('smoke: Generate QR section renders without exception',
      (tester) async {
    await tester.pumpWidget(buildHub());

    await tester.tap(find.text('Generate QR'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Generate QR'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('smoke: Styled QR section renders without exception',
      (tester) async {
    await tester.pumpWidget(buildHub());

    await tester.tap(find.text('Styled QR'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Styled QR'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('smoke: Gradient QR section renders without exception',
      (tester) async {
    await tester.pumpWidget(buildHub());

    await tester.tap(find.text('Gradient QR'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Gradient QR'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('smoke: Validation section renders without exception',
      (tester) async {
    await tester.pumpWidget(buildHub());

    // Scroll the hub list until Validation is on-stage, then tap it.
    final validationFinder = find.text('Validation', skipOffstage: false);
    await tester.scrollUntilVisible(validationFinder, 80);
    await tester.pump();

    await tester.tap(find.text('Validation'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Validation'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('smoke: History section renders without exception',
      (tester) async {
    await tester.pumpWidget(buildHub());

    // History is near the bottom of the hub list; scroll to bring it on-stage.
    final historyFinder = find.text('History', skipOffstage: false);
    await tester.scrollUntilVisible(historyFinder, 80);
    await tester.pump();

    // ensureVisible to guarantee it's in the viewport before tap.
    await tester.ensureVisible(find.text('History'));
    await tester.pump();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('History'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  // Batch: assert tile exists. Navigation is skipped in the smoke test because
  // generateBatch is real async (rasterizes PNGs) — the per-section test in
  // batch_section_test.dart covers that path with runAsync.
  testWidgets('smoke: Batch Generation tile exists on hub', (tester) async {
    await tester.pumpWidget(buildHub());
    expect(find.text('Batch Generation', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
