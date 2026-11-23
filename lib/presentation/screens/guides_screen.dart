import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../core/constants/app_constants.dart';

/// Guides tab — physician guide content.
/// Rung 2: full guide content will be added.
class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48, color: palette.moon),
            const SizedBox(height: 16),
            Text(
              'Physician Guides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: palette.moonlight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nutritional and care guides coming in Rung 2.',
              style: TextStyle(fontSize: 14, color: palette.moonlightSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              AppConstants.disclaimer,
              style: TextStyle(
                fontSize: 11,
                color: palette.moonlightSoft.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
