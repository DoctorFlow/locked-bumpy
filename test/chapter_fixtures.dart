import 'dart:convert';

/// Made-up, non-health chapter records for tests only.
Map<String, dynamic> chapterRecord({
  String id = 'chapter_16',
  int from = 16,
  int to = 19,
  String status = 'approved',
  String approvedBy = 'Test reviewer',
  String approvedDate = '2026-11-20',
  String title = 'Paper kites',
  String accent = '#7FB3A0',
  String illustration = 'chapter-test',
  String bumpyLine = 'I folded a tiny paper kite today.',
  String knowText = 'Kites fly best on a breezy afternoon.',
  String sourceOrg = 'Test Kite Club',
  String url = 'https://example.org/kites',
  String readyText = 'Find a ribbon you like for the kite tail.',
  String suggested = 'Which ribbon colour is the brightest?',
  String lookForward = 'A picnic on the hill with a striped blanket.',
  String curious = 'How long can a kite string be?',
  String need = 'REST',
}) => {
  'id': id,
  'from_week': from,
  'to_week': to,
  'status': status,
  'approved_by': approvedBy,
  'approved_date': approvedDate,
  'title': title,
  'accent': accent,
  'illustration': illustration,
  'art_brief': 'A kite over a paper hill.',
  'bumpy_line': bumpyLine,
  'know': {
    'text': knowText,
    'source_org': sourceOrg,
    'source_title': 'Kite basics',
    'url': url,
  },
  'ready': {'text': readyText, 'suggested_question': suggested},
  'look_forward': {'text': lookForward},
  'curious': {'question': curious, 'need': need},
};

String chapterJson(List<Map<String, dynamic>> records) => jsonEncode(records);
