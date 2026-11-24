import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/urgent_loader.dart';
import 'package:little_bumpy/domain/models/urgent_signs.dart';

import '../support/urgent_fixture.dart';

UrgentSigns? review(Object? row, {bool drafts = false}) =>
    UrgentSigns.review(jsonEncode(row), drafts: drafts);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(UrgentLoader.debugReset);

  test('approved: shown in full, not marked', () {
    final u = review(paperBoatUrgent())!;
    expect(u.isDraft, isFalse);
    expect(u.title, 'Pull the boat out of the pond');
    expect(u.signs, hasLength(3));
    expect(u.action, startsWith('Fetch a dry towel.'));
    expect(u.sources.single.org, 'Pond Club');
    expect(u.lastChecked, '2026-11-24');
    // A one-record array reads the same as the bare record.
    expect(review([paperBoatUrgent()])!.signs, u.signs);
  });

  test('draft in a review build: shown, marked as draft', () {
    final u = review(paperBoatUrgent(status: 'draft'), drafts: true)!;
    expect(u.isDraft, isTrue);
    expect(u.signs, hasLength(3));
  });

  test('draft outside a review build: hidden', () {
    expect(review(paperBoatUrgent(status: 'draft')), isNull);
    expect(UrgentSigns.review(jsonEncode(paperBoatUrgent(status: 'draft'))),
        isNull);
    for (final status in ['needs_fix', 'rejected']) {
      expect(review(paperBoatUrgent(status: status), drafts: true), isNull);
    }
  });

  test('approved needs a reviewer and a real date', () {
    expect(review(paperBoatUrgent(reviewer: '')), isNull);
    expect(review(paperBoatUrgent(date: '2025-02-29')), isNull);
  });

  test('an empty list is hidden, approved or draft', () {
    expect(review(paperBoatUrgent(signs: [])), isNull);
    expect(review(paperBoatUrgent(status: 'draft', signs: []), drafts: true),
        isNull);
  });

  final broken = <String, Object?>{
    'a null record': null,
    'a number': 3,
    'two records': [paperBoatUrgent(), paperBoatUrgent()],
    'wrong id': {...paperBoatUrgent(), 'id': 'other'},
    'no title': {...paperBoatUrgent(), 'title': ''},
    'no intro': {...paperBoatUrgent()}..remove('intro'),
    'no action': {...paperBoatUrgent(), 'action': '  '},
    'a sign is not text': paperBoatUrgent(signs: ['Sail torn', 4]),
    'an empty sign': paperBoatUrgent(signs: ['Sail torn', ' ']),
    'a repeated sign': paperBoatUrgent(signs: ['Sail torn', 'sail torn']),
    'a sign over 14 words': paperBoatUrgent(
      signs: [List.filled(15, 'sail').join(' ')],
    ),
    'signs not a list': {...paperBoatUrgent(), 'signs': 'Sail torn'},
    'no sources': {...paperBoatUrgent(), 'sources': <Object>[]},
    'a source without a url': {
      ...paperBoatUrgent(),
      'sources': [
        {'key': 'k', 'org': 'Pond Club', 'title': 'Card', 'url': ''},
      ],
    },
    'last_checked not a date': {...paperBoatUrgent(), 'last_checked': 'soon'},
    'approved_by not text': {...paperBoatUrgent(), 'approved_by': 1},
  };
  for (final MapEntry(key: name, value: row) in broken.entries) {
    test('broken is hidden, never a crash: $name', () {
      expect(review(row), isNull);
      expect(
        review(row is Map ? {...row, 'status': 'draft'} : row, drafts: true),
        isNull,
      );
    });
  }
  test('text that is not JSON at all is hidden', () {
    expect(UrgentSigns.review('{ not json'), isNull);
    expect(UrgentSigns.review(''), isNull);
  });

  test('a sign may hold digits and plain words', () {
    final u = review(paperBoatUrgent(signs: ['Water above 2 lines on the hull']));
    expect(u!.signs.single, contains('2'));
  });

  test('the loader reads the bundle once and treats a missing file as '
      'hidden', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var reads = 0;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == UrgentLoader.path) reads++;
      return null; // as if the file were missing
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    rootBundle.evict(UrgentLoader.path);
    expect(await UrgentLoader.load(), isNull);
    expect(await UrgentLoader.load(), isNull);
    expect(reads, 1);
  });

  test('the shipped file keeps the fixed wording and its review fields', () {
    final json = File('assets/content/urgent_signs.json').readAsStringSync();
    final row = jsonDecode(json) as Map<String, dynamic>;
    expect(row['id'], 'urgent_signs');
    expect(row['title'], 'Get medical help right away');
    expect(row['intro'], 'Day or night, do not wait, if you have any of these:');
    expect(
      row['action'],
      'Call your doctor, midwife or hospital. If you cannot reach them, '
      'call emergency services.',
    );
    if (row['status'] == 'draft') {
      expect(row['approved_by'], isEmpty);
      expect(row['approved_date'], isEmpty);
    }
    if (row['status'] == 'approved') {
      // An approved file must pass, so it never silently disappears.
      expect(UrgentSigns.ruleIssue(row), isNull);
      expect(UrgentSigns.review(json), isNotNull);
    }
    // Release builds and tests never show a draft.
    if (row['status'] != 'approved') {
      expect(UrgentSigns.review(json, drafts: false), isNull);
    }
    // Once the list has signs, they pass every rule, so a review build
    // shows the draft and approval alone makes it live.
    if ((row['signs'] as List).isNotEmpty) {
      expect(UrgentSigns.ruleIssue(row), isNull);
      final shown = UrgentSigns.review(json, drafts: true)!;
      expect(shown.signs, hasLength((row['signs'] as List).length));
      expect(shown.isDraft, row['status'] == 'draft');
    }
  });
}
