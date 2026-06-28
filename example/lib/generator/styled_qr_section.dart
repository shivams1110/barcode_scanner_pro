import 'package:barcode_scanner_pro/barcode_scanner_pro.dart';
import 'package:flutter/material.dart';

import 'widgets/code_preview.dart';
import 'widgets/section_scaffold.dart';

const String _kData = 'https://karnival.com';

/// Fixed foreground-color palette for the color picker chips.
const List<({Color color, String label})> _kColors = [
  (color: Colors.black, label: 'black'),
  (color: Colors.indigo, label: 'indigo'),
  (color: Colors.teal, label: 'teal'),
  (color: Colors.deepOrange, label: 'orange'),
  (color: Colors.purple, label: 'purple'),
];

/// Demonstrates live styled QR rendering: module shape, eye shape, foreground
/// color, and border radius are all interactive.
///
/// Covers the "Rounded QR" use-case via [ModuleShape.rounded].
class StyledQrSection extends StatefulWidget {
  const StyledQrSection({super.key});

  @override
  State<StyledQrSection> createState() => _StyledQrSectionState();
}

class _StyledQrSectionState extends State<StyledQrSection> {
  ModuleShape _module = ModuleShape.square;
  EyeShape _eye = EyeShape.square;
  Color _fg = Colors.black;
  double _radius = 0;

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'Styled QR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Label('Module shape'),
          _ChipRow<ModuleShape>(
            values: ModuleShape.values,
            selected: _module,
            label: (v) => v.name,
            onSelected: (v) => setState(() => _module = v),
          ),
          const SizedBox(height: 8),
          _Label('Eye shape'),
          _ChipRow<EyeShape>(
            values: EyeShape.values,
            selected: _eye,
            label: (v) => v.name,
            onSelected: (v) => setState(() => _eye = v),
          ),
          const SizedBox(height: 8),
          _Label('Foreground color'),
          Wrap(
            spacing: 6,
            children: _kColors.map((entry) {
              final selected = _fg == entry.color;
              return ChoiceChip(
                label: Text(entry.label),
                selected: selected,
                selectedColor: entry.color.withAlpha(80),
                avatar: CircleAvatar(backgroundColor: entry.color),
                onSelected: (_) => setState(() => _fg = entry.color),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _Label('Border radius: ${_radius.toStringAsFixed(2)}'),
          Slider(
            min: 0,
            max: 1,
            divisions: 20,
            value: _radius,
            onChanged: (v) => setState(() => _radius = v),
          ),
          CodePreview(
            child: BarcodeWidget(
              data: _kData,
              format: BarcodeFormat.qr,
              moduleShape: _module,
              eyeShape: _eye,
              foregroundColor: _fg,
              borderRadius: _radius,
              errorCorrectionLevel: ErrorCorrection.high,
              width: 240,
              height: 240,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        children: values
            .map(
              (v) => ChoiceChip(
                label: Text(label(v)),
                selected: selected == v,
                onSelected: (_) => onSelected(v),
              ),
            )
            .toList(),
      );
}
