import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../widgets/need_word.dart';
import '../widgets/visit_topics.dart';
import '../widgets/whole_word_text.dart';

/// One clean page to hold up at the visit: the questions in large type, then
/// the topics as plain words. Only a close control and a quiet Edit.
///
/// The plainest page in the app: flat paper, no cards, no pictures, and the
/// largest reading type, so it can be held up across a desk.
class VisitScreen extends StatelessWidget {
  const VisitScreen({super.key, required this.state});

  final AppState state;

  /// The design system's reading style at the size this page needs. The
  /// system has no style above 18 for app text, so it is set here only.
  static final TextStyle showText = AppText.body.copyWith(
    fontSize: 24,
    height: 32 / 24,
  );

  static Future<void> open(BuildContext context, AppState state) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => VisitScreen(state: state)),
      );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final questions = state.visitQuestionsOwnFirst;
        final own = [
          for (final q in questions)
            if (q.isOwnWords) q,
        ];
        final picked = [
          for (final q in questions)
            if (!q.isOwnWords) q,
        ];
        final topics = MaternalNeed.values
            .where(state.visitTopics.contains)
            .toList();
        final body = showText.copyWith(color: palette.ink);
        final week = state.currentWeek;
        return Scaffold(
          backgroundColor: palette.paper,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.xs,
                    AppSpace.xs,
                    AppSpace.s,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.close, color: palette.ink),
                      ),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: palette.inkSoft,
                        ),
                        onPressed: () => VisitTopics.edit(context, state),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    // Room under "Copy my list": at large text on a small
                    // phone the last control can always be scrolled clear
                    // of where the tab bar and the floating note sit.
                    padding: EdgeInsets.fromLTRB(
                      AppSpace.xl,
                      AppSpace.s,
                      AppSpace.xl,
                      bottomRoom(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          // Wraps only between words; steps down in size at
                          // the largest text rather than break "questions".
                          child: WholeWordText(
                            'My questions',
                            style: AppText.display.copyWith(color: palette.ink),
                          ),
                        ),
                        // The first thing a clinician asks.
                        if (week != null) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            'Week $week',
                            style: AppText.heading.copyWith(
                              color: palette.inkSoft,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpace.xl),
                        if (questions.isEmpty && topics.isEmpty)
                          Text(
                            'Nothing here yet. Tap Edit to add a question.',
                            style: body.copyWith(color: palette.inkSoft),
                          ),
                        if (own.isNotEmpty) ...[
                          _GroupHeading(ownWordsHeading, palette: palette),
                          for (final question in own)
                            _ShownQuestion(
                              question: question,
                              style: body,
                              palette: palette,
                            ),
                        ],
                        if (picked.isNotEmpty) ...[
                          if (own.isNotEmpty)
                            const SizedBox(height: AppSpace.s),
                          _GroupHeading(pickedHeading, palette: palette),
                          for (final question in picked)
                            _ShownQuestion(
                              question: question,
                              style: body,
                              palette: palette,
                            ),
                        ],
                        if (topics.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.s),
                          _GroupHeading('Topics', palette: palette),
                          for (final need in topics)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpace.s,
                              ),
                              child: Text(needWord(need), style: body),
                            ),
                        ],
                        if (questions.isNotEmpty || topics.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.l),
                          // The one way out of the app: plain text the parent
                          // pastes wherever they like. Nothing is sent.
                          OutlinedButton.icon(
                            key: const ValueKey('visit-copy'),
                            onPressed: () => _copy(context),
                            icon: const Icon(Icons.copy_outlined),
                            label: const Text('Copy my list'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The empty room under the last control: the tab bar's height (it may
  /// sit under this page, and at 200 percent text it is tall) or, with no
  /// tab bar, the room of a floating note; never less than 96.
  static double bottomRoom(BuildContext context) {
    final note = MediaQuery.textScalerOf(context).scale(16) + 3 * AppSpace.l;
    final tabs = tabBarClearance(context);
    final room = (tabs > note ? tabs : note) + AppSpace.xxxl;
    return room < 2 * AppSpace.xxxl ? 2 * AppSpace.xxxl : room;
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await Clipboard.setData(ClipboardData(text: plainText(state)));
    } catch (_) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            key: ValueKey('visit-copy-failed'),
            behavior: SnackBarBehavior.floating,
            content: Text('Your list couldn’t be copied on this device.'),
          ),
        );
      return;
    }
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          key: ValueKey('visit-copied'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text('Your list is copied.'),
        ),
      );
  }

  /// The heading over the parent's own questions.
  static const ownWordsHeading = 'In my own words';

  /// The heading over the questions picked from the app's suggestions.
  static const pickedHeading = 'Picked from Bumpy’s suggestions';

  /// The whole list as plain text for the clipboard: the title and week,
  /// the parent's own words first, then the picked questions, then topics.
  static String plainText(AppState state) {
    final questions = state.visitQuestionsOwnFirst;
    final own = [
      for (final q in questions)
        if (q.isOwnWords) q.text,
    ];
    final picked = [
      for (final q in questions)
        if (!q.isOwnWords) q.text,
    ];
    final topics = [
      for (final need in MaternalNeed.values)
        if (state.visitTopics.contains(need)) needWord(need),
    ];
    final week = state.currentWeek;
    final lines = <String>['My questions', if (week != null) 'Week $week'];
    void group(String heading, List<String> items) {
      if (items.isEmpty) return;
      lines
        ..add('')
        ..add(heading)
        ..addAll(items.map((item) => '- $item'));
    }

    group(ownWordsHeading, own);
    group(pickedHeading, picked);
    group('Topics', topics);
    return '${lines.join('\n')}\n';
  }
}

/// A plain heading over one group on the show page.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text, {required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.m),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: AppText.heading.copyWith(color: palette.inkSoft),
        ),
      ),
    );
  }
}

/// One question on the show page, with its quiet origin line when it was
/// picked from the app's suggestions.
class _ShownQuestion extends StatelessWidget {
  const _ShownQuestion({
    required this.question,
    required this.style,
    required this.palette,
  });

  final VisitQuestion question;
  final TextStyle style;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final origin = visitOriginLine(question);
    return Padding(
      key: ValueKey('visit-show-${question.text}'),
      padding: const EdgeInsets.only(bottom: AppSpace.l),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.text, style: style),
            if (origin != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                origin,
                style: AppText.body.copyWith(color: palette.inkSoft),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
