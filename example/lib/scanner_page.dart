import 'dart:async';

import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-featured demo screen: live preview, overlay, camera controls, format
/// switching, and a scan history with copy / open-URL actions.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.isDark, required this.onToggleTheme});

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late BarcodeScannerController _controller;
  StreamSubscription<BarcodeResult>? _resultSub;
  StreamSubscription<ScannerException>? _errorSub;

  final List<BarcodeResult> _history = [];
  bool _permissionGranted = false;
  bool _checking = true;
  bool _qrOnly = false;
  bool _continuous = true;

  // Bumped to force the platform view + controller to be recreated when the
  // configuration changes (formats / scan mode are fixed at initialize time).
  int _sessionKey = 0;

  @override
  void initState() {
    super.initState();
    _initPermissionAndController();
  }

  Future<void> _initPermissionAndController() async {
    final platform = BarcodeScannerPlatform.instance;
    var granted = await platform.checkPermission();
    granted = granted || await platform.requestPermission();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _checking = false;
    });
    if (granted) _buildController();
  }

  void _buildController() {
    _controller = BarcodeScannerController(
      configuration: ScannerConfiguration(
        formats: _qrOnly ? {BarcodeFormat.qr} : BarcodeFormat.all,
        scanMode: _continuous ? ScanMode.continuous : ScanMode.single,
        continuousScanning: _continuous,
        scanArea: ScanArea.centeredSquare(fraction: 0.75),
        enablePinchZoom: true,
        enableTapFocus: true,
      ),
    );
    _resultSub = _controller.barcodes.listen(_onBarcode);
    _errorSub = _controller.errors.listen(_onError);
  }

  void _onBarcode(BarcodeResult result) {
    setState(() {
      // De-dup adjacent identical reads in the visible history.
      if (_history.isEmpty || _history.first.value != result.value) {
        _history.insert(0, result);
      }
    });
  }

  void _onError(ScannerException e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.message)));
  }

  Future<void> _onScannerCreated(BarcodeScannerController controller) async {
    await controller.initialize();
    await controller.start();
  }

  Future<void> _reconfigure() async {
    await _resultSub?.cancel();
    await _errorSub?.cancel();
    await _controller.dispose();
    setState(() => _sessionKey++);
    _buildController();
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _errorSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('barcode_scanner_pro'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_checking) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_permissionGranted) {
      return _PermissionDenied(onRetry: _initPermissionAndController);
    }
    return Column(
      children: [
        Expanded(child: _buildScanner()),
        _buildControls(),
        Expanded(child: _HistoryList(history: _history)),
      ],
    );
  }

  Widget _buildScanner() {
    return BarcodeScannerView(
      key: ValueKey(_sessionKey),
      controller: _controller,
      onScannerCreated: _onScannerCreated,
      overlayBuilder: (context, controller) => ScannerOverlay(
        controller: controller,
        style: ScannerOverlayStyle(
          laserColor: Theme.of(context).colorScheme.primary,
          detectionColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _controller.flashEnabled,
                builder: (_, on, _) => IconButton.filledTonal(
                  icon: Icon(on ? Icons.flash_on : Icons.flash_off),
                  onPressed: _controller.toggleFlash,
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.cameraswitch),
                onPressed: _controller.switchCamera,
              ),
              FilterChip(
                label: const Text('QR only'),
                selected: _qrOnly,
                onSelected: (v) {
                  setState(() => _qrOnly = v);
                  _reconfigure();
                },
              ),
              FilterChip(
                label: const Text('Continuous'),
                selected: _continuous,
                onSelected: (v) {
                  setState(() => _continuous = v);
                  _reconfigure();
                },
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.zoom_out),
              Expanded(
                child: ValueListenableBuilder<double>(
                  valueListenable: _controller.zoom,
                  builder: (_, zoom, _) => Slider(
                    value: zoom,
                    onChanged: _controller.setZoom,
                  ),
                ),
              ),
              const Icon(Icons.zoom_in),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography, size: 48),
          const SizedBox(height: 12),
          const Text('Camera permission is required to scan.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Grant access')),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});
  final List<BarcodeResult> history;

  bool _isUrl(String v) {
    final uri = Uri.tryParse(v);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('Point the camera at a barcode.'));
    }
    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final b = history[i];
        return ListTile(
          dense: true,
          leading: Chip(label: Text(b.format.name)),
          title: Text(b.value, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${b.timestamp.hour}:${b.timestamp.minute.toString().padLeft(2, '0')}'
            ':${b.timestamp.second.toString().padLeft(2, '0')}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: b.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                },
              ),
              if (_isUrl(b.value))
                IconButton(
                  tooltip: 'Open',
                  icon: const Icon(Icons.open_in_new, size: 20),
                  onPressed: () =>
                      launchUrl(Uri.parse(b.value), mode: LaunchMode.externalApplication),
                ),
            ],
          ),
        );
      },
    );
  }
}
