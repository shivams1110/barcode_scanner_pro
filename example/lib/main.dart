import 'package:flutter/material.dart';

import 'demo_hub_page.dart';

void main() => runApp(const BarcodeScannerDemoApp());

/// Root of the example app. Owns the theme-mode toggle (light/dark) used to
/// demonstrate overlay theming.
class BarcodeScannerDemoApp extends StatefulWidget {
  const BarcodeScannerDemoApp({super.key});

  @override
  State<BarcodeScannerDemoApp> createState() => _BarcodeScannerDemoAppState();
}

class _BarcodeScannerDemoAppState extends State<BarcodeScannerDemoApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() => setState(() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'barcode_scanner_pro demo',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF34C759),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF34C759),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: DemoHubPage(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
