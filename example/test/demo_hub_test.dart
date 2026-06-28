import 'package:barcode_scanner_pro_example/demo_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hub lists the generator section tiles', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DemoHubPage(isDark: true, onToggleTheme: () {}),
    ));
    expect(find.text('Generate QR'), findsOneWidget);
    expect(find.text('Generate Barcode'), findsOneWidget);
    expect(find.text('Batch Generation'), findsOneWidget);
    expect(find.text('Validation'), findsOneWidget);
    expect(find.text('Image Decode'), findsOneWidget);
  });
}
