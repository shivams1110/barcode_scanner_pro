// Shared ZXing BarcodeFormat <-> cross-platform bit mapping.
//
// The bit values MUST match lib/src/domain/barcode_format.dart — that Dart enum
// is the single source of truth for the cross-platform format bitmask. This
// header is included by both the Windows and Linux plugins.
#pragma once
// Unprefixed: ZXing consumed via FetchContent exposes core/src on the include
// path, so <BarcodeFormat.h> resolves (not <ZXing/BarcodeFormat.h>).
#include <BarcodeFormat.h>

#include <utility>
#include <vector>

namespace bsp {

// ZXing readable format -> the `.bit` value from lib/src/domain/barcode_format.dart.
// Formats the Dart enum does not carry (or that ZXing cannot read) map to 0.
inline int zxing_format_to_bit(ZXing::BarcodeFormat f) {
  using BF = ZXing::BarcodeFormat;
  switch (f) {
    case BF::QRCode:     return 1 << 0;   // qr
    case BF::Code128:    return 1 << 1;   // code128
    case BF::Code39:     return 1 << 2;   // code39
    case BF::Code93:     return 1 << 3;   // code93
    case BF::EAN8:       return 1 << 4;   // ean8
    case BF::EAN13:      return 1 << 5;   // ean13
    case BF::UPCA:       return 1 << 6;   // upcA
    case BF::UPCE:       return 1 << 7;   // upcE
    case BF::PDF417:     return 1 << 8;   // pdf417
    case BF::Aztec:      return 1 << 9;   // aztec
    case BF::DataMatrix: return 1 << 10;  // dataMatrix
    case BF::ITF:        return 1 << 11;  // itf
    case BF::Codabar:    return 1 << 12;  // codabar
    default:             return 0;
  }
}

// Cross-platform bitmask -> ZXing format set. 0 means "all formats".
// BarcodeFormats has no `|=`; it is built from a vector<BarcodeFormat>.
inline ZXing::BarcodeFormats mask_to_zxing(int mask) {
  using BF = ZXing::BarcodeFormat;
  if (mask == 0) return BF::Any;
  std::vector<BF> fmts;
  if (mask & (1 << 0))  fmts.push_back(BF::QRCode);
  if (mask & (1 << 1))  fmts.push_back(BF::Code128);
  if (mask & (1 << 2))  fmts.push_back(BF::Code39);
  if (mask & (1 << 3))  fmts.push_back(BF::Code93);
  if (mask & (1 << 4))  fmts.push_back(BF::EAN8);
  if (mask & (1 << 5))  fmts.push_back(BF::EAN13);
  if (mask & (1 << 6))  fmts.push_back(BF::UPCA);
  if (mask & (1 << 7))  fmts.push_back(BF::UPCE);
  if (mask & (1 << 8))  fmts.push_back(BF::PDF417);
  if (mask & (1 << 9))  fmts.push_back(BF::Aztec);
  if (mask & (1 << 10)) fmts.push_back(BF::DataMatrix);
  if (mask & (1 << 11)) fmts.push_back(BF::ITF);
  if (mask & (1 << 12)) fmts.push_back(BF::Codabar);
  return ZXing::BarcodeFormats(std::move(fmts));
}

}  // namespace bsp
