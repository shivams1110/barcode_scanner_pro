import 'package:barcode_scanner_pro/src/controller.dart';
import 'package:barcode_scanner_pro/src/scanner_view.dart';
import 'package:barcode_scanner_pro/src/platform/barcode_scanner_platform.dart';
import 'package:barcode_scanner_pro/src/config/scanner_configuration.dart';
import 'package:barcode_scanner_pro/src/platform/scanner_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _DesktopFake extends BarcodeScannerPlatform {
  _DesktopFake() : super();
  @override
  String get viewType => 'fake';
  @override
  Stream<ScannerEvent> events(int viewId) => const Stream.empty();
  @override
  Future<bool> checkPermission() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<int?> initialize(int viewId, ScannerConfiguration config) async => 7;
  @override
  noSuchMethod(Invocation i) => Future<void>.value();
}

void main() {
  testWidgets('renders Texture on Linux', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    BarcodeScannerPlatform.instance = _DesktopFake();
    final controller = BarcodeScannerController(platform: BarcodeScannerPlatform.instance);
    await tester.pumpWidget(MaterialApp(
      home: BarcodeScannerView(controller: controller),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Texture), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
