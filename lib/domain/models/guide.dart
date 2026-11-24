import 'dart:convert';
import 'content_record.dart';
import 'need.dart';

/// One sourced sentence from a guide. Today shows one by itself.
class GuideFact {
  const GuideFact({
    required this.id,
    required this.kind,
    required this.text,
    required this.sourceOrg,
  });

  final String id;

  /// `why` | `food` | `pairing` | `care_team` | `good_to_know`
  final String kind;
  final String text;

  /// The organisation of the fact's source, e.g. `NHS`.
  final String sourceOrg;
}

/// Where a fact comes from. Shown as text; the app opens no links.
class GuideSource {
  const GuideSource({
    required this.key,
    required this.org,
    required this.title,
    required this.url,
  });

  final String key, org, title, url;
}

/// One guide per need, shown as five cards. Built only through [reviewAll],
/// so every field has already passed the rules in `specs/GUIDE-CONTRACT.md`.
class Guide {
  const Guide({
    required this.need,
    required this.isDraft,
    required this.lastChecked,
    required this.costumeLine,
    required this.point,
    required this.ifHard,
    required this.callToday,
    required this.callNow,
    required this.closing,
    required this.facts,
    required this.tryThis,
    required this.questions,
    required this.sources,
  });

  final MaternalNeed need;

  /// True when this guide is visible only because this is a review build.
  final bool isDraft;

  /// `yyyy-MM-dd`.
  final String lastChecked;
  final String costumeLine, point, ifHard, callToday, callNow, closing;
  final List<GuideFact> facts;
  final List<String> tryThis, questions;
  final List<GuideSource> sources;

  /// The fact Today shows: it changes once per full turn of the six needs.
  GuideFact factFor(int dayNumber) => facts[(dayNumber ~/ 6) % facts.length];

  // ── Parsing behind the gate ───────────────────────────────────────────────

  static const callTodayStart = 'Call your doctor or midwife today if ';
  static const callTodayEnd = ', even if you are not sure.';
  static const callNowStart = 'Call emergency services now if ';
  static const closings = [
    'Your doctor or midwife decides what is right for you.',
    'Your doctor or midwife decides the amount.',
  ];
  static const factKinds = [
    'why',
    'food',
    'pairing',
    'care_team',
    'good_to_know',
    'good_to_know',
  ];

  /// Words never used in the app-voice fields.
  static const appVoiceBanned = [
    'should',
    'must',
    'need to',
    'have to',
    'missed',
    'forgot',
    'failed',
    'lazy',
    'weight',
    'diet',
    'streak',
    'lesson',
    'learn',
    'teach',
  ];

  static final List<(String, RegExp)> _appBannedPatterns = [
    for (final term in appVoiceBanned)
      (
        term,
        RegExp(
          r'\b' +
              term.split(' ').map(RegExp.escape).join(r'\s+') +
              r'(?:s|es|d|ed|ing)?\b',
          caseSensitive: false,
        ),
      ),
  ];
  static final _digit = RegExp(r'\d');
  static final _doctorAlone = RegExp(
    r'\bdoctors?\b(?!\s+or\s+midwi(?:fe|ves)\b)',
    caseSensitive: false,
  );
  static final _sentenceEnd = RegExp(r'[.!?]+(?=\s|$)');

  /// Reads every record in [json] and returns the guides the gate lets
  /// through. A broken record hides only its own guide; two records for one
  /// need hide that need.
  static Map<MaternalNeed, Guide> reviewAll(
    String json, {
    bool drafts = ContentGate.draftsByDefault,
  }) {
    final rows = jsonDecode(json);
    if (rows is! List) return const {};
    final seen = <MaternalNeed>{};
    final twice = <MaternalNeed>{};
    final guides = <MaternalNeed, Guide>{};
    for (final row in rows) {
      final need = row is Map ? _needOf(row['need']) : null;
      if (need == null) continue;
      if (!seen.add(need)) twice.add(need);
      final guide = _tryParse(row as Map, need, drafts);
      if (guide != null) guides[need] = guide;
    }
    guides.removeWhere((need, _) => twice.contains(need));
    return Map.unmodifiable(guides);
  }

