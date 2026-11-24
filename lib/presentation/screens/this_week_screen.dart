import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/week_card.dart';

/// This Week tab — browse gestational weeks 4–42 with approved baby-voice cards.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  List<WeekCard>? _cards;
  static const int _minWeek = AppConstants.minWeek;
  static const int _maxWeek = AppConstants.maxWeek;
  late int _currentWeek;
  late int _selectedWeek;
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.state.currentWeek ?? _minWeek;
    _selectedWeek = _currentWeek;
    _pages = PageController(initialPage: _selectedWeek - _minWeek);
    _loadCards();
  }

  @override
  void didUpdateWidget(ThisWeekScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.state.currentWeek ?? _minWeek;
    if (current == _currentWeek) return;
    final following = _selectedWeek == _currentWeek;
    _currentWeek = current;
    if (following) {
      _selectedWeek = current;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(current - _minWeek);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int week) {
    final index = week - _minWeek;
    if (MediaQuery.disableAnimationsOf(context) ||
        (_selectedWeek - week).abs() > 1) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadCards() async {
    final cards = await ContentLoader.loadWeekCards();
    if (mounted) setState(() => _cards = cards);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final cards = _cards;

    if (cards == null) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }

    final mode = palette.isHalloween ? 'halloween' : 'everyday';
    return Column(
      children: [
        const SizedBox(height: 12),
        ExcludeSemantics(
          child: _WeekDots(
            selected: _selectedWeek,
            min: _minWeek,
            max: _maxWeek,
            current: _currentWeek,
            palette: palette,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _maxWeek - _minWeek + 1,
            onPageChanged: (page) =>
                setState(() => _selectedWeek = page + _minWeek),
            itemBuilder: (context, index) {
              final week = _minWeek + index;
              final card = WeekCard.findFor(
                cards: cards,
                week: week,
                mode: mode,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomScrollView(
                  key: PageStorageKey('week-$week'),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _WeekCardView(
                        week: week,
                        card: card,
                        palette: palette,
                        isCurrentWeek: week == _currentWeek,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.arrow_back_ios_new,
                label: 'Previous week',
                enabled: _selectedWeek > _minWeek,
                palette: palette,
                onTap: () => _goTo(_selectedWeek - 1),
              ),
              Flexible(
                child: _selectedWeek == _currentWeek
                    ? Text(
                        'Week $_selectedWeek',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: palette.moonlight,
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: palette.moonlight,
                        ),
                        onPressed: () => _goTo(_currentWeek),
                        child: const Text(
                          'Back to this week',
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
              _NavButton(
                icon: Icons.arrow_forward_ios,
                label: 'Next week',
                enabled: _selectedWeek < _maxWeek,
                palette: palette,
                onTap: () => _goTo(_selectedWeek + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WeekDots extends StatelessWidget {
  const _WeekDots({
    required this.selected,
    required this.min,
    required this.max,
    required this.current,
    required this.palette,
  });

  final int selected;
  final int min;
  final int max;
  final int current;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(max - min + 1, (i) {
          final week = min + i;
          final isSelected = week == selected;
          final isCurrent = week == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: isSelected ? 10 : 5,
            height: isSelected ? 10 : 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? palette.accent
                  : isCurrent
                  ? palette.moon.withValues(alpha: 0.6)
                  : palette.moonlightSoft.withValues(alpha: 0.25),
            ),
          );
        }),
      ),
    );
  }
}

class _WeekCardView extends StatelessWidget {
  const _WeekCardView({
    required this.week,
    required this.card,
    required this.palette,
    required this.isCurrentWeek,
  });

  final int week;
  final WeekCard? card;
  final AppPalette palette;
  final bool isCurrentWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(24),
        border: isCurrentWeek
            ? Border.all(color: palette.accent, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.moon.withValues(alpha: 0.3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Image.asset(
                'assets/images/need-rest.png',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isCurrentWeek) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'You are here',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: palette.accent,
                ),
              ),
            ),
          ],
          Text(
            'Week $week',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: palette.accent,
            ),
          ),
          if (card != null) ...[
            const SizedBox(height: 16),
            Text(
              card!.babyLine,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: palette.ink,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (card?.sizeObject != null) ...[
            const SizedBox(height: 12),
            Text(
              'About the size of a ${card!.sizeObject}',
              style: TextStyle(
                fontSize: 13,
                color: palette.inkSoft,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: palette.moonlight,
          disabledForegroundColor: palette.moonlightSoft.withValues(
            alpha: 0.45,
          ),
          // Both looks use a dark sky outside the paper card.
          backgroundColor: palette.moonlight.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, semanticLabel: label, size: 20),
      ),
    );
  }
}
