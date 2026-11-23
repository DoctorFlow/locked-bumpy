import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';

class ClosetSheet extends StatefulWidget {
  const ClosetSheet({super.key, required this.state});
  final AppState state;

  static Future<void> open(BuildContext context, AppState state) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 440),
      backgroundColor: AppPalette.of(context).paper,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (_) => ClosetSheet(state: state),
    );
  }

  @override
  State<ClosetSheet> createState() => _ClosetSheetState();
}

class _ClosetSheetState extends State<ClosetSheet> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onChange);
  }

  bool get _available =>
      widget.state.isHalloween &&
      !widget.state.isPaused &&
      !widget.state.isFirstRun;

  void _onChange() {
    if (!_available && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    final state = widget.state;
    final palette = AppPalette.of(context);
    final selected = state.costumeOverride ?? state.todayNeed;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      "Tonight’s wardrobe",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: palette.ink,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close wardrobe',
                  icon: Icon(Icons.close, color: palette.ink),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final need in MaternalNeed.values)
                    SizedBox(
                      width: (constraints.maxWidth - 8) / 2,
                      child: _CostumeCard(
                        need: need,
                        palette: palette,
                        selected: selected == need,
                        onTap: () {
                          state.setCostumeOverride(need);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostumeCard extends StatelessWidget {
  const _CostumeCard({
    required this.need,
    required this.palette,
    required this.selected,
    required this.onTap,
  });
  final MaternalNeed need;
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = need.costume[0] + need.costume.substring(1).toLowerCase();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? palette.accent : Colors.transparent,
        width: 2,
      ),
    );
    return Semantics(
      key: ValueKey('closet-${need.name}'),
      button: true,
      selected: selected,
      label: '$name, ${need.label}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: palette.paperRaised,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              children: [
                Image.asset(need.assetPath(palette), height: 84, width: 84),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.ink,
                  ),
                ),
                Text(
                  need.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.inkSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
