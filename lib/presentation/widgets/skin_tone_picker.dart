import 'package:flutter/material.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/skin_tone.dart';
import 'paper_portrait.dart';

class SkinTonePicker extends StatelessWidget {
  const SkinTonePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.foreground,
    this.showPreview = false,
  });
  final SkinTone selected;
  final ValueChanged<SkinTone> onSelected;
  final Color foreground;
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final heading = Semantics(
      header: true,
      child: Text(
        'Bumpy’s skin tone',
        style: AppText.heading.copyWith(color: foreground),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview)
          Row(
            children: [
              // The whole Bumpy on a raised paper tile, like the need
              // portraits on Guides: no cropped head, no cut shirt.
              Container(
                key: const ValueKey('skin-tone-preview-tile'),
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(AppSpace.xs),
                decoration: BoxDecoration(
                  color: palette.paperRaised,
                  borderRadius: AppRadii.control,
                  border: Border.all(color: palette.edge),
                  boxShadow: paperShadows(palette, raised: true),
                ),
                child: Image(
                  key: const ValueKey('skin-tone-preview'),
                  image: paperPortrait('assets/images/everyday.png', selected),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: heading),
            ],
          )
        else
          heading,
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
