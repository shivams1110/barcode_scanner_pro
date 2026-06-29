import 'package:barcode_scanner_pro/src/platform/channels.dart';
import 'package:barcode_scanner_pro/src/platform/method_channel_barcode_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final channel = MethodChannel(Channels.global);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('decodeImage sends method + args and maps the result list', () async {
    late MethodCall captured;
    messenger.setMockMethodCallHandler(channel, (call) async {
      captured = call;
      return <Object?>[
        {'value': 'HELLO', 'format': 1, 'cornerPoints': <Object?>[]},
      ];
    });

    final platform = MethodChannelBarcodeScanner();
    final out = await platform.decodeImage(Uint8List.fromList([9, 9]), 0);

    expect(captured.method, 'decodeImage');
    final args = captured.arguments as Map;
    expect(args['formats'], 0);
    expect((args['bytes'] as Uint8List).length, 2);
    expect(out, hasLength(1));
    expect(out.first['value'], 'HELLO');
  });

  test('null native result becomes an empty list', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    final platform = MethodChannelBarcodeScanner();
    expect(await platform.decodeImage(Uint8List.fromList([1]), 0), isEmpty);
  });

  test('PlatformException propagates (not swallowed by _guard)', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'DECODING_ERROR'),
    );
    final platform = MethodChannelBarcodeScanner();
    expect(
      () => platform.decodeImage(Uint8List.fromList([1]), 0),
      throwsA(isA<PlatformException>()),
    );
  });
}
