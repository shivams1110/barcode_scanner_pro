import 'dart:io';

import 'package:barcode_scanner_pro/src/domain/barcode_format.dart';
import 'package:barcode_scanner_pro/src/generator/generator_service.dart';
import 'package:barcode_scanner_pro/src/generator/models/barcode_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = BarcodeGenerator();
  const req = BarcodeRequest(data: '012345678905', format: BarcodeFormat.upcA);

  testWidgets('generateSvg returns svg string', (tester) async {
    String? svg;
    await tester.runAsync(() async => svg = await gen.generateSvg(req));
    expect(svg, contains('<svg'));
  });

  testWidgets('saveAsSVG writes a file (creating parent dirs)', (tester) async {
    final dir = Directory.systemTemp.createTempSync('bsp_svg');
    final path = '${dir.path}/nested/out.svg';
    File? file;
    await tester.runAsync(() async => file = await gen.saveAsSVG(req, path));
    expect(file!.existsSync(), isTrue);
    expect(file!.readAsStringSync(), contains('<svg'));
    dir.deleteSync(recursive: true);
  });
}
