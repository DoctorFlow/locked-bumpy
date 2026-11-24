import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/week_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('week_cards.json — coverage', () {
    late List<WeekCard> cards;

    setUpAll(() async {
      final raw = await rootBundle.loadString('assets/content/week_cards.json');
      cards = WeekCard.listFromJsonString(raw);
    });

    test('JSON parses without error', () {
      expect(cards, isNotEmpty);
    });

    test('every week 4–42 has an approved card or a draft awaiting review', () {
      for (int w = 4; w <= 42; w++) {
        for (final mode in ['everyday', 'halloween']) {
          final approved = WeekCard.findFor(cards: cards, week: w, mode: mode);
          final draft = cards.any(
            (c) =>
                c.week == w &&
                c.status == 'draft' &&
                (c.mode == 'both' || c.mode == mode),
          );
          expect(
            approved != null || draft,
            isTrue,
            reason: 'No approved or draft $mode card for week $w',
          );
        }
      }
    });

    test('every approved card passes the gate', () {
      for (final c in cards.where((c) => c.status == 'approved')) {
        expect(
          WeekCard.findFor(
            cards: [c],
            week: c.week,
            mode: c.mode == 'both' ? 'everyday' : c.mode,
          ),
          same(c),
          reason: 'approved card week=${c.week} mode=${c.mode} fails the gate',
        );
      }
    });

    test('every draft card has empty approved_by and approved_date', () {
      for (final c in cards.where((c) => c.status == 'draft')) {
        expect(c.approvedBy, isEmpty, reason: 'draft week=${c.week}');
        expect(c.approvedDate, isEmpty, reason: 'draft week=${c.week}');
      }
    });

    test('no card has a week outside 4–42', () {
      for (final c in cards) {
        expect(c.week, inInclusiveRange(4, 42));
      }
    });
  });
}
