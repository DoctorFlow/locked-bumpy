import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_line.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/guide_screen.dart';
import 'package:little_bumpy/presentation/screens/guides_screen.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Topic guides (`assets/content/topic_guides.json`): the week's own big
/// question at weeks 9, 20 and 36. Drafts tonight: hidden in a normal build,
/// shown with the Draft tag in a review build.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final raw = File(TopicGuide.assetPath).readAsStringSync();
  final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  final lines = AppLines.review(
    File(AppLines.assetPath).readAsStringSync(),
    drafts: true,
  );
  const titles = {
    'guide_sick': 'Feeling sick',
    'guide_scan': 'The mid-pregnancy scan',
    'guide_time': 'Is it time?',
  };
  const chapters = {
    'guide_sick': 'chapter_8',
    'guide_scan': 'chapter_20',
    'guide_time': 'chapter_36',
  };
  const newLines = [
    'topic_guides_title',
    'topic_title_sick',
    'topic_title_scan',
    'topic_title_time',
  ];

  setUp(() {
    ContentLoader.clearCache();
    rootBundle.clear();
  });

  tearDown(() {
    ContentGate.debugDrafts = null;
    ContentLoader.clearCache();
  });

  group('content file', () {
    test('three records, all draft with empty approval fields', () {
      expect([for (final r in rows) r['id']], titles.keys.toList());
      for (final r in rows) {
        expect(r['status'], 'draft', reason: r['id']);
        expect(r['approved_by'], '', reason: r['id']);
        expect(r['approved_date'], '', reason: r['id']);
        expect(TopicGuide.ruleIssue(r), isNull, reason: r['id']);
        expect(r.containsKey('need'), isFalse);
        expect(r.containsKey('costume_line'), isFalse);
      }
    });

    test('pointers name a real chapter and a real app line', () {
      final chapterIds = {
        for (final c in ChapterLoader.parse(
          File(ChapterLoader.assetPath).readAsStringSync(),
        ))
          c.id,
      };
      for (final r in rows) {
        expect(r['chapter'], chapters[r['id']]);
        expect(chapterIds, contains(r['chapter']));
        expect(lines[r['title_line']]?.text, titles[r['id']]);
      }
    });

    test('new app lines are drafts, pass the word rules and stay short', () {
      final all =
          (jsonDecode(File(AppLines.assetPath).readAsStringSync()) as List)
              .cast<Map<String, dynamic>>();
      for (final id in newLines) {
        final row = all.singleWhere((r) => r['id'] == id);
        expect(row['status'], 'draft', reason: id);
        expect(row['approved_by'], '', reason: id);
        expect(row['approved_date'], '', reason: id);
        expect(AppLines.ruleIssue(row['text'] as String), isNull, reason: id);
        expect((row['text'] as String).split(' ').length, lessThan(5));
      }
    });

    test('normal build: the gate lets no topic guide through', () {
      expect(TopicGuide.reviewAll(raw, drafts: false), isEmpty);
      final review = TopicGuide.reviewAll(raw, drafts: true);
      expect(review, hasLength(3));
      expect(review.every((g) => g.isDraft), isTrue);
    });

    test('an unknown fact kind does not crash and still shows', () {
      final row = Map<String, dynamic>.from(rows.first);
      row['facts'] = [
        for (final f in row['facts'] as List)
          {...(f as Map), 'kind': 'something_new'},
      ];
      final out = TopicGuide.reviewAll(jsonEncode([row]), drafts: true);
      expect(out.single.facts.first.kind, 'something_new');
    });

    test('a broken record hides only itself; a broken file hides all', () {
      final broken = Map<String, dynamic>.from(rows.first)..remove('sources');
      final out = TopicGuide.reviewAll(
        jsonEncode([broken, rows[1], rows[2]]),
        drafts: true,
      );
      expect([for (final g in out) g.id], ['guide_scan', 'guide_time']);
      expect(TopicGuide.reviewAll('{not json', drafts: true), isEmpty);
      expect(
        TopicGuide.reviewAll(jsonEncode([rows[1], rows[1]]), drafts: true),
        isEmpty,
      );
    });

    test('an approved record with a rule broken stays hidden', () {
      final row = {
        ...rows.first,
        'status': 'approved',
        'approved_by': 'Reviewer',
        'approved_date': '2026-11-24',
        'point': 'You should rest.',
      };
      expect(TopicGuide.reviewAll(jsonEncode([row]), drafts: true), isEmpty);
    });
  });

  Future<AppState> boot(int week, {bool halloween = false}) async {
    final due = DateTime(2027, 5, 11 + 7 * (16 - week));
    SharedPreferences.setMockInitialValues({
      'due_date_iso': due.toIso8601String().substring(0, 10),
      'is_halloween': halloween,
    });
    return AppState.load(now: () => DateTime(2026, 11, 24));
  }

  Widget host(AppState state, Widget child, AppPalette palette) =>
      ListenableBuilder(
        listenable: state,
        builder: (_, _) => MaterialApp(
          theme: buildTheme(palette),
          home: Scaffold(body: child),
        ),
      );

  group('normal build', () {
    for (final week in [9, 20, 36]) {
      testWidgets('week $week: no topic guide on Guides or This Week', (
        t,
      ) async {
        ContentGate.debugDrafts = false;
        final state = await boot(week);
        await t.pumpWidget(LittleBumpyApp(state: state));
        await t.pumpAndSettle();
        await t.tap(find.text('This Week'));
        await t.pumpAndSettle();
        for (final title in titles.values) {
          expect(find.text(title), findsNothing, reason: 'This Week');
        }
        await t.tap(find.text('Guides'));
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('topic-guides')), findsNothing);
        expect(find.text('More guides'), findsNothing);
        for (final title in titles.values) {
          expect(find.text(title, skipOffstage: false), findsNothing);
        }
        expect(await ContentLoader.loadTopicGuides(), isEmpty);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
    }
  });

  group('review build', () {
    for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
      testWidgets('${palette.isHalloween ? 'Halloween' : 'Everyday'}: '
          'Guides lists the three by title, each Draft-tagged', (t) async {
        ContentGate.debugDrafts = true;
        final state = await boot(20, halloween: palette.isHalloween);
        await t.pumpWidget(host(state, GuidesScreen(state: state), palette));
        await t.pumpAndSettle();
        final list = find.byKey(const ValueKey('topic-guides'));
        await t.scrollUntilVisible(list, 300);
        await t.pumpAndSettle();
        expect(
          find.descendant(of: list, matching: find.text('More guides')),
          findsOneWidget,
        );
        for (final entry in titles.entries) {
          final row = find.byKey(ValueKey('topic-row-${entry.key}'));
          expect(
            find.descendant(of: row, matching: find.text(entry.value)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: row, matching: find.byType(DraftTag)),
            findsOneWidget,
          );
        }
        // The heading is a draft line too.
        expect(
          find.descendant(of: list, matching: find.byType(DraftTag)),
          findsNWidgets(4),
        );
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('a topic guide opens: title, facts with sources, tips, '
        'questions with the visit-list button, no costume', (t) async {
      ContentGate.debugDrafts = true;
      final state = await boot(20);
      await t.pumpWidget(
        host(state, GuidesScreen(state: state), AppPalette.everyday),
      );
      await t.pumpAndSettle();
      final row = find.byKey(const ValueKey('topic-row-guide_scan'));
      await t.scrollUntilVisible(row, 300);
      await t.tap(row);
      await t.pumpAndSettle();

      final guide = TopicGuide.reviewAll(raw, drafts: true)[1];
      expect(find.byType(GuideScreen), findsOneWidget);
      expect(find.text('The mid-pregnancy scan'), findsWidgets);
      expect(find.byType(BumpyAvatar), findsNothing);
      expect(find.text('Bumpy says'), findsNothing);
      expect(find.byKey(const ValueKey('guide-try-this-icon')), findsNothing);
      for (final f in guide.facts) {
        expect(find.text(f.text, skipOffstage: false), findsOneWidget);
        expect(
          find.byKey(
            ValueKey('guide-fact-source-${f.id}'),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      }
      expect(find.text('Source: NHS', skipOffstage: false), findsWidgets);
      for (final idea in guide.tryThis) {
        expect(find.text(idea, skipOffstage: false), findsOneWidget);
      }
      expect(find.byType(DraftTag, skipOffstage: false), findsWidgets);

      final ask = find.byKey(const ValueKey('guide-question-0'));
      await t.scrollUntilVisible(ask, 300);
      await t.pumpAndSettle();
      final add = find.descendant(
        of: ask,
        matching: find.text('Add to visit list'),
      );
      expect(add, findsOneWidget);
      await t.tap(add);
      await t.pumpAndSettle();
      expect(state.hasVisitQuestion(guide.questions.first), isTrue);
      expect(t.takeException(), isNull);
    });

    testWidgets('week 20 chapter: one more link under the curious question, '
        'the curious question unchanged', (t) async {
      ContentGate.debugDrafts = true;
      final state = await boot(20);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      await t.tap(find.text('This Week'));
      await t.pumpAndSettle();
      final chapter = ChapterLoader.parse(
        File(ChapterLoader.assetPath).readAsStringSync(),
      ).singleWhere((c) => c.id == 'chapter_20');
      final link = find.byKey(const ValueKey('chapter-topic-guide_scan'));
      await t.scrollUntilVisible(
        link,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await t.pumpAndSettle();
      final curious = find.text(chapter.curiousQuestion);
      expect(curious, findsOneWidget);
      expect(t.getTopLeft(link).dy, greaterThan(t.getTopLeft(curious).dy));
      expect(
        find.descendant(
          of: link,
          matching: find.text('The mid-pregnancy scan'),
        ),
        findsOneWidget,
      );
      // The other two guides belong to other chapters.
      expect(
        find.byKey(const ValueKey('chapter-topic-guide_sick')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('chapter-topic-guide_time')),
        findsNothing,
      );
      await t.tap(link);
      await t.pumpAndSettle();
      expect(find.byType(GuideScreen), findsOneWidget);
      expect(find.text('Is it time?'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('layout', () {
    for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('320 px, text x$scale, '
            '${palette.isHalloween ? 'Halloween' : 'Everyday'}: rows and '
            'guide pages fit, targets 48 px or more', (t) async {
          ContentGate.debugDrafts = true;
          t.view.physicalSize = const Size(320, 640);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final state = await boot(20, halloween: palette.isHalloween);
          Widget scaled(Widget child) => MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              textScaler: TextScaler.linear(scale),
            ),
            child: child,
          );
          await t.pumpWidget(
            scaled(host(state, GuidesScreen(state: state), palette)),
          );
          await t.pumpAndSettle();
          for (final id in titles.keys) {
            final row = find.byKey(ValueKey('topic-row-$id'));
            await t.scrollUntilVisible(row, 400, maxScrolls: 200);
            await t.pumpAndSettle();
            expect(t.getSize(row).height, greaterThanOrEqualTo(48));
            expect(t.getSize(row).width, lessThanOrEqualTo(320));
          }
          expect(t.takeException(), isNull);

          for (final entry in await ContentLoader.loadTopicGuides()) {
            await t.pumpWidget(
              scaled(
                ListenableBuilder(
                  listenable: state,
                  builder: (_, _) => MaterialApp(
                    theme: buildTheme(palette),
                    home: GuideScreen.topic(
                      state: state,
                      topic: entry,
                      urgentFromBundle: true,
                    ),
                  ),
                ),
              ),
            );
            await t.pumpAndSettle();
            await t.drag(find.byType(ListView), const Offset(0, -20000));
            await t.pumpAndSettle();
            expect(t.takeException(), isNull, reason: entry.guide.id);
          }
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
