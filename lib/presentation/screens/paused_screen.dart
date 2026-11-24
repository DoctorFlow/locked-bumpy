import 'package:flutter/material.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';

import '../widgets/data_confirmation.dart';
import '../widgets/whole_word_text.dart';

/// Quiet, neutral Paused screen.
/// App voice only — no baby, no costume, no animations.
///
/// Everything sits on one paper card, so the erase colours are the palette's
/// `danger` / `onDanger` on paper in both looks (DESIGN.md section 8, item 5),
/// and they stay right when the Everyday page turns light. "Resume" is the
/// one main button; the other two actions sit 32 below it.
class PausedScreen extends StatelessWidget {
  const PausedScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    // Centred when it fits; scrolls when large text makes it taller.
    return LayoutBuilder(
      builder: (context, bounds) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: bounds.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.page,
              vertical: AppSpace.xxl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: PaperCard(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.xl,
                      AppSpace.xl,
                      AppSpace.xl,
                      AppSpace.l,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // A still paper moon, no animation while paused. Never
                        // Bumpy: this is also the screen after a loss.
                        Center(
                          child: Container(
                            key: const ValueKey('paused-moon'),
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.moon,
                              border: Border.all(color: palette.edge),
                              boxShadow: paperShadows(palette),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        Semantics(
                          header: true,
                          child: WholeWordText(
                            'Everything is paused.',
                            style: AppText.title.copyWith(color: palette.ink),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpace.m),
                        Text(
                          'Take all the time you need. '
                          'We are right here whenever you are ready.',
                          style: AppText.body.copyWith(color: palette.inkSoft),
                          textAlign: TextAlign.center,
                        ),
                        if (state.eraseFailed) ...[
                          const SizedBox(height: AppSpace.l),
                          Text(
                            state.erasePending
                                ? "Erase didn't finish. Some of your data may "
                                      'already be removed, so the app stays '
                                      'paused until Erase finishes.'
                                : "Erase didn't finish, so your data is still "
                                      'on this device. Please try Erase again.',
                            style: AppText.body.copyWith(color: palette.ink),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpace.l),
                          // Already confirmed once; retry goes straight to
                          // Erase.
                          ElevatedButton(
                            onPressed: state.eraseAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.danger,
                              foregroundColor: palette.onDanger,
                              minimumSize: const Size.fromHeight(
                                AppSpace.target,
                              ),
                            ),
                            child: const Text('Try Erase again'),
                          ),
                        ],
                        const SizedBox(height: AppSpace.xl),

                        // Resume (disabled while an Erase is unfinished on
                        // disk). The one main button.
                        ElevatedButton(
                          onPressed: state.erasePending ? null : state.resume,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppSpace.target),
                          ),
                          child: const Text('Resume'),
                        ),
                        const SizedBox(height: AppSpace.xxl),
                        if (state.dueDate != null) ...[
                          // Resets today's check-ins and leaves Pause (its
                          // dialog says so). Outlined: Resume stays the one
                          // main button.
                          OutlinedButton(
                            onPressed: state.erasePending
                                ? null
                                : () => confirmStartFresh(context, state),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                AppSpace.target,
                              ),
                            ),
                            child: const Text(
                              'Reset today’s check-ins and resume',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpace.s),
                        ],

                        // Erase all data: a link in the danger colour.
                        TextButton(
                          onPressed: () => confirmErase(context, state),
                          style: TextButton.styleFrom(
                            foregroundColor: palette.danger,
                            minimumSize: const Size.fromHeight(AppSpace.target),
                          ),
                          child: const Text('Erase all data'),
                        ),
                      ],
                    ),
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
