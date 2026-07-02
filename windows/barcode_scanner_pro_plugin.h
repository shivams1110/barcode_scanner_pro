#ifndef FLUTTER_PLUGIN_BARCODE_SCANNER_PRO_PLUGIN_H_
#define FLUTTER_PLUGIN_BARCODE_SCANNER_PRO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace barcode_scanner_pro {

class BarcodeScannerProPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  BarcodeScannerProPlugin();

  virtual ~BarcodeScannerProPlugin();

  // Disallow copy and assign.
  BarcodeScannerProPlugin(const BarcodeScannerProPlugin&) = delete;
  BarcodeScannerProPlugin& operator=(const BarcodeScannerProPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace barcode_scanner_pro

#endif  // FLUTTER_PLUGIN_BARCODE_SCANNER_PRO_PLUGIN_H_
