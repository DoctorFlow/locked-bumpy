import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/domain/models/need.dart';

import '../support/guide_fixture.dart';

Map<MaternalNeed, Guide> review(List<Object> rows, {bool drafts = false}) =>
    Guide.reviewAll(jsonEncode(rows), drafts: drafts);

Map<String, dynamic> withFact(int index, Map<String, dynamic> change) {
  final row = paperBoatGuide();
  final facts = [
    for (final f in row['facts'] as List)
      Map<String, dynamic>.of(f as Map<String, dynamic>),
  ];
  facts[index] = {...facts[index], ...change};
  return {...row, 'facts': facts};
}

void main() {
  test('a reviewed record that keeps every rule is shown in full', () {
    final guides = review([paperBoatGuide()]);
    final g = guides[MaternalNeed.iron]!;
    expect(g.isDraft, isFalse);
    expect(g.facts.map((f) => f.kind), [
      'why',
      'food',
      'pairing',
      'care_team',
      'good_to_know',
    ]);
    expect(g.facts[2].sourceOrg, 'Fold Guild');
    expect(g.questions, hasLength(3));
    expect(g.sources.first.title, 'Folding a paper boat');
    expect(g.lastChecked, '2026-11-24');
    expect(Guide.ruleIssue(paperBoatGuide()), isNull);
  });

  test('drafts are hidden by default and shown, marked, in review', () {
    final draft = paperBoatGuide(status: 'draft');
    expect(Guide.reviewAll(jsonEncode([draft])), isEmpty);
    expect(review([draft]), isEmpty);
    final shown = review([draft], drafts: true);
    expect(shown[MaternalNeed.iron]!.isDraft, isTrue);
    for (final status in ['needs_fix', 'rejected']) {
      expect(
        review([paperBoatGuide(status: status)], drafts: true),
        isEmpty,
        reason: status,
      );
    }
  });

  test('approved needs a reviewer and a real date', () {
    for (final (reviewer, date) in [
      ('', '2026-11-24'),
      ('  ', '2026-11-24'),
      ('Fixture reviewer', ''),
      ('Fixture reviewer', '2025-02-29'),
    ]) {
      expect(
        review([paperBoatGuide(reviewer: reviewer, date: date)]),
        isEmpty,
        reason: '[$reviewer, $date]',
      );
    }
  });

  final broken = <String, Map<String, dynamic>>{
    'digit in point': {
      ...paperBoatGuide(),
      'point': 'Fold 3 boats before lunch.',
    },
    'banned word in if_hard': {
      ...paperBoatGuide(),
      'if_hard': 'You should fold one anyway.',
    },
    '"doctor" alone in a question': {
      ...paperBoatGuide(),
      'questions': [
        'Could my doctor fold one?',
        'Which paper works best for a long trip?',
        'Could we race boats at the pond?',
      ],
    },
    'banned "learn" ending': {
      ...paperBoatGuide(),
      'try_this': ['Learning to fold', 'Draw a flag', 'Launch it'],
    },
    'point over 35 words': {
      ...paperBoatGuide(),
      'point': '${List.filled(36, 'fold').join(' ')}.',
    },
    'point of three sentences': {
      ...paperBoatGuide(),
      'point': 'Fold it. Sail it. Dry it.',
    },
    'four facts': {
      ...paperBoatGuide(),
      'facts': (paperBoatGuide()['facts'] as List).take(4).toList(),
    },
    'seven facts': {
      ...paperBoatGuide(),
      'facts': [
        ...paperBoatGuide()['facts'] as List,
        for (final id in ['x6', 'x7'])
          {
            'id': id,
            'kind': 'good_to_know',
            'text': 'Boats like calm water.',
            'source': 'pond-club',
            'claims': ['BOAT-06'],
          },
      ],
    },
    'facts out of order': withFact(0, {'kind': 'food'}),
    'fact over 20 words': withFact(1, {
      'text': '${List.filled(21, 'paper').join(' ')}.',
    }),
    'fact of two sentences': withFact(1, {'text': 'Fold it. Sail it.'}),
    'fact with unknown source': withFact(2, {'source': 'nowhere'}),
    'fact without a claim': withFact(3, {'claims': <String>[]}),
    'two facts share an id': withFact(4, {'id': 'boat-f1'}),
    'two try_this ideas': {
      ...paperBoatGuide(),
      'try_this': ['Fold a boat', 'Sail a boat'],
    },
    'six try_this ideas': {
      ...paperBoatGuide(),
      'try_this': List.filled(6, 'Fold a boat'),
    },
    'try_this idea over 8 words': {
      ...paperBoatGuide(),
      'try_this': [
        'Fold a boat from old paper on a calm sunny day',
        'Draw a flag',
        'Launch it',
      ],
    },
    'if_hard over 35 words': {
      ...paperBoatGuide(),
      'if_hard': '${List.filled(36, 'boat').join(' ')}.',
    },
    'two questions': {
      ...paperBoatGuide(),
      'questions': ['Could we fold?', 'Could we sail?'],
    },
    'question without "?"': {
      ...paperBoatGuide(),
      'questions': ['Could we fold.', 'Could we sail?', 'Could we race?'],
    },
    'question over 16 words': {
      ...paperBoatGuide(),
      'questions': [
        'Could ${List.filled(16, 'we').join(' ')} fold?',
        'Could we sail?',
        'Could we race?',
      ],
    },
    'call_today wrong start': {
      ...paperBoatGuide(),
      'call_today':
          'Phone someone if the paper tears, even if you are not sure.',
    },
    'call_today wrong end': {
      ...paperBoatGuide(),
      'call_today': 'Call your doctor or midwife today if the paper tears.',
    },
    'call_today empty middle': {
      ...paperBoatGuide(),
      'call_today':
          'Call your doctor or midwife today if , even if you are not sure.',
    },
    'call_now wrong start': {
      ...paperBoatGuide(),
      'call_now': 'Run if the pond floods.',
    },
    'other closing': {...paperBoatGuide(), 'closing': 'Happy sailing.'},
    'costume_line over 16 words': {
      ...paperBoatGuide(),
      'costume_line': List.filled(17, 'sail').join(' '),
    },
    'costume_line with a baby-voice banned word': {
      ...paperBoatGuide(),
      'costume_line': 'My potion makes the boat go.',
    },
    'no sources': {...paperBoatGuide(), 'sources': <Object>[]},
    'source without a title': {
      ...paperBoatGuide(),
      'sources': [
        {'key': 'pond-club', 'org': 'Pond Club', 'title': '', 'url': 'x'},
        {'key': 'fold-guild', 'org': 'Fold Guild', 'title': 'Dry', 'url': 'y'},
      ],
    },
    'last_checked not a date': {...paperBoatGuide(), 'last_checked': 'soon'},
    'facts is not a list': {...paperBoatGuide(), 'facts': 'none'},
  };
  for (final MapEntry(key: name, value: row) in broken.entries) {
    test('a broken record is hidden: $name', () {
      expect(Guide.ruleIssue(row), isNotNull);
      expect(review([row]), isEmpty);
      expect(
        review([
          {...row, 'status': 'draft'},
        ], drafts: true),
        isEmpty,
      );
    });
  }

  test('an emergency line and a sixth fact are allowed', () {
    final row = {
      ...paperBoatGuide(),
      'call_now': 'Call emergency services now if the boat sinks.',
      'closing': 'Your doctor or midwife decides the amount.',
      'facts': [
        ...paperBoatGuide()['facts'] as List,
        {
          'id': 'boat-f6',
          'kind': 'good_to_know',
          'text': 'Boats like calm water.',
          'source': 'pond-club',
          'claims': ['BOAT-06'],
        },
      ],
    };
    final g = review([row])[MaternalNeed.iron]!;
    expect(g.facts, hasLength(6));
    expect(g.callNow, startsWith('Call emergency services now if '));
  });

  test('a broken record hides only that guide', () {
    final guides = review([
      paperBoatGuide(),
      {...paperBoatGuide(need: 'WATER'), 'point': 'Fold 2 boats.'},
      paperBoatGuide(need: 'REST'),
      'not a record',
      {...paperBoatGuide(), 'need': 'TEA'},
    ]);
    expect(
      guides.keys,
      unorderedEquals([MaternalNeed.iron, MaternalNeed.rest]),
    );
  });

  test('two records for one need hide that need', () {
    final guides = review([
      paperBoatGuide(),
      paperBoatGuide(),
      paperBoatGuide(need: 'BONES'),
    ]);
    expect(guides.keys, [MaternalNeed.bones]);
  });

  test('Today rotates one fact per full turn of the six needs', () {
    final g = review([paperBoatGuide()])[MaternalNeed.iron]!;
    expect(g.factFor(0).id, 'boat-f1');
    expect(g.factFor(5).id, 'boat-f1');
    expect(g.factFor(6).id, 'boat-f2');
    expect(g.factFor(29).id, 'boat-f5');
    expect(g.factFor(30).id, 'boat-f1');
  });

  test('the bundled guides file is an array the gate can read', () {
    final json = File('assets/content/guides.json').readAsStringSync();
    final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    expect(
      rows.map((r) => r['need']).toSet(),
      hasLength(rows.length),
      reason: 'one record per need',
    );
    for (final row in rows.where((r) => r['status'] == 'draft')) {
      expect(row['approved_by'], isEmpty);
      expect(row['approved_date'], isEmpty);
    }
    // Every approved record must pass, so none silently disappears.
    final approved = rows.where((r) => r['status'] == 'approved');
    for (final row in approved) {
      expect(Guide.ruleIssue(row), isNull, reason: row['id'] as String?);
    }
    expect(Guide.reviewAll(json).length, approved.length);
    expect(File('assets/content/guide_articles.json').existsSync(), isFalse);
  });
}
