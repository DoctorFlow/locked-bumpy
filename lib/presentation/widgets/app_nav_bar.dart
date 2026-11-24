import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';

/// Bottom navigation: Today, This Week, Guides.
///
/// A paper strip with three equal tabs. The selected tab is marked four ways,
/// so it never depends on colour alone: an accent paper marker behind the
/// icon, a filled icon, a bold label and the accent colour. Labels grow with
/// the system text size up to 1.3x and stay on one line (the stock Material
/// bar pins them at 100%).
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.state});

  final AppState state;

  static const _tabs = [
    (label: 'Today', icon: Icons.today_outlined, selectedIcon: Icons.today),
    (
      label: 'This Week',
      icon: Icons.calendar_view_week_outlined,
      selectedIcon: Icons.calendar_view_week,
    ),
    (
      label: 'Guides',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
  ];

  /// The largest text scale a tab label follows before it shrinks to fit.
  static const maxLabelScale = 1.3;

  /// Label and icon colour of a tab that is not selected, on [AppPalette.tabBar].
  static Color unselectedColor(AppPalette palette) => palette.tabBarText;

  /// Label colour of the selected tab, on [AppPalette.tabBar].
  static Color selectedColor(AppPalette palette) => palette.accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    // A rotated phone has no height to spare: icon beside label, 48 tall.
    final beside = MediaQuery.sizeOf(context).height < 480;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.tabBar,
        border: Border(top: BorderSide(color: palette.edge)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          role: SemanticsRole.tabBar,
          explicitChildNodes: true,
          container: true,
          // One height for all three, so the icons stay in a line and every
          // target is full height.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, tab) in _tabs.indexed)
                  Expanded(
                    child: _Tab(
                      label: tab.label,
                      icon: tab.icon,
                      selectedIcon: tab.selectedIcon,
                      position: MaterialLocalizations.of(
                        context,
                      ).tabLabel(tabIndex: index + 1, tabCount: _tabs.length),
                      selected: state.currentTab == index,
                      beside: beside,
                      palette: palette,
                      onTap: () => state.setTab(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.position,
    required this.selected,
    required this.beside,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String position;
  final bool selected;
  final bool beside;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppNavBar.selectedColor(palette)
        : AppNavBar.unselectedColor(palette);
    final marker = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      width: beside ? 44 : 56,
      height: 30,
      decoration: BoxDecoration(
        color: selected ? palette.accent : palette.accent.withValues(alpha: 0),
        borderRadius: AppRadii.control,
      ),
      child: Icon(
        selected ? selectedIcon : icon,
        size: 24,
        color: selected ? palette.accentText : color,
      ),
    );
    // One line at any text size. The label grows with the system text size
    // up to [AppNavBar.maxLabelScale], then shrinks to fit the tab rather
    // than wrap: the icon and the marker carry the meaning, and the bar
    // stays short enough to leave the page room on a small phone.
    final text = MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppNavBar.maxLabelScale,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );

    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadii.control,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: beside ? AppSpace.target : AppSpace.row,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: beside ? AppSpace.xs : 6,
                  ),
                  child: beside
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            marker,
                            const SizedBox(width: AppSpace.s),
                            Flexible(child: text),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [marker, const SizedBox(height: 2), text],
                        ),
                ),
              ),
              // "Tab 1 of 3", spoken after the name.
              Semantics(label: position),
            ],
          ),
        ),
      ),
    );
  }
}
