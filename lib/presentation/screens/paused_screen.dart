import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';

/// Quiet, neutral Paused screen.
/// App voice only — no baby, no costume, no animations.
class PausedScreen extends StatelessWidget {
  const PausedScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Still moon mark — no animation while paused.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.moon.withValues(alpha: 0.8),
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
            'Take all the time you need. '
            'We are right here whenever you are ready.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: palette.moonlightSoft,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: state.togglePause,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.accentText,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              minimumSize: const Size(180, 48),
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
}
