#ifndef FLUTTER_PLUGIN_BARCODE_SCANNER_PRO_TEXTURE_BRIDGE_H_
#define FLUTTER_PLUGIN_BARCODE_SCANNER_PRO_TEXTURE_BRIDGE_H_

#include <flutter/texture_registrar.h>

#include <cstdint>
#include <memory>
#include <mutex>
#include <vector>

namespace barcode_scanner_pro {

// Bridges RGBA camera frames pushed from a capture thread (see Task 6's
// camera session) to a Flutter `Texture` widget via a
// flutter::PixelBufferTexture.
//
// Threading model:
//  - push_frame() may be called from any thread (e.g. a dedicated Media
//    Foundation capture thread). It copies the caller's tightly-packed
//    RGBA8888 buffer into an internal buffer under buffer_mutex_, then calls
//    TextureRegistrar::MarkTextureFrameAvailable(), which is documented as
//    safe to call from any thread on Windows.
//  - The Flutter engine invokes the CopyBufferCallback (CopyPixelBuffer())
//    on the raster thread whenever it wants to paint the texture. That call
//    LOCKS buffer_mutex_ and returns a pointer to an internal
//    FlutterDesktopPixelBuffer describing the current buffer. The mutex is
//    deliberately NOT unlocked before returning: it is held until the
//    engine invokes the returned buffer's release_callback (once it has
//    finished reading the pixels), which is where the unlock happens. This
//    prevents push_frame() from overwriting the buffer while the engine is
//    still copying out of it.
class TextureBridge {
 public:
  // `registrar` must outlive this object; it is used to register/unregister
  // the texture and to mark new frames available. Not owned.
  explicit TextureBridge(flutter::TextureRegistrar* registrar);

  ~TextureBridge();

  // Disallow copy and assign.
  TextureBridge(const TextureBridge&) = delete;
  TextureBridge& operator=(const TextureBridge&) = delete;

  // The Flutter texture id to hand back to Dart (e.g. for a `Texture`
  // widget). Valid for the lifetime of this object.
  int64_t texture_id() const { return texture_id_; }

  // Copies width * height * 4 bytes of tightly-packed RGBA8888 pixel data
  // from `rgba` into the internal buffer and notifies the engine that a new
  // frame is available. Safe to call from any single capture thread; the
  // caller is responsible for not calling this concurrently with itself.
  void push_frame(const uint8_t* rgba, int width, int height);

 private:
  // Invoked by the Flutter engine on the raster thread to obtain the latest
  // frame. Locks buffer_mutex_ and, if a frame is available, returns a
  // pointer to pixel_buffer_; the lock is released in ReleaseCopyBuffer()
  // once the engine is done reading. If no frame has been pushed yet, the
  // mutex is unlocked immediately and nullptr is returned (no buffer means
  // no release callback will be invoked by the engine).
  const FlutterDesktopPixelBuffer* CopyPixelBuffer(size_t width,
                                                    size_t height);

  // The release_callback registered on pixel_buffer_. `release_context` is
  // set to `this`; unlocks the buffer_mutex_ that was locked in
  // CopyPixelBuffer().
  static void ReleaseCopyBuffer(void* release_context);

  flutter::TextureRegistrar* registrar_;  // Not owned.

  std::unique_ptr<flutter::TextureVariant> texture_;
  int64_t texture_id_ = -1;

  // Guards buffer_, buffer_width_, buffer_height_ and the fields of
  // pixel_buffer_. Locked (and left locked) in CopyPixelBuffer(), unlocked
  // in ReleaseCopyBuffer(). Also locked/unlocked around the copy in
  // push_frame() via a scoped lock_guard.
  std::mutex buffer_mutex_;
  std::vector<uint8_t> buffer_;
  int buffer_width_ = 0;
  int buffer_height_ = 0;

  // Reused across CopyPixelBuffer() calls; its `buffer` pointer is updated
  // to point at buffer_.data() each time it is handed to the engine.
  FlutterDesktopPixelBuffer pixel_buffer_{};
};

}  // namespace barcode_scanner_pro

#endif  // FLUTTER_PLUGIN_BARCODE_SCANNER_PRO_TEXTURE_BRIDGE_H_
