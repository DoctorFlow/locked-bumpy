import 'package:flutter/material.dart';
import '../../domain/models/skin_tone.dart';

class SkinTonePicker extends StatelessWidget {
  const SkinTonePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.foreground,
  });
  final SkinTone selected;
  final ValueChanged<SkinTone> onSelected;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Bumpy’s skin tone',
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final tone in SkinTone.values)
              ChoiceChip(
                avatar: CircleAvatar(
                  backgroundColor: Color(0xff000000 | tone.rgb),
                ),
                label: Text(tone.label),
                selected: selected == tone,
                onSelected: (_) => onSelected(tone),
              ),
          ],
        ),
      ],
    );
  }
}
