import 'package:flutter/material.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';
import '../screens/settings_screen.dart';

/// Week navigation and the nursery controls stay within reach on each tab.
///
/// Left: the week, as a paper tag. Right: the lamp (switch look), Settings
/// and Pause. Every control is a 48 px target.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, required this.state});

  final AppState state;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final currentWeek = state.currentWeek;
    final week = currentWeek == null ? '—' : 'Week $currentWeek';
    final otherLook = state.isHalloween ? 'Everyday' : 'Halloween';
    final available = MediaQuery.sizeOf(context).width;
    final type = MediaQuery.textScalerOf(context).scale(14);
    final showLampLabel = available >= 350 && type <= 18;
    final weekTag = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.paperRaised,
        borderRadius: AppRadii.tag,
        border: Border.all(color: palette.edge),
        boxShadow: paperShadows(palette, raised: true),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.m,
          vertical: 7,
        ),
        child: Text(
          week,
          style: AppText.label.copyWith(
            color: palette.ink,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
    // The paper lamp keeps its own colours in both looks.
    final lamp = Image.asset(
      'assets/images/nursery-lamp.png',
      width: showLampLabel ? 24 : 36,
      height: showLampLabel ? 24 : 36,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) =>
          Icon(Icons.lightbulb_outline, color: palette.moon),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, 4, 4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: state.currentTab == 1
                ? weekTag
                : Tooltip(
                    message: 'Read this week’s card',
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        foregroundColor: palette.moonlight,
                      ),
                      onPressed: () => state.setTab(1),
                      child: weekTag,
                    ),
                  ),
          ),
          Row(
            children: [
              Tooltip(
                message: 'Switch to $otherLook',
                excludeFromSemantics: true,
                child: TextButton(
                  onPressed: state.toggleMode,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: palette.moonlight,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    // An icon button with a caption, not a link: no underline.
                    textStyle: AppText.label,
                  ),
                  child: Semantics(
                    // Starts with the visible words, so "tap Switch look"
                    // works in Voice Control (WCAG 2.5.3).
                    label: 'Switch look to $otherLook',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        lamp,
                        if (showLampLabel) ...[
                          const SizedBox(width: AppSpace.xs),
                          const Text('Switch look'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: Icon(Icons.settings_outlined, color: palette.moonlight),
                onPressed: () => SettingsScreen.open(context, state),
              ),
              Tooltip(
                message: 'Pause',
                excludeFromSemantics: true,
                child: IconButton(
                  icon: Icon(
                    Icons.pause_circle_outline,
                    semanticLabel: 'Pause app',
                    color: palette.moonlight,
                  ),
                  onPressed: state.pause,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
