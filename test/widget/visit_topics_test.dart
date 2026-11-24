import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Today saves a visit topic independently of care and can remove it',
    (t) async {
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load(now: () => DateTime(2026, 11, 23));
      await state.saveVisitTopics({MaternalNeed.water});
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      Future<void> tap(Finder finder) async {
        await t.ensureVisible(finder);
        await t.pumpAndSettle();
        await t.tap(finder.hitTestable());
        await t.pumpAndSettle();
      }

      await tap(find.text('Save Iron for my visit'));
      expect((await AppState.load()).visitTopics, {
        MaternalNeed.iron,
        MaternalNeed.water,
      });
      expect(state.completedCheckIns, isEmpty);
      await tap(find.text('Iron saved · View visit list'));
      await tap(find.byKey(const ValueKey('visit-topic-iron')));
      await tap(find.text('Save visit list'));
      expect(find.text('Save Iron for my visit'), findsOneWidget);
      expect((await AppState.load()).visitTopics, {MaternalNeed.water});
      expect(state.completedCheckIns, isEmpty);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a parent can prepare, change and erase a private visit list', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final state = await AppState.load(now: () => DateTime(2026, 11, 23));
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    Future<void> tap(Finder f) async {
      await t.ensureVisible(f);
      await t.pumpAndSettle();
      await t.tap(f.hitTestable());
      await t.pumpAndSettle();
    }

    await tap(find.text('Guides'));
    final waterGuide = find.byKey(const PageStorageKey(MaternalNeed.water));
    // The need cards are taller now: scroll the Water card into view first.
    await t.scrollUntilVisible(waterGuide, 120);
    await tap(find.descendant(of: waterGuide, matching: find.text('Water')));
    await tap(
      find.descendant(
        of: waterGuide,
        matching: find.text('Add to my visit list'),
      ),
    );
    expect(
      t
          .widget<FilterChip>(find.byKey(const ValueKey('visit-topic-water')))
          .selected,
      isTrue,
    );
    await t.enterText(
      find.byType(TextFormField),
      'Could we talk about my routine?',
    );
    await tap(find.byKey(const ValueKey('visit-topic-rest')));
    await tap(find.text('Save visit list'));
    expect(state.visitTopics, {MaternalNeed.water, MaternalNeed.rest});
    expect(state.completedCheckIns, isEmpty);
    final waterSaved = find.descendant(
      of: waterGuide,
      matching: find.text('On my visit list'),
    );
    await tap(waterSaved);
    await tap(find.byKey(const ValueKey('visit-topic-rest')));
    await tap(find.byTooltip('Close visit list'));
    final restored = await AppState.load();
    expect(restored.visitQuestion, 'Could we talk about my routine?');
    expect(restored.visitTopics, {MaternalNeed.water, MaternalNeed.rest});
    await tap(waterSaved);
    expect(find.text('Could we talk about my routine?'), findsOneWidget);
    await tap(find.byKey(const ValueKey('visit-topic-water')));
    await tap(find.byTooltip('Pause').hitTestable());
    expect(find.text('Could we talk about my routine?'), findsNothing);
    expect(find.text('Everything is paused.'), findsOneWidget);
    expect((await AppState.load()).visitTopics, {
      MaternalNeed.water,
      MaternalNeed.rest,
    });
    expect(find.text('For my next visit'), findsNothing);
    await state.eraseAll();
    expect((await AppState.load()).visitTopics, isEmpty);
    expect((await AppState.load()).visitQuestion, isEmpty);
    await t.pumpWidget(const SizedBox());
  });
}
