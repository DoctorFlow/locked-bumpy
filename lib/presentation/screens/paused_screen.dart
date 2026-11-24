import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_line.dart';
import '../../domain/models/app_state.dart';

import '../widgets/data_confirmation.dart';
import '../widgets/draft_tag.dart';
import '../widgets/paper_portrait.dart';
import '../widgets/whole_word_text.dart';

/// Quiet Paused screen (lab round 3, problem 3: it was a bright Resume
/// button under a faceless disc, with no kind word).
///
/// App voice only, no costume, no animation. Bumpy is a still picture,
/// asleep, in the plain onesie. The title is the strongest thing on the
/// card; Resume is a calm outlined button; reset and erase are quieter
/// links below it. One kind line points to real support: it is content
/// (`app_lines.json`, `paused_support`) behind the review gate, so until the
/// physician approves it, it shows only in a review build, with a Draft tag.
///
/// Everything sits on one paper card. The erase retry keeps the palette's
/// `danger` / `onDanger`; so does the erase confirmation dialog.
class PausedScreen extends StatelessWidget {
  const PausedScreen({super.key, required this.state});

  final AppState state;

  /// The sleeping picture, the same art the Everyday look already uses.
  static const sleepingBumpy = 'assets/images/everyday-sleepy.png';

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, AppLine>>(
    future: ContentLoader.loadAppLines(),
    initialData: ContentLoader.loadedAppLines,
    builder: (context, snap) =>
        _build(context, snap.data?[AppLines.pausedSupport]),
  );

  Widget _build(BuildContext context, AppLine? support) {
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
                        // Bumpy asleep: a still picture, no costume, no hop,
                        // nothing read aloud. Eyes closed, so it asks
                        // nothing of a parent on a hard day.
                        Center(
                          child: ExcludeSemantics(
                            child: Image(
                              key: const ValueKey('paused-bumpy'),
                              image: paperPortrait(
                                sleepingBumpy,
                                state.skinTone,
                              ),
                              height: 112,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.l),
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
                        if (support != null) ...[
                          const SizedBox(height: AppSpace.m),
                          Text(
                            support.text,
                            key: const ValueKey('paused-support'),
                            style: AppText.body.copyWith(color: palette.ink),
                            textAlign: TextAlign.center,
                          ),
                          if (support.isDraft) ...[
                            const SizedBox(height: AppSpace.xs),
                            Center(child: DraftTag(palette: palette)),
                          ],
                        ],
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
                        // disk). A calm outlined button: clear, never loud.
                        OutlinedButton(
                          key: const ValueKey('paused-resume'),
                          onPressed: state.erasePending ? null : state.resume,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.ink,
                            minimumSize: const Size.fromHeight(AppSpace.target),
                          ),
                          child: const Text('Resume'),
                        ),
                        const SizedBox(height: AppSpace.l),
                        if (state.dueDate != null)
                          // Resets today's check-ins and leaves Pause (its
                          // dialog says so). A plain link, quieter than
                          // Resume.
                          TextButton(
                            key: const ValueKey('paused-reset'),
                            onPressed: state.erasePending
                                ? null
                                : () => confirmStartFresh(context, state),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.inkSoft,
                              minimumSize: const Size.fromHeight(
                                AppSpace.target,
                              ),
                            ),
                            child: const Text(
                              'Reset today’s check-ins and resume',
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Erase all data: the quietest link. Its confirming
                        // step keeps the danger colour.
                        TextButton(
                          key: const ValueKey('paused-erase'),
                          onPressed: () => confirmErase(context, state),
                          style: TextButton.styleFrom(
                            foregroundColor: palette.inkSoft,
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
