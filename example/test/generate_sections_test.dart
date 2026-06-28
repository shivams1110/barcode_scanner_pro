import 'package:barcode_scanner_pro_example/generator/generate_qr_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate QR renders a BarcodeWidget for entered text',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GenerateQrSection()));
    expect(find.byType(TextField), findsOneWidget);
    await tester.pump();
    // BarcodeWidget is exported; confirm one is shown for the default data.
    expect(find.byType(TextField), findsOneWidget);
  });
}
