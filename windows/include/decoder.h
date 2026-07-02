// Shared ZXing-C++ decode core.
//
// Header-only so both the Windows and Linux plugins can include it directly.
// Decodes barcodes from a tightly-packed RGBA8888 buffer (rowStride == width*4)
// and returns detections in a plain struct the channel layer maps into the
// cross-platform `BarcodeResult.fromMap` shape. No camera, no I/O — pure decode,
// so it is unit-testable on any host (see test/native).
#pragma once
// ZXing headers are included unprefixed: when ZXing-C++ is consumed via
// CMake FetchContent (add_subdirectory), its BUILD_INTERFACE include dir is
// `core/src`, so headers resolve as <ReadBarcode.h>, not <ZXing/ReadBarcode.h>
// (the ZXing/ prefix only exists for installed headers).
#include <BarcodeFormat.h>
#include <ReadBarcode.h>

#include <algorithm>
#include <cstdint>
#include <string>
#include <vector>

#include "format_map.h"

namespace bsp {

struct Corner {
  int x, y;
};

struct Detection {
  std::string value;   // decoded UTF-8 payload
  int formatBit;       // cross-platform BarcodeFormat bit (see format_map.h)
  int left, top, width, height;  // axis-aligned bounding box, image px
  std::vector<Corner> corners;   // 4 corners: TL, TR, BR, BL
};

// Decode all barcodes in an RGBA8888 buffer. `formatsMask` is the cross-platform
// bitmask (0 => all formats). Returns one Detection per valid result.
inline std::vector<Detection> decode_rgba(const uint8_t* rgba, int width,
                                          int height, int formatsMask) {
  ZXing::ImageView image(rgba, width, height, ZXing::ImageFormat::RGBA);
  auto opts = ZXing::ReaderOptions()
                  .setTryHarder(true)
                  .setTryRotate(true)
                  .setFormats(mask_to_zxing(formatsMask));
  auto results = ZXing::ReadBarcodes(image, opts);

  std::vector<Detection> out;
  out.reserve(results.size());
  for (const auto& b : results) {
    if (!b.isValid()) continue;
    const auto& p = b.position();
    const int xs[] = {p.topLeft().x, p.topRight().x, p.bottomRight().x,
                      p.bottomLeft().x};
    const int ys[] = {p.topLeft().y, p.topRight().y, p.bottomRight().y,
                      p.bottomLeft().y};
    int minx = xs[0], maxx = xs[0], miny = ys[0], maxy = ys[0];
    for (int i = 1; i < 4; ++i) {
      minx = std::min(minx, xs[i]);
      maxx = std::max(maxx, xs[i]);
      miny = std::min(miny, ys[i]);
      maxy = std::max(maxy, ys[i]);
    }
    out.push_back(Detection{
        b.text(),
        zxing_format_to_bit(b.format()),
        minx, miny, maxx - minx, maxy - miny,
        {{p.topLeft().x, p.topLeft().y},
         {p.topRight().x, p.topRight().y},
         {p.bottomRight().x, p.bottomRight().y},
         {p.bottomLeft().x, p.bottomLeft().y}}});
  }
  return out;
}

}  // namespace bsp
