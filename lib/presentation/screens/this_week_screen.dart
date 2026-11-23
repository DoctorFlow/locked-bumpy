import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/pregnancy.dart';

/// This Week tab — shows gestational week (4–42).
/// Rung 2: week card dataset and horizontal pager will be added.
class ThisWeekScreen extends StatelessWidget {
  const ThisWeekScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final week = state.dueDate == null
        ? 0
        : PregnancyCalculator.weekFromDueDate(
            dueDate: state.dueDate!,
            currentDate: DateTime.now(),
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Week $week',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: palette.moon,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Week cards for weeks 4 to 42 coming in Rung 2.',
              style: TextStyle(fontSize: 14, color: palette.moonlightSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
