import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/build_flags.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/week_card.dart';

ContentRecord line(String status, {String text = 'Hello.'}) => ContentRecord(
  id: 'fixture',
  category: 'greeting',
  need: 'IRON',
  mode: 'both',
  tone: 'both',
  text: text,
  status: status,
  approvedBy: status == 'approved' ? 'Fixture reviewer' : '',
  approvedDate: status == 'approved' ? '2026-11-23' : '',
);

WeekCard card(String status, {String text = 'Hello.'}) => WeekCard(
  week: 10,
  mode: 'both',
  babyLine: text,
  status: status,
  approvedBy: status == 'approved' ? 'Fixture reviewer' : '',
  approvedDate: status == 'approved' ? '2026-11-23' : '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'tests run as a release would: drafts hidden by default',
    () {
      expect(kReviewBuild, isFalse);
      expect(ContentGate.draftsByDefault, isFalse);
      expect(ContentGate.reviewRecord(line('draft')), Review.hidden);
      expect(card('draft').review(), Review.hidden);
    },
    skip: kReviewBuild ? 'review build run' : null,
  );

  test('one gate, three outcomes', () {
    Review r(String status, {bool rules = true, bool drafts = true}) =>
        ContentGate.review(
          status: status,
          reviewer: status == 'approved' ? 'Any reviewer' : '',
          date: status == 'approved' ? '2026-11-23' : '',
          rulesPass: rules,
          drafts: drafts,
        );
    expect(r('approved'), Review.shown);
    expect(r('approved', drafts: false), Review.shown);
    expect(r('approved', rules: false), Review.hidden);
    expect(r('draft'), Review.draft);
    expect(r('draft', drafts: false), Review.hidden);
    expect(r('draft', rules: false), Review.hidden);
    expect(r('needs_fix'), Review.hidden);
    expect(r('rejected'), Review.hidden);
    expect(
      ContentGate.review(
        status: 'approved',
        reviewer: '',
        date: '2026-11-23',
        rulesPass: true,
      ),
      Review.hidden,
    );
  });

  test('Today lines: a clean draft shows only in review', () {
    expect(ContentGate.reviewRecord(line('approved')), Review.shown);
    expect(ContentGate.reviewRecord(line('draft'), drafts: true), Review.draft);
    expect(
      ContentGate.reviewRecord(
        line('draft', text: 'You missed it.'),
        drafts: true,
      ),
      Review.hidden,
    );
    expect(line('draft').isDraft, isTrue);
    expect(line('approved').isDraft, isFalse);
  });

  test('week cards: approved wins over a draft for the same week', () {
    final draft = card('draft', text: 'Draft line.');
    final approved = card('approved', text: 'Reviewed line.');
    expect(
      WeekCard.findFor(
        cards: [draft, approved],
        week: 10,
        mode: 'everyday',
        drafts: true,
      ),
      same(approved),
    );
    expect(
      WeekCard.findFor(
        cards: [draft],
        week: 10,
        mode: 'everyday',
        drafts: true,
      ),
      same(draft),
    );
    expect(
      WeekCard.findFor(cards: [draft], week: 10, mode: 'everyday'),
      isNull,
    );
    expect(
      WeekCard.findFor(
        cards: [card('draft', text: 'A potion.')],
        week: 10,
        mode: 'everyday',
        drafts: true,
      ),
      isNull,
    );
  });

  test('every approved Today line and week card still shows', () async {
    final lines = ContentRecord.listFromJsonString(
      await rootBundle.loadString('assets/content/today_lines.json'),
    ).where((r) => r.status == 'approved').toList();
    final weeks = WeekCard.listFromJsonString(
      await rootBundle.loadString('assets/content/week_cards.json'),
    ).where((c) => c.status == 'approved').toList();
    for (final r in lines) {
      expect(ContentGate.reviewRecord(r), Review.shown, reason: r.id);
    }
    for (final c in weeks) {
      expect(c.review(), Review.shown, reason: 'week ${c.week}');
    }
    // The 64 records stamped before tonight.
    expect(lines.length + weeks.length, greaterThanOrEqualTo(64));
  });

  test('kReviewBuild is read only by the flag, the gate and main', () {
    final users = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.readAsStringSync().contains('kReviewBuild'))
          f.path.replaceAll('\\', '/'),
    ];
    expect(
      users,
      unorderedEquals([
        'lib/core/build_flags.dart',
        'lib/domain/models/content_record.dart',
        'lib/main.dart',
      ]),
    );
  });
}
