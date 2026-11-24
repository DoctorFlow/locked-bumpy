import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/presentation/widgets/visit_topics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  DateTime now() => DateTime(2026, 11, 23);

  test('a question round-trips through its stored form', () {
    const own = VisitQuestion('Is my iron fine?');
    const guided = VisitQuestion(
      'Could we check: my iron?',
      need: MaternalNeed.iron,
    );
    expect(VisitQuestion.tryParse(own.encode()), own);
    expect(VisitQuestion.tryParse(guided.encode()), guided);
    expect(VisitQuestion.tryParse('iron'), isNull);
    expect(VisitQuestion.tryParse('question:   '), isNull);
  });

  test('questions stay in words, in order, across a restart', () async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final state = await AppState.load(now: now);
    expect(state.isFirstRun, isFalse);

    expect(await state.addVisitQuestion('  Is my iron fine?  '), isTrue);
    expect(
      await state.addVisitQuestion('How much water?', need: MaternalNeed.water),
      isTrue,
    );
    expect(await state.addVisitQuestion('Is my iron fine?'), isTrue);
    expect(state.visitQuestions.map((q) => q.text), [
      'Is my iron fine?',
      'How much water?',
    ]);
    expect(state.visitQuestion, 'Is my iron fine?');

    await state.saveVisitTopics({MaternalNeed.rest});
    final restored = await AppState.load(now: now);
    expect(restored.visitTopics, {MaternalNeed.rest});
    expect(restored.visitQuestions, state.visitQuestions);

    expect(await restored.removeVisitQuestion('Is my iron fine?'), isTrue);
    expect(restored.hasVisitQuestion('Is my iron fine?'), isFalse);
    final cold = await AppState.load(now: now);
    expect(cold.visitQuestions.single.need, MaternalNeed.water);
    expect(cold.visitQuestion, isEmpty);
  });

  test('typing a new own question keeps the guide questions', () async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final state = await AppState.load(now: now);
    await state.addVisitQuestion('How much water?', need: MaternalNeed.water);
    await state.saveVisitTopics({}, question: 'Can I travel?');
    expect(state.visitQuestions.map((q) => q.text), [
      'Can I travel?',
      'How much water?',
    ]);
    await state.saveVisitTopics({}, question: '');
    expect(state.visitQuestions.map((q) => q.text), ['How much water?']);
  });

  test('erase removes every question', () async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final state = await AppState.load(now: now);
    await state.addVisitQuestion('How much water?', need: MaternalNeed.water);
    await state.eraseAll();
    expect((await AppState.load(now: now)).visitQuestions, isEmpty);
  });

  group('origin', () {
    test('each question remembers where it came from and the day', () async {
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load(now: now);
      expect(state.currentWeek, 16);
      await state.addVisitQuestion('Can I travel?');
      await state.addVisitQuestion(
        'When will I feel movement?',
        origin: VisitOrigin.week,
      );
      await state.addVisitQuestion(
        'What happens at the scan?',
        origin: VisitOrigin.week,
        week: 20,
      );
      await state.addVisitQuestion(
        'How much water?',
        need: MaternalNeed.water,
        origin: VisitOrigin.guide,
      );
      await state.addVisitQuestion(
        'Could we check my iron?',
        need: MaternalNeed.iron,
        origin: VisitOrigin.today,
      );
      // A need with no origin given came from a guide.
      await state.addVisitQuestion('Is rest enough?', need: MaternalNeed.rest);

      final day = DateTime(2026, 11, 23);
      final cold = await AppState.load(now: now);
      expect(cold.visitQuestions, [
        VisitQuestion('Can I travel?', added: day),
        VisitQuestion(
          'When will I feel movement?',
          origin: VisitOrigin.week,
          week: 16,
          added: day,
        ),
        VisitQuestion(
          'What happens at the scan?',
          origin: VisitOrigin.week,
          week: 20,
          added: day,
        ),
        VisitQuestion(
          'How much water?',
          need: MaternalNeed.water,
          origin: VisitOrigin.guide,
          added: day,
        ),
        VisitQuestion(
          'Could we check my iron?',
          need: MaternalNeed.iron,
          origin: VisitOrigin.today,
          added: day,
        ),
        VisitQuestion(
          'Is rest enough?',
          need: MaternalNeed.rest,
          origin: VisitOrigin.guide,
          added: day,
        ),
      ]);
    });

    test('own words come first, each group in the order added', () async {
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load(now: now);
      await state.addVisitQuestion('A guide one', need: MaternalNeed.iron);
      await state.addVisitQuestion('My first');
      await state.addVisitQuestion('A week one', origin: VisitOrigin.week);
      await state.addVisitQuestion('My second');
      expect(state.visitQuestionsOwnFirst.map((q) => q.text), [
        'My first',
        'My second',
        'A guide one',
        'A week one',
      ]);
      // The stored order is untouched.
      expect(state.visitQuestions.first.text, 'A guide one');
      expect(state.visitQuestion, 'My first');
      expect(state.newestOwnQuestion, 'My second');
    });

    test(
      'changing the words makes a picked question the parent’s own',
      () async {
        SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
        var today = DateTime(2026, 11, 23);
        final state = await AppState.load(now: () => today);
        await state.addVisitQuestion('A week one', origin: VisitOrigin.week);
        await state.addVisitQuestion('My first');
        await state.addVisitQuestion('A guide one', need: MaternalNeed.iron);
        today = DateTime(2026, 11, 26);

        expect(
          await state.editVisitQuestion('A week one', '  In my words  '),
          isTrue,
        );
        expect(state.visitQuestions.map((q) => q.text), [
          'My first',
          'A guide one',
          'In my words',
        ]);
        expect(
          state.visitQuestions.last,
          VisitQuestion('In my words', added: DateTime(2026, 11, 26)),
        );
        expect(state.newestOwnQuestion, 'In my words');

        // New words that match another question make the two one.
        expect(
          await state.editVisitQuestion('A guide one', 'My first'),
          isTrue,
        );
        expect(state.visitQuestions.map((q) => q.text), [
          'In my words',
          'My first',
        ]);
        expect(state.visitQuestions.every((q) => q.isOwnWords), isTrue);

        // Empty words and unknown questions change nothing.
        expect(await state.editVisitQuestion('My first', '  '), isFalse);
        expect(await state.editVisitQuestion('Not there', 'x'), isFalse);
        final cold = await AppState.load(now: () => today);
        expect(cold.visitQuestions, state.visitQuestions);
      },
    );

    test('a list saved in the earlier stored form loads exactly and is '
        'rewritten in the current form', () async {
      // Fixture: the stored form written by the build at 8425ff7.
      SharedPreferences.setMockInitialValues({
        'due_date_iso': '2027-05-10',
        'visit_topics': [
          'iron',
          'rest',
          'question:Can I travel?',
          'question@water:How much water is right for me?',
          'question:Where do I go when labour starts?',
          'question@vitamin:Which vitamin is worth taking?',
          'question@unknown:An old tag',
        ],
      });
      final state = await AppState.load(now: now);
      final loaded = [
        const VisitQuestion('Can I travel?'),
        const VisitQuestion(
          'How much water is right for me?',
          need: MaternalNeed.water,
        ),
        const VisitQuestion('Where do I go when labour starts?'),
        const VisitQuestion(
          'Which vitamin is worth taking?',
          need: MaternalNeed.vitamin,
        ),
        const VisitQuestion('An old tag'),
      ];
      expect(state.visitTopics, {MaternalNeed.iron, MaternalNeed.rest});
      expect(state.visitQuestions, loaded);
      // Typed (plain) questions read as own words; tagged ones as a guide's.
      expect(state.visitQuestions.map((q) => q.origin), [
        VisitOrigin.own,
        VisitOrigin.guide,
        VisitOrigin.own,
        VisitOrigin.guide,
        VisitOrigin.own,
      ]);
      expect(state.visitQuestions.map((q) => q.added), everyElement(isNull));
      expect(state.visitQuestion, 'Can I travel?');

      // The next save writes every question in the current form, unchanged.
      await state.addVisitQuestion('A new one');
      final raw = (await SharedPreferences.getInstance()).getStringList(
        'visit_topics',
      )!;
      expect(raw.take(2), ['iron', 'rest']);
      expect(raw.skip(2).every((v) => v.startsWith('q2:')), isTrue);
      final cold = await AppState.load(now: now);
      expect(cold.visitQuestions.take(5), loaded);
      expect(cold.visitTopics, {MaternalNeed.iron, MaternalNeed.rest});
    });

    test('the stored form survives odd words and rejects junk', () {
      final tricky = VisitQuestion(
        'Is "q2:" or a {brace}, a comma: fine?\nYes',
        need: MaternalNeed.bones,
        origin: VisitOrigin.today,
        added: DateTime(2027, 1, 2),
      );
      expect(VisitQuestion.tryParse(tricky.encode()), tricky);
      const week = VisitQuestion('W', origin: VisitOrigin.week, week: 32);
      expect(VisitQuestion.tryParse(week.encode()), week);
      expect(VisitQuestion.tryParse('q2:not json'), isNull);
      expect(VisitQuestion.tryParse('q2:{"t":"   "}'), isNull);
      expect(VisitQuestion.tryParse('q2:[1]'), isNull);
      // An origin this build does not know falls back to the plain reading.
      expect(
        VisitQuestion.tryParse('q2:{"t":"Hi","o":"later"}'),
        const VisitQuestion('Hi'),
      );
    });
    test('the quiet origin line says where and when, never for own words', () {
      final day = DateTime(2026, 11, 2);
      expect(visitOriginLine(VisitQuestion('Mine', added: day)), isNull);
      expect(
        visitOriginLine(
          VisitQuestion('W', origin: VisitOrigin.week, week: 20, added: day),
        ),
        'From week 20 · 2 Nov',
      );
      expect(
        visitOriginLine(
          VisitQuestion('G', need: MaternalNeed.vitamin, added: day),
        ),
        'From the prenatal vitamin guide · 2 Nov',
      );
      expect(
        visitOriginLine(
          VisitQuestion(
            'T',
            need: MaternalNeed.iron,
            origin: VisitOrigin.today,
            added: day,
          ),
        ),
        'From Today · 2 Nov',
      );
      // Saved before the day was kept: the origin alone.
      expect(
        visitOriginLine(const VisitQuestion('G', need: MaternalNeed.water)),
        'From the water guide',
      );
      expect(
        visitOriginLine(const VisitQuestion('W', origin: VisitOrigin.week)),
        'From This Week',
      );
    });
  });
}
