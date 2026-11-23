import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../widgets/data_confirmation.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  static Future<void> open(BuildContext context, AppState state) async {
    final nav = Navigator.of(context);
    final route = MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(state: state),
    );
    // Pause and Erase replace every active screen in the same frame.
    void closeIfInactive() {
      if ((state.isPaused || state.isFirstRun) && route.isActive) {
        nav.removeRoute(route);
      }
    }

    state.addListener(closeIfInactive);
    try {
      await nav.push(route);
    } finally {
      state.removeListener(closeIfInactive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final title = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: palette.ink,
      fontWeight: FontWeight.bold,
    );
    return Scaffold(
      backgroundColor: palette.skyBottom,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                Row(
                  children: [
                    BackButton(color: palette.moonlight),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            color: palette.moonlight,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Pause',
                      child: TextButton.icon(
                        onPressed: state.togglePause,
                        style: TextButton.styleFrom(
                          foregroundColor: palette.moonlight,
                        ),
                        icon: const Icon(Icons.pause_circle_outline),
                        label: const Text('Pause app'),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Card(
                        color: palette.paper,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Little Bumpy',
                                style: title?.copyWith(fontSize: 24),
                              ),
                              Text(
                                AppConstants.appVersion,
                                style: TextStyle(color: palette.inkSoft),
                              ),
                              const SizedBox(height: 24),
                              Text('Appearance', style: title),
                              const SizedBox(height: 8),
                              ListenableBuilder(
                                listenable: state,
                                builder: (context, _) => Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final mode in [false, true])
                                      ChoiceChip(
                                        label: Text(
                                          mode ? 'Halloween' : 'Everyday',
                                        ),
                                        selected: mode == state.isHalloween,
                                        onSelected: (_) {
                                          if (mode != state.isHalloween) {
                                            state.toggleMode();
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text('Privacy', style: title),
                              const SizedBox(height: 4),
                              Text(
                                AppConstants.privacyStatement,
                                style: TextStyle(color: palette.inkSoft),
                              ),
                              const SizedBox(height: 20),
                              Text('Medical disclaimer', style: title),
                              const SizedBox(height: 4),
                              Text(
                                AppConstants.disclaimer,
                                style: TextStyle(color: palette.inkSoft),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.moonlight,
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () => confirmErase(context, state),
                          child: const Text('Erase all data'),
                        ),
                      ),
                    ],
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
