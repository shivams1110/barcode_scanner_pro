// Integration test for the example app. Runs on a real device/emulator:
//
//   flutter test integration_test/app_test.dart
//
// It verifies the app boots and reaches either the live scanner (permission
// granted) or the permission prompt, without crashing the native pipeline.
import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:barcode_scanner_pro_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows scanner or permission UI',
      (tester) async {
    await tester.pumpWidget(const BarcodeScannerDemoApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final hasScanner = find.byType(BarcodeScannerView).evaluate().isNotEmpty;
    final hasPermissionPrompt =
        find.text('Camera permission is required to scan.').evaluate().isNotEmpty;

    expect(hasScanner || hasPermissionPrompt, isTrue);
  });
}
