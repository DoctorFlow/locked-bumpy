import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/pregnancy.dart';
import '../sheets/closet_sheet.dart';

/// App top bar: week chip, lamp toggle, pause button.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, required this.state});

  final AppState state;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final week = state.dueDate == null
        ? '—'
        : 'Week ${PregnancyCalculator.weekFromDueDate(dueDate: state.dueDate!, currentDate: DateTime.now())}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gestational week chip
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: palette.paperRaised.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: palette.moonlight.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                week,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: palette.moonlight,
                ),
              ),
            ),
          ),

          Row(
            children: [
              // Lamp toggle — switches Everyday ↔ Halloween
              Semantics(
                label: state.isHalloween
                    ? 'Switch to Everyday mode'
                    : 'Switch to Halloween mode',
                button: true,
                child: IconButton(
                  iconSize: 36,
                  icon: Image.asset(
                    'assets/images/nursery-lamp.png',
                    width: 36,
                    height: 36,
                    excludeFromSemantics: true,
                    color: palette.isHalloween ? palette.moonlightSoft : null,
                    colorBlendMode: BlendMode.srcIn,
                    errorBuilder: (_, _, _) => Icon(
                      state.isHalloween
                          ? Icons.lightbulb_outline
                          : Icons.lightbulb,
                      color: palette.moon,
                    ),
                  ),
                  onPressed: state.toggleMode,
                  tooltip: state.isHalloween
                      ? 'Switch to Everyday'
                      : 'Switch to Halloween',
                ),
              ),
              if (state.isHalloween)
                IconButton(
                  tooltip: 'Costume closet',
                  icon: Icon(Icons.checkroom, color: palette.moonlight),
                  onPressed: () => ClosetSheet.open(context, state),
                ),
              // Pause
              Semantics(
                label: 'Pause app',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.pause_circle_outline,
                    color: palette.moonlightSoft,
                  ),
                  onPressed: state.togglePause,
                  tooltip: 'Pause',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
