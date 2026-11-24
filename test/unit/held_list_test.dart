import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/content/content_paths.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/held_list.dart';
import 'package:little_bumpy/domain/models/week_card.dart';

/// `assets/content/held.json`: stamped records held back for the physician's
/// re-check are gated exactly like drafts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ContentGate.debugDrafts = null;
    ContentLoader.debugSetHeld(null);
    ContentLoader.clearCache();
  });

  Future<HeldList> shippedHolds() async =>
      HeldList.parse(await rootBundle.loadString(HeldList.assetPath));

  Future<Map<String, Set<String>>> shippedIds() async => {
    'today_lines.json': {
      for (final r in ContentRecord.listFromJsonString(
        await rootBundle.loadString(ContentPaths.todayLines),
      ))
        r.id,
    },
    'week_cards.json': {
      for (final c in WeekCard.listFromJsonString(
        await rootBundle.loadString(ContentPaths.weekCards),
      ))
        c.id,
    },
  };

  group('held.json, the shipped list', () {
    test('parses, and every hold says why', () async {
      final held = await shippedHolds();
      expect(held.records, isNotEmpty);
      for (final r in held.records) {
        expect(r.reason.trim(), isNotEmpty, reason: '${r.file} ${r.id}');
      }
    });

    test('every hold names a real record (a stale id fails here)', () async {
      final stale = (await shippedHolds()).unmatched(await shippedIds());
      expect(
        stale.map((r) => '${r.file} ${r.id}'),
        isEmpty,
        reason:
            'held.json names records that do not exist. Fix the id or take '
            'the hold off the list.',
      );
    });

    test(
      'holds the three week cards PRODUCT.md calls wrong, and week 20',
      () async {
        final held = await shippedHolds();
        for (final id in ['week-8', 'week-9', 'week-20', 'week-35']) {
          expect(held.holds('week_cards.json', id), isTrue, reason: id);
        }
      },
    );

    test('week card ids are unique, so a hold names one card', () async {
      final cards = WeekCard.listFromJsonString(
        await rootBundle.loadString(ContentPaths.weekCards),
      );
      final ids = cards.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('the stale-id check', () {
    final ids = {
      'today_lines.json': {'iron_greeting_ev_01'},
      'week_cards.json': {'week-9'},
    };

    test('catches an id that matches no record', () {
      final held = HeldList(const [
        HeldRecord(file: 'week_cards.json', id: 'week-9', reason: 'r'),
        HeldRecord(file: 'week_cards.json', id: 'week-99', reason: 'r'),
      ]);
      expect(held.unmatched(ids).map((r) => r.id), ['week-99']);
    });

    test('catches a file a hold cannot name', () {
      final held = HeldList(const [
        HeldRecord(file: 'chapters.json', id: 'chapter_8', reason: 'r'),
      ]);
      expect(held.unmatched(ids), hasLength(1));
    });

    test('catches an id filed under the wrong pack', () {
      final held = HeldList(const [
        HeldRecord(file: 'today_lines.json', id: 'week-9', reason: 'r'),
      ]);
      expect(held.unmatched(ids), hasLength(1));
    });

    test('a broken file fails loudly instead of holding nothing', () {
      expect(() => HeldList.parse('{}'), throwsFormatException);
      expect(() => HeldList.parse('[{"file": 1}]'), throwsA(anything));
    });
  });

  group('a held week card', () {
    Future<WeekCard?> week(int w, {required bool review}) async {
      ContentGate.debugDrafts = review;
      final cards = await ContentLoader.loadWeekCards();
      return WeekCard.findFor(cards: cards, week: w, mode: 'everyday');
    }

    test('never shows with the review flag off', () async {
      for (final w in [8, 9, 35]) {
        for (final mode in ['everyday', 'halloween']) {
          ContentGate.debugDrafts = false;
          final cards = await ContentLoader.loadWeekCards();
          expect(
            WeekCard.findFor(cards: cards, week: w, mode: mode),
            isNull,
            reason: 'week $w ($mode) must fall back like a week with no card',
          );
        }
      }
    });

    test('shows as held with the review flag on, stamp untouched', () async {
      final card = await week(9, review: true);
      expect(card, isNotNull);
      expect(card!.isHeld, isTrue);
      expect(card.isDraft, isTrue);
      expect(card.review(), Review.draft);
      expect(card.status, 'approved');
      expect(card.approvedBy, isNotEmpty);
    });

    test('taking the id off the list restores it', () async {
      final held = await shippedHolds();
      ContentLoader.debugSetHeld(
        HeldList(held.records.where((r) => r.id != 'week-9')),
      );
      final card = await week(9, review: false);
      expect(card, isNotNull);
      expect(card!.isHeld, isFalse);
      expect(card.review(), Review.shown);
      expect(await week(8, review: false), isNull, reason: 'still held');
    });

    test('neighbouring weeks are not touched', () async {
      for (final w in [7, 10, 34, 36]) {
        final card = await week(w, review: false);
        expect(card, isNotNull, reason: 'week $w');
        expect(card!.isHeld, isFalse, reason: 'week $w');
      }
    });
  });

  group('a held Today line', () {
    const id = 'iron_greeting_ev_01';
    HeldList holdIron() => HeldList(const [
      HeldRecord(file: 'today_lines.json', id: id, reason: 'test hold'),
    ]);

    test('is hidden with the review flag off', () async {
      ContentLoader.debugSetHeld(holdIron());
      ContentGate.debugDrafts = false;
      final lines = await ContentLoader.load(ContentPaths.todayLines);
      expect(lines.map((r) => r.id), isNot(contains(id)));
    });

    test('shows as held, after the approved lines, when on', () async {
      ContentLoader.debugSetHeld(holdIron());
      ContentGate.debugDrafts = true;
      final lines = await ContentLoader.load(ContentPaths.todayLines);
      final line = lines.singleWhere((r) => r.id == id);
      expect(line.isHeld, isTrue);
      expect(line.isDraft, isTrue);
      expect(ContentGate.canDisplay(line), isFalse);
      expect(
        lines.indexOf(line),
        greaterThan(lines.lastIndexWhere((r) => !r.isDraft)),
      );
    });

    test('comes back when the hold is lifted', () async {
      ContentLoader.debugSetHeld(HeldList.empty);
      ContentGate.debugDrafts = false;
      final lines = await ContentLoader.load(ContentPaths.todayLines);
      expect(lines.singleWhere((r) => r.id == id).isHeld, isFalse);
    });
  });
}
