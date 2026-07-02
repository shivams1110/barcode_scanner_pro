#include "../../windows/include/decoder.h"
#include "fixtures/qr_hello.rgba.h"
#include <cassert>
#include <cstdio>

int main() {
  auto dets = bsp::decode_rgba(QR_HELLO_RGBA, QR_HELLO_W, QR_HELLO_H, 0);
  assert(dets.size() == 1);
  assert(dets[0].value == "HELLO");
  assert(dets[0].corners.size() == 4);
  printf("OK: %s\n", dets[0].value.c_str());
  return 0;
}
