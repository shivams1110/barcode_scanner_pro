import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/code_preview.dart';
import 'widgets/section_scaffold.dart';

const String _kData = 'https://example.com';

/// Fixed color palette for gradient endpoints.
const List<({Color color, String label})> _kColors = [
  (color: Colors.indigo, label: 'indigo'),
  (color: Colors.teal, label: 'teal'),
  (color: Colors.deepOrange, label: 'orange'),
  (color: Colors.purple, label: 'purple'),
  (color: Colors.pink, label: 'pink'),
];

/// Demonstrates QR codes rendered with Flutter gradients (linear / radial /
/// sweep).
///
/// [BarcodeWidget] accepts a standard Flutter [Gradient] and maps it to the
/// generator's internal gradient model, so no manual conversion is required.
class GradientQrSection extends StatefulWidget {
  const GradientQrSection({super.key});

  @override
  State<GradientQrSection> createState() => _GradientQrSectionState();
}

class _GradientQrSectionState extends State<GradientQrSection> {
  /// One of 'linear', 'radial', 'sweep'.
  String _type = 'linear';
  Color _colorA = Colors.indigo;
  Color _colorB = Colors.teal;

  Gradient get _gradient => switch (_type) {
    'radial' => RadialGradient(colors: [_colorA, _colorB]),
    'sweep' => SweepGradient(colors: [_colorA, _colorB]),
    _ => LinearGradient(colors: [_colorA, _colorB]),
  };

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'Gradient QR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(context, 'Gradient type'),
          Wrap(
            spacing: 6,
            children: ['linear', 'radial', 'sweep']
                .map(
                  (t) => ChoiceChip(
                    label: Text(t),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          _label(context, 'Start color'),
          _ColorChips(
            selected: _colorA,
            onSelected: (c) => setState(() => _colorA = c),
          ),
          const SizedBox(height: 8),
          _label(context, 'End color'),
          _ColorChips(
            selected: _colorB,
            onSelected: (c) => setState(() => _colorB = c),
          ),
          const SizedBox(height: 4),
          Text(
            'BarcodeWidget accepts a Flutter Gradient and maps it to the '
            "generator's internal gradient model automatically.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          CodePreview(
            child: BarcodeWidget(
              data: _kData,
              format: BarcodeFormat.qr,
              gradient: _gradient,
              errorCorrectionLevel: ErrorCorrection.high,
              width: 240,
              height: 240,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

class _ColorChips extends StatelessWidget {
  const _ColorChips({required this.selected, required this.onSelected});

  final Color selected;
  final void Function(Color) onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    children: _kColors
        .map(
          (entry) => ChoiceChip(
            label: Text(entry.label),
            selected: selected == entry.color,
            selectedColor: entry.color.withAlpha(80),
            avatar: CircleAvatar(backgroundColor: entry.color),
            onSelected: (_) => onSelected(entry.color),
          ),
        )
        .toList(),
  );
}