  /// The first rule [row] breaks, or null when every field rule passes.
  /// Review status is not a rule here; [reviewAll] asks the gate.
  static String? ruleIssue(Map<dynamic, dynamic> row) {
    try {
      return _ruleIssue(row);
    } catch (e) {
      return 'unreadable record: $e';
    }
  }

  static MaternalNeed? _needOf(Object? value) {
    if (value is! String) return null;
    for (final need in MaternalNeed.values) {
      if (need.needName == value) return need;
    }
    return null;
  }

  static Guide? _tryParse(Map row, MaternalNeed need, bool drafts) {
    final String status, reviewer, date;
    try {
      status = row['status'] as String;
      reviewer = row['approved_by'] as String? ?? '';
      date = row['approved_date'] as String? ?? '';
    } catch (_) {
      return null;
    }
    final verdict = ContentGate.review(
      status: status,
      reviewer: reviewer,
      date: date,
      rulesPass: ruleIssue(row) == null,
      drafts: drafts,
    );
    if (verdict == Review.hidden) return null;
    final sources = [
      for (final s in row['sources'] as List)
        GuideSource(
          key: s['key'] as String,
          org: s['org'] as String,
          title: s['title'] as String,
          url: s['url'] as String,
        ),
    ];
    final orgs = {for (final s in sources) s.key: s.org};
    return Guide(
      need: need,
      isDraft: verdict == Review.draft,
      lastChecked: row['last_checked'] as String,
      costumeLine: (row['costume_line'] as String).trim(),
      point: (row['point'] as String).trim(),
      ifHard: (row['if_hard'] as String).trim(),
      callToday: (row['call_today'] as String).trim(),
      callNow: (row['call_now'] as String? ?? '').trim(),
      closing: (row['closing'] as String).trim(),
      facts: List.unmodifiable([
        for (final f in row['facts'] as List)
          GuideFact(
            id: f['id'] as String,
            kind: f['kind'] as String,
            text: (f['text'] as String).trim(),
            sourceOrg: orgs[f['source']]!,
          ),
      ]),
      tryThis: List.unmodifiable([
        for (final t in row['try_this'] as List) (t as String).trim(),
      ]),
      questions: List.unmodifiable([
        for (final q in row['questions'] as List) (q as String).trim(),
      ]),
      sources: List.unmodifiable(sources),
    );
  }

  static int _words(String text) =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  static int _sentences(String text) => _sentenceEnd.allMatches(text).length;

  static String? _appVoiceIssue(String field, String text) {
    if (text.trim().isEmpty) return '$field is empty';
    if (_digit.hasMatch(text)) return '$field contains a digit';
    for (final (term, pattern) in _appBannedPatterns) {
      if (pattern.hasMatch(text)) return '$field uses "$term"';
    }
    if (_doctorAlone.hasMatch(text)) {
      return '$field says "doctor" without "or midwife"';
    }
    return null;
  }

  static String? _sentencesIssue(String field, String text, int max) {
    final t = text.trim();
    final n = _sentences(t);
    if (n < 1 || n > max || !RegExp(r'[.!?]$').hasMatch(t)) {
      return '$field must be ${max == 1 ? 'one sentence' : 'one or two sentences'}';
    }
    return null;
  }

