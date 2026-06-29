import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/widgets/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a CustomPaint inside a RepaintBoundary', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: BarcodeWidget(
            data: 'https://umda.com',
            format: BarcodeFormat.qr,
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
    expect(find.byType(BarcodeWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(RepaintBoundary), findsWidgets);
  });

  testWidgets('renders linear format', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: BarcodeWidget(
            data: '012345678905',
            format: BarcodeFormat.upcA,
            width: 240,
            height: 100,
            showText: true,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
