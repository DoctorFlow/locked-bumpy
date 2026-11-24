import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a parent can prepare, change and erase a private visit list', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final state = await AppState.load(now: () => DateTime(2026, 11, 23));
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    Future<void> tap(Finder f) async {
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pumpAndSettle();
    }

    await tap(find.text('Guides'));
    await tap(find.text('Choose topics'));
    await tap(find.byKey(const ValueKey('visit-topic-water')));
    await tap(find.byKey(const ValueKey('visit-topic-rest')));
    await tap(find.text('Save visit list'));
    expect(state.visitTopics, {MaternalNeed.water, MaternalNeed.rest});
    expect(state.completedCheckIns, isEmpty);
    await tap(find.text('Edit visit list'));
    await tap(find.byKey(const ValueKey('visit-topic-rest')));
    await tap(find.byTooltip('Close visit list'));
    final restored = await AppState.load();
    expect(restored.visitTopics, {MaternalNeed.water, MaternalNeed.rest});
    await state.togglePause();
    await t.pumpAndSettle();
    expect(find.text('For my next visit'), findsNothing);
    await state.eraseAll();
    expect((await AppState.load()).visitTopics, isEmpty);
    await t.pumpWidget(const SizedBox());
  });
}
