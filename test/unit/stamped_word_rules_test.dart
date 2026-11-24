import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_paths.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/week_card.dart';

/// The word rules, run over every line in `today_lines.json` and
/// `week_cards.json`, stamped lines included.
///
/// A stamped line is never edited here: only the physician changes one. So
/// a stamped line that breaks a rule is named in [awaitingPhysicianRestamp]
/// with the rule it breaks. The suite then passes, but it fails when a line
/// breaks a rule and is not on the list, or is on the list and no longer
/// breaks that rule (take it off once the corrected line is stamped). The
/// same list, with each line's text and a proposed correction, is in the
/// factory's `review/restamp-proposals.json` for the review sheet.
const Map<String, Set<String>> awaitingPhysicianRestamp = {
  'today_lines.json:bones_greeting_ev_01': {emDash},
  'today_lines.json:bones_greeting_hw_01': {emDash},
  'today_lines.json:vitamin_greeting_ev_01': {doctorAlone},
  'today_lines.json:vitamin_greeting_hw_01': {doctorAlone},
  'week_cards.json:week-9': {emDash},
  'week_cards.json:week-13': {emDash},
  'week_cards.json:week-20': {emDash},
  'week_cards.json:week-28': {emDash},
  'week_cards.json:week-40': {emDash},
  'week_cards.json:week-42': {emDash},
};

const emDash = 'no em dash';
const doctorAlone = '"doctor" only as "doctor or midwife"';

final _doctorAlone = RegExp(
  r'\bdoctors?\b(?!\s+or\s+midwi(?:fe|ves)\b)',
  caseSensitive: false,
);

/// Every word rule [text] breaks, by name.
Set<String> brokenRules(String text) => {
  if (ContentGate.bannedTerm(text) case final term?) 'banned word "$term"',
  if (text.contains('—')) emDash,
  if (_doctorAlone.hasMatch(text)) doctorAlone,
};

class _Line {
  const _Line(this.key, this.text, {required this.stamped});

  final String key;
  final String text;
  final bool stamped;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the rules themselves', () {
    test('catch an em dash, "doctor" alone and a banned word', () {
      expect(brokenRules('Hello — there.'), {emDash});
      expect(brokenRules('Ask your doctor.'), {doctorAlone});
      expect(brokenRules('Ask the doctors.'), {doctorAlone});
      expect(brokenRules('You missed it.'), {'banned word "missed"'});
    });

    test('let a clean line through', () {
      expect(brokenRules('Ask your doctor or midwife.'), isEmpty);
      expect(brokenRules('Doctors or midwives can help.'), isEmpty);
      expect(brokenRules('Week ten, more or less - hello.'), isEmpty);
    });
  });

  group('today_lines.json and week_cards.json', () {
    late List<_Line> lines;

    setUpAll(() async {
      final today = ContentRecord.listFromJsonString(
        await rootBundle.loadString(ContentPaths.todayLines),
      );
      final weeks = WeekCard.listFromJsonString(
        await rootBundle.loadString(ContentPaths.weekCards),
      );
      lines = [
        for (final r in today)
          _Line(
            'today_lines.json:${r.id}',
            r.text,
            stamped: r.approvedBy.trim().isNotEmpty,
          ),
        for (final c in weeks)
          _Line(
            'week_cards.json:${c.id}',
            '${c.babyLine}\n${c.sizeObject ?? ''}',
            stamped: c.approvedBy.trim().isNotEmpty,
          ),
      ];
    });

    test('the packs were read', () {
      expect(lines.length, greaterThan(60));
    });

    test('every line keeps the word rules, or awaits a restamp', () {
      final unlisted = <String>[];
      for (final line in lines) {
        final broken = brokenRules(line.text);
        final waiting = awaitingPhysicianRestamp[line.key] ?? const {};
        final extra = broken.difference(waiting);
        if (extra.isNotEmpty) {
          unlisted.add(
            '${line.key} breaks ${extra.join(', ')}'
            '${line.stamped ? ' (stamped: list it and propose a fix)' : ' (fix the draft)'}',
          );
        }
      }
      expect(unlisted, isEmpty, reason: unlisted.join('\n'));
    });

    test('only stamped lines wait for a restamp', () {
      final byKey = {for (final l in lines) l.key: l};
      for (final key in awaitingPhysicianRestamp.keys) {
        final line = byKey[key];
        expect(line, isNotNull, reason: '$key is on the list but not a line');
        expect(
          line!.stamped,
          isTrue,
          reason: '$key is a draft: fix its text instead',
        );
      }
    });

    test(
      'every listed rule is still broken (a fixed line leaves the list)',
      () {
        final byKey = {for (final l in lines) l.key: l};
        final stale = <String>[];
        for (final MapEntry(:key, value: rules)
            in awaitingPhysicianRestamp.entries) {
          final line = byKey[key];
          if (line == null) continue; // reported by the test above
          final gone = rules.difference(brokenRules(line.text));
          if (gone.isNotEmpty) {
            stale.add('$key no longer breaks ${gone.join(', ')}');
          }
        }
        expect(stale, isEmpty, reason: stale.join('\n'));
      },
    );
  });
}