  static String? _ruleIssue(Map row) {
    if (_needOf(row['need']) == null) return 'unknown need';
    final id = row['id'];
    if (id is! String || id.trim().isEmpty) return 'id is empty';
    final checked = row['last_checked'];
    if (checked is! String || !ContentGate.isCalendarDate(checked)) {
      return 'last_checked is not a date';
    }

    // Sources first: facts must point at one.
    final sources = row['sources'];
    if (sources is! List || sources.isEmpty) return 'no sources';
    final keys = <String>{};
    for (final s in sources) {
      if (s is! Map) return 'a source is not a record';
      for (final field in ['key', 'org', 'title', 'url']) {
        final v = s[field];
        if (v is! String || v.trim().isEmpty) return 'a source has no $field';
      }
      if (!keys.add(s['key'] as String)) return 'two sources share a key';
    }

    final costume = row['costume_line'];
    if (costume is! String || costume.trim().isEmpty) {
      return 'costume_line is empty';
    }
    if (_words(costume) > 16) return 'costume_line is over 16 words';
    if (_digit.hasMatch(costume)) return 'costume_line contains a digit';
    final babyBanned = ContentGate.bannedTerm(costume);
    if (babyBanned != null) return 'costume_line uses "$babyBanned"';

    final point = row['point'];
    if (point is! String) return 'point is missing';
    final pointIssue =
        _appVoiceIssue('point', point) ?? _sentencesIssue('point', point, 2);
    if (pointIssue != null) return pointIssue;
    if (_words(point) > 35) return 'point is over 35 words';

    final facts = row['facts'];
    if (facts is! List || facts.length < 5 || facts.length > 6) {
      return 'facts must number five or six';
    }
    final factIds = <String>{};
    for (var i = 0; i < facts.length; i++) {
      final f = facts[i];
      if (f is! Map) return 'fact ${i + 1} is not a record';
      if (f['kind'] != factKinds[i]) {
        return 'fact ${i + 1} must be kind ${factKinds[i]}';
      }
      final fid = f['id'];
      if (fid is! String || fid.trim().isEmpty || !factIds.add(fid)) {
        return 'fact ${i + 1} needs its own id';
      }
      final text = f['text'];
      if (text is! String) return 'fact ${i + 1} has no text';
      final textIssue =
          _appVoiceIssue('fact ${i + 1}', text) ??
          _sentencesIssue('fact ${i + 1}', text, 1);
      if (textIssue != null) return textIssue;
      if (_words(text) > 20) return 'fact ${i + 1} is over 20 words';
      if (!keys.contains(f['source'])) {
        return 'fact ${i + 1} source is not in sources';
      }
      final claims = f['claims'];
      if (claims is! List ||
          claims.isEmpty ||
          claims.any((c) => c is! String || c.trim().isEmpty)) {
        return 'fact ${i + 1} lists no claim';
      }
    }

    final tryThis = row['try_this'];
    if (tryThis is! List || tryThis.length < 3 || tryThis.length > 5) {
      return 'try_this must hold three to five ideas';
    }
    for (final t in tryThis) {
      if (t is! String) return 'a try_this idea is not text';
      final issue = _appVoiceIssue('try_this', t);
      if (issue != null) return issue;
      if (_words(t) > 8) return 'a try_this idea is over 8 words';
    }

    final ifHard = row['if_hard'];
    if (ifHard is! String) return 'if_hard is missing';
    final hardIssue =
        _appVoiceIssue('if_hard', ifHard) ??
        _sentencesIssue('if_hard', ifHard, 2);
    if (hardIssue != null) return hardIssue;
    if (_words(ifHard) > 35) return 'if_hard is over 35 words';

    final questions = row['questions'];
    if (questions is! List || questions.length != 3) {
      return 'questions must number exactly three';
    }
    final asked = <String>{};
    for (final q in questions) {
      if (q is! String) return 'a question is not text';
      final issue = _appVoiceIssue('a question', q);
      if (issue != null) return issue;
      if (!q.trim().endsWith('?')) return 'a question does not end with "?"';
      if (_words(q) > 16) return 'a question is over 16 words';
      if (!asked.add(q.trim())) return 'two questions are the same';
    }

    final callToday = row['call_today'];
    if (callToday is! String ||
        !callToday.startsWith(callTodayStart) ||
        !callToday.trimRight().endsWith(callTodayEnd) ||
        callToday.trim().length <=
            callTodayStart.length + callTodayEnd.length) {
      return 'call_today must begin "$callTodayStart" and end "$callTodayEnd"';
    }
    final callNow = row['call_now'] ?? '';
    if (callNow is! String ||
        (callNow.trim().isNotEmpty &&
            (!callNow.startsWith(callNowStart) ||
                callNow.trim().length <= callNowStart.length))) {
      return 'call_now must be empty or begin "$callNowStart"';
    }
    for (final (field, text) in [
      ('call_today', callToday),
      ('call_now', callNow),
    ]) {
      if (_doctorAlone.hasMatch(text)) {
        return '$field says "doctor" without "or midwife"';
      }
    }
    final closing = row['closing'];
    if (closing is! String || !closings.contains(closing.trim())) {
      return 'closing is not one of the two fixed lines';
    }
    return null;
  }
}
