import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../widgets/visit_topics.dart';

/// One clean page to hold up at the visit: the questions in large type, then
/// the topics as plain words. Only a close control and a quiet Edit.
class VisitScreen extends StatelessWidget {
  const VisitScreen({super.key, required this.state});

  final AppState state;

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
        final body = TextStyle(fontSize: 24, height: 1.35, color: palette.ink);
        return Scaffold(
          backgroundColor: palette.paper,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
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
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => VisitTopics.edit(context, state),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'My questions',
                            style: TextStyle(
                              fontSize: 32,
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (questions.isEmpty && topics.isEmpty)
                          Text(
                            'Nothing here yet. Tap Edit to add a question.',
                            style: body.copyWith(color: palette.inkSoft),
                          ),
                        for (final (index, question) in questions.indexed)
                          Padding(
                            key: ValueKey('visit-show-question-$index'),
                            padding: const EdgeInsets.only(bottom: 18),
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(question.text, style: body),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (topics.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Semantics(
                            header: true,
                            child: Text(
                              'Topics',
                              style: body.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          for (final need in topics)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(need.label, style: body),
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
