#include "texture_bridge.h"

#include <condition_variable>
#include <cstring>
#include <utility>

namespace barcode_scanner_pro {

TextureBridge::TextureBridge(flutter::TextureRegistrar* registrar)
    : registrar_(registrar) {
  texture_ = std::make_unique<flutter::TextureVariant>(
      flutter::PixelBufferTexture(
          [this](size_t width,
                 size_t height) -> const FlutterDesktopPixelBuffer* {
            return CopyPixelBuffer(width, height);
          }));
  texture_id_ = registrar_->RegisterTexture(texture_.get());
}

TextureBridge::~TextureBridge() {
  if (registrar_ == nullptr || texture_id_ == -1) {
    return;
  }

  // UnregisterTexture is asynchronous: the engine posts removal of this
  // texture to the raster thread and only invokes the completion callback
  // once that removal has happened, which guarantees no further calls to
  // CopyPixelBuffer() (and therefore no more use of `this` via the lambda
  // captured in `texture_`) will occur afterwards. Block here until that
  // happens before `texture_` (and `this`) are torn down, to avoid a
  // use-after-free of the copy-buffer callback on the raster thread.
  std::mutex unregister_mutex;
  std::condition_variable unregister_cv;
  bool unregistered = false;

  registrar_->UnregisterTexture(texture_id_, [&]() {
    std::lock_guard<std::mutex> lock(unregister_mutex);
    unregistered = true;
    unregister_cv.notify_one();
  });

  std::unique_lock<std::mutex> lock(unregister_mutex);
  unregister_cv.wait(lock, [&unregistered] { return unregistered; });
}

void TextureBridge::push_frame(const uint8_t* rgba, int width, int height) {
  if (rgba == nullptr || width <= 0 || height <= 0) {
    return;
  }

  const size_t byte_count =
      static_cast<size_t>(width) * static_cast<size_t>(height) * 4;

  {
    std::lock_guard<std::mutex> lock(buffer_mutex_);
    buffer_.resize(byte_count);
    std::memcpy(buffer_.data(), rgba, byte_count);
    buffer_width_ = width;
    buffer_height_ = height;
  }

  // Thread-safe on Windows: may be called directly from the capture thread.
  registrar_->MarkTextureFrameAvailable(texture_id_);
}

const FlutterDesktopPixelBuffer* TextureBridge::CopyPixelBuffer(
    size_t width, size_t height) {
  buffer_mutex_.lock();

  if (buffer_.empty()) {
    // No frame has been pushed yet; nothing to hand to the engine. Unlock
    // immediately since the engine will not see a buffer to release.
    buffer_mutex_.unlock();
    return nullptr;
  }

  pixel_buffer_.buffer = buffer_.data();
  pixel_buffer_.width = static_cast<size_t>(buffer_width_);
  pixel_buffer_.height = static_cast<size_t>(buffer_height_);
  pixel_buffer_.release_callback = &TextureBridge::ReleaseCopyBuffer;
  pixel_buffer_.release_context = this;

  // Intentionally left locked: released in ReleaseCopyBuffer() once the
  // engine has finished reading pixel_buffer_.buffer.
  return &pixel_buffer_;
}

// static
void TextureBridge::ReleaseCopyBuffer(void* release_context) {
  auto* self = static_cast<TextureBridge*>(release_context);
  self->buffer_mutex_.unlock();
}

}  // namespace barcode_scanner_pro
