import 'package:flutter/material.dart';

import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
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
        final questions = state.visitQuestions;
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.xl,
                      AppSpace.s,
                      AppSpace.xl,
                      AppSpace.xxl,
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
                        for (final (index, question) in questions.indexed)
                          Padding(
                            key: ValueKey('visit-show-question-$index'),
                            padding: const EdgeInsets.only(bottom: AppSpace.l),
                            child: MergeSemantics(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.m),
                                  Expanded(
                                    child: Text(question.text, style: body),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (topics.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.s),
                          Semantics(
                            header: true,
                            child: Text(
                              'Topics',
                              style: body.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: AppSpace.s),
                          for (final need in topics)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpace.s,
                              ),
                              child: Text(needWord(need), style: body),
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
}
