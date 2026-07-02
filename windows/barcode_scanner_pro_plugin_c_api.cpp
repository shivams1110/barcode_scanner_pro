#include "include/barcode_scanner_pro/barcode_scanner_pro_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "barcode_scanner_pro_plugin.h"

void BarcodeScannerProPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  barcode_scanner_pro::BarcodeScannerProPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
