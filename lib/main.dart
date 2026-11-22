import 'package:flutter/material.dart';
import 'core/theme/palette.dart';
import 'domain/models/need.dart';
import 'domain/pregnancy.dart';

void main() {
  runApp(const LittleBumpyApp());
}

class LittleBumpyApp extends StatefulWidget {
  const LittleBumpyApp({super.key});

  @override
  State<LittleBumpyApp> createState() => _LittleBumpyAppState();
}

class _LittleBumpyAppState extends State<LittleBumpyApp> {
  bool _isHalloween = true; // Halloween shown first on first open
  bool _isPaused = false;
  int _currentTab = 0; // 0: Today, 1: This Week, 2: Guides

  // Demo state
  late DateTime _dueDate;
  final Set<String> _completedCheckIns = {};

  @override
  void initState() {
    super.initState();
    // Default demo due date: ~24 weeks from now (June 2027)
    _dueDate = DateTime.now().add(const Duration(days: 112));
  }

  void _toggleMode() {
    setState(() {
      _isHalloween = !_isHalloween;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _toggleCheckIn(String id) {
    setState(() {
      if (_completedCheckIns.contains(id)) {
        _completedCheckIns.remove(id);
      } else {
        _completedCheckIns.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = _isHalloween ? AppPalette.halloween : AppPalette.everyday;

    return MaterialApp(
      title: 'Little Bumpy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isHalloween ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: palette.skyBottom,
        extensions: [palette],
      ),
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.skyTop, palette.skyBottom],
                ),
              ),
              child: SafeArea(
                child: _isPaused
                    ? _buildPausedView(palette)
                    : _buildMainShell(palette),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPausedView(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Still moon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.everyday.moon.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Everything is paused.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: palette.moonlight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Take all the time you need. We are right here whenever you are ready.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: palette.moonlightSoft,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: _togglePause,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.accentText,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Resume',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainShell(AppPalette palette) {
    final currentWeek = PregnancyCalculator.weekFromDueDate(
      dueDate: _dueDate,
      currentDate: DateTime.now(),
    );

    return Column(
      children: [
        _buildTopBar(palette, currentWeek),
        Expanded(
          child: _currentTab == 0
              ? _buildTodayTab(palette, currentWeek)
              : _buildPlaceholderTab(palette),
        ),
        _buildBottomNav(palette),
      ],
    );
  }

  Widget _buildTopBar(AppPalette palette, int currentWeek) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gestational Week Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: palette.paperRaised.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.moonlight.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Week $currentWeek',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: palette.moonlight,
              ),
            ),
          ),

          // Actions: Lamp Switch & Pause
          Row(
            children: [
              // Lamp Toggle
              IconButton(
                icon: Icon(
                  _isHalloween ? Icons.lightbulb_outline : Icons.lightbulb,
                  color: palette.moon,
                ),
                tooltip: _isHalloween
                    ? 'Switch to Everyday'
                    : 'Switch to Halloween',
                onPressed: _toggleMode,
              ),
              // Pause Button
              IconButton(
                icon: Icon(
                  Icons.pause_circle_outline,
                  color: palette.moonlightSoft,
                ),
                tooltip: 'Pause',
                onPressed: _togglePause,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab(AppPalette palette, int currentWeek) {
    const todayNeed = MaternalNeed.iron;
    final isNeedTicked = _completedCheckIns.contains('need_of_the_day');

    final babyLine = isNeedTicked
        ? (_isHalloween ? 'Cape on. Thank you!' : 'Done! Tiny cheer from me.')
        : (_isHalloween
              ? 'I vant... lentils. Or beans.'
              : 'Iron snack? Lentils or beans, your pick.');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Baby Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.paper,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Costume Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: todayNeed.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: todayNeed.color, width: 1.5),
                  ),
                  child: Text(
                    todayNeed.tag(isHalloween: _isHalloween),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: palette.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Baby illustration placeholder / symbol
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: palette.paperRaised,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _isHalloween ? '🧛' : '👶',
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Baby Speech
                Text(
                  babyLine,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: palette.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Check-Ins Section
          Text(
            "Today's 3 Check-Ins",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.moonlightSoft,
            ),
          ),
          const SizedBox(height: 10),

          _buildCheckInTile(
            palette: palette,
            id: 'need_of_the_day',
            title: 'Iron (Need of the Day)',
            subtitle: todayNeed.foodExamples,
            needColor: todayNeed.color,
            isTicked: isNeedTicked,
          ),
          const SizedBox(height: 8),
          _buildCheckInTile(
            palette: palette,
            id: 'water',
            title: 'Water',
            subtitle: 'A refreshing glass of water',
            needColor: AppPalette.needWater,
            isTicked: _completedCheckIns.contains('water'),
          ),
          const SizedBox(height: 8),
          _buildCheckInTile(
            palette: palette,
            id: 'vitamin',
            title: 'Prenatal Vitamin',
            subtitle: 'The vitamin your doctor chose',
            needColor: AppPalette.needVitamin,
            isTicked: _completedCheckIns.contains('vitamin'),
          ),
          const SizedBox(height: 20),

          // Medical Disclaimer
          Text(
            'This app is not medical advice. If you are worried about anything, call your doctor.',
            style: TextStyle(
              fontSize: 11,
              color: palette.moonlightSoft.withValues(alpha: 0.7),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCheckInTile({
    required AppPalette palette,
    required String id,
    required String title,
    required String subtitle,
    required Color needColor,
    required bool isTicked,
  }) {
    return InkWell(
      onTap: () => _toggleCheckIn(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.paperRaised,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: needColor,
                shape: BoxShape.circle,
                border: Border.all(color: palette.ink, width: 1.5),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: palette.inkSoft),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isTicked ? palette.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTicked ? palette.accent : palette.inkSoft,
                  width: 2,
                ),
              ),
              child: isTicked
                  ? Icon(Icons.star, size: 16, color: palette.accentText)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(AppPalette palette) {
    return Center(
      child: Text(
        _currentTab == 1 ? 'This Week (Weeks 4 to 42)' : 'Physician Guides',
        style: TextStyle(fontSize: 16, color: palette.moonlightSoft),
      ),
    );
  }

  Widget _buildBottomNav(AppPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.tabBar,
        border: Border(
          top: BorderSide(color: palette.ink.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        backgroundColor: palette.tabBar,
        selectedItemColor: palette.accent,
        unselectedItemColor: palette.tabBarText.withValues(alpha: 0.6),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week),
            label: 'This Week',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Guides'),
        ],
      ),
    );
  }
}
