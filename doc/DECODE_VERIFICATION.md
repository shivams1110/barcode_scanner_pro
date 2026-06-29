# decodeImage — Manual Device Verification

`decodeImage`'s native ML Kit/Vision handlers cannot be unit-tested in CI; verify
them manually on a real Android device and an iOS simulator/device.

## Setup
Run the example app (`cd example && flutter run`).

## Round-trip checks (do each on Android AND iOS)
1. **QR round-trip** — generate a QR for `https://umda.com`:
   `final png = await const BarcodeGenerator().generateBytes(BarcodeGenerator.url('https://umda.com'));`
   then `final codes = await const BarcodeGenerator().decodeImage(png);`
   - Expect: `codes.length == 1`, `codes.first.value == 'https://umda.com'`,
     `codes.first.format == BarcodeFormat.qr`.
2. **EAN-13 round-trip** — generate `BarcodeRequest(data: '4006381333931', format: BarcodeFormat.ean13)`,
   export PNG, decode.
   - Expect: one result, `value == '4006381333931'`, `format == BarcodeFormat.ean13`.
3. **Format filter** — decode the QR PNG with `formats: {BarcodeFormat.ean13}`.
   - Expect: empty list (QR excluded).
4. **No-codes image** — decode a plain-colour PNG.
   - Expect: empty list, no exception.
5. **Invalid bytes** — `decodeImage(Uint8List.fromList([1,2,3]))`.
   - Expect: `BarcodeGenException` thrown.

## Record
| Check | Android (device, OS) | iOS (device/sim, OS) |
|-------|----------------------|----------------------|
| 1 QR round-trip |  |  |
| 2 EAN-13 |  |  |
| 3 Filter |  |  |
| 4 No-codes |  |  |
| 5 Invalid bytes |  |  |

## Known limitations

- **UPC-A**: iOS Vision has no dedicated UPC-A symbology — UPC-A codes decode with `format == BarcodeFormat.ean13` on iOS (Android ML Kit reports upcA correctly).
- **Codabar on iOS**: requires iOS 15+.
- **EXIF orientation (Android)**: image bytes are decoded at orientation 0; a photo with EXIF rotation may decode at the wrong orientation (generated barcode PNGs are unaffected).
- **Large images**: bitmap decode runs on the platform thread; very large images may briefly block. Generated barcodes are small — not a concern for the round-trip checks.
