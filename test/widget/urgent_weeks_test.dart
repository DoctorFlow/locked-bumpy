import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_line.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/urgent_signs.dart';
import 'package:little_bumpy/presentation/screens/urgent_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/urgent_weeks_test.dart' show movement, afterBirth;

// The urgent page in the parent's week (GUIDE-CONTRACT Amendment 4).
void main() {
  UrgentSigns list() =>
      UrgentSigns.review(
        File('assets/content/urgent_signs.json').readAsStringSync(),
        drafts: true,
      )!.withLaterTitle(
        AppLines.review(
          File('assets/content/app_lines.json').readAsStringSync(),
          drafts: true,
        )[AppLines.urgentLaterTitle],
      );

  Future<void> pumpPage(WidgetTester t, String? due) async {
    SharedPreferences.setMockInitialValues({'due_date_iso': ?due});
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(AppPalette.halloween),
        home: UrgentScreen(state: state, urgent: list()),
      ),
    );
    await t.pumpAndSettle();
  }

  String signAt(WidgetTester t, int i) => t
      .widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey('urgent-sign-$i')),
          matching: find.byType(Text),
        ),
      )
      .data!;

  testWidgets('week 9: the page opens with bleeding, and the movement sign '
      'sits in the last quiet group', (t) async {
    await pumpPage(t, '2027-06-26');
    final u = list();
    expect(signAt(t, 0), u.signs[1]);
    expect(find.byKey(const ValueKey('urgent-later-group')), findsOneWidget);
    final n = u.signs.length;
    expect(signAt(t, n - 2), movement);
    expect(signAt(t, n - 1), afterBirth);
    for (final s in u.signs) {
      expect(find.text(s), findsOneWidget);
    }
  });

  testWidgets('week 30: the movement sign opens the list in its own group', (
    t,
  ) async {
    await pumpPage(t, '2027-02-02');
    final u = list();
    expect(signAt(t, 0), movement);
    expect(signAt(t, u.signs.length - 1), afterBirth);
    for (final s in u.signs) {
      expect(find.text(s), findsOneWidget);
    }
  });

  testWidgets('no week known: the file order, no last group', (t) async {
    await pumpPage(t, null);
    expect(signAt(t, 0), movement);
    expect(find.byKey(const ValueKey('urgent-later-group')), findsNothing);
  });
}
