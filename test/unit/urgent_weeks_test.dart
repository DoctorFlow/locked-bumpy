import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_line.dart';
import 'package:little_bumpy/domain/models/urgent_signs.dart';

// GUIDE-CONTRACT Amendment 4 with the bundled urgent list: a sign whose
// from_week is later than the parent's week moves to the end, in a last
// quiet group; nothing is ever hidden; no week means the file's order.

const movement =
    'Your baby is moving less, has stopped moving, or the pattern has changed.';
const afterBirth =
    'After birth: soaking a pad within an hour, or clots bigger than an egg.';

UrgentSigns bundled() => UrgentSigns.review(
  File('assets/content/urgent_signs.json').readAsStringSync(),
  drafts: true,
)!;

AppLine laterTitle() => AppLines.review(
  File('assets/content/app_lines.json').readAsStringSync(),
  drafts: true,
)[AppLines.urgentLaterTitle]!;

void main() {
  test('the file sets a week on the movement and after-birth signs only', () {
    expect(bundled().fromWeeks, {movement: 16, afterBirth: 37});
  });

  for (final withTitle in [true, false]) {
    final label = withTitle ? 'with the last group title' : 'title hidden';
    UrgentSigns list() =>
        withTitle ? bundled().withLaterTitle(laterTitle()) : bundled();

    test('$label: week 9 no longer opens with the baby-movement sign', () {
      final u = list();
      final signs = u.signsFor(9);
      expect(signs.first, isNot(movement));
      expect(signs.first, u.signs[1]);
      final groups = u.groupsFor(9);
      if (withTitle) {
        expect(groups.last.later, isTrue);
        expect(groups.last.title, laterTitle().text);
        expect(groups.last.signs, [movement, afterBirth]);
        expect(signs.sublist(signs.length - 2), [movement, afterBirth]);
      } else {
        expect(groups.first.signs.sublist(2), [movement, afterBirth]);
        expect(groups.length, u.groups.length);
      }
    });

    test('$label: week 30 keeps the movement sign in its normal place', () {
      final u = list();
      expect(u.signsFor(30).first, movement);
      expect(u.groupsFor(30).first.signs.first, movement);
      // After birth still waits until week 37: in the last group, or at the
      // end of its own group when that title is hidden.
      if (withTitle) {
        expect(u.signsFor(30).last, afterBirth);
      } else {
        expect(u.groupsFor(30).first.signs.last, afterBirth);
      }
      expect(u.signsFor(37), u.signs);
      expect(u.groupsFor(40).any((g) => g.later), isFalse);
    });

    test('$label: every sign is present, once, at every week', () {
      final u = list();
      for (final week in [null, for (var w = 4; w <= 42; w++) w]) {
        final signs = u.signsFor(week);
        expect(signs, hasLength(u.signs.length), reason: 'week $week');
        expect(signs.toSet(), u.signs.toSet(), reason: 'week $week');
        expect(
          [for (final g in u.groupsFor(week)) ...g.signs],
          signs,
          reason: 'week $week',
        );
      }
    });

    test('$label: with no week known the order is the file order', () {
      final u = list();
      expect(u.signsFor(null), u.signs);
      expect(u.groupsFor(null), same(u.groups));
    });
  }

  test('a flat list without groups moves the same signs to the end', () {
    final row =
        jsonDecode(File('assets/content/urgent_signs.json').readAsStringSync())
            as Map<String, dynamic>;
    row.remove('groups');
    final u = UrgentSigns.review(jsonEncode(row), drafts: true)!;
    expect(u.groups, isEmpty);
    expect(u.signsFor(9).sublist(u.signs.length - 2), [movement, afterBirth]);
    expect(u.signsFor(null), u.signs);
  });

  test('a broken sign_weeks entry keeps the list and that sign in place', () {
    final row =
        jsonDecode(File('assets/content/urgent_signs.json').readAsStringSync())
            as Map<String, dynamic>;
    row['sign_weeks'] = [
      {'sign': 'Not a sign on the list', 'from_week': 20},
      {'sign': movement, 'from_week': 'sixteen'},
      {'sign': afterBirth, 'from_week': 99},
    ];
    final u = UrgentSigns.review(jsonEncode(row), drafts: true)!;
    expect(u.fromWeeks, isEmpty);
    expect(u.signsFor(9), u.signs);
  });

  test('app lines: drafts only in a review build, word rules apply', () {
    final json = File('assets/content/app_lines.json').readAsStringSync();
    expect(AppLines.review(json, drafts: false), isEmpty);
    for (final row in (jsonDecode(json) as List).cast<Map>()) {
      expect(row['status'], 'draft', reason: row['id'] as String);
      expect(row['approved_by'], isEmpty);
      expect(row['approved_date'], isEmpty);
      expect(AppLines.ruleIssue(row['text'] as String), isNull);
    }
    expect(AppLines.ruleIssue('You should rest.'), isNotNull);
    expect(AppLines.ruleIssue('Call your doctor.'), isNotNull);
    expect(AppLines.ruleIssue('Rest — now.'), isNotNull);
  });
}
