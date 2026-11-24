import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/domain/models/visit_question.dart';
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
}
