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

          // Resume
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.togglePause,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.accentText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Resume',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Start Fresh
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmStartFresh(context, palette),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.moonlightSoft,
                side: BorderSide(
                  color: palette.moonlightSoft.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Start Fresh',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Erase all data
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _confirmErase(context, palette),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Erase all data',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmStartFresh(
    BuildContext context,
    AppPalette palette,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        palette: palette,
        title: 'Start a fresh day?',
        body: "Today's check-ins will reset. Your date and nickname stay.",
        confirmLabel: 'Yes, start fresh',
        confirmDestructive: false,
      ),
    );
    if (confirmed == true && context.mounted) {
      await state.clearTodayCheckIns();
    }
  }

  Future<void> _confirmErase(BuildContext context, AppPalette palette) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        palette: palette,
        title: 'Erase everything?',
        body:
            'This removes your date, nickname, and check-ins. '
            'It cannot be undone.',
        confirmLabel: 'Yes, erase',
        confirmDestructive: true,
      ),
    );
    if (confirmed == true && context.mounted) {
      await state.eraseAll();
    }
  }
}

// ── Shared confirm dialog ─────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.palette,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmDestructive,
  });

  final AppPalette palette;
  final String title;
  final String body;
  final String confirmLabel;
  final bool confirmDestructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: palette.paper,
      title: Text(
        title,
        style: TextStyle(
          color: palette.ink,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      content: Text(
        body,
        style: TextStyle(color: palette.inkSoft, fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Never mind',
            style: TextStyle(color: palette.moonlightSoft),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmDestructive
                ? Colors.redAccent
                : palette.accent,
            foregroundColor: confirmDestructive
                ? Colors.white
                : palette.accentText,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
