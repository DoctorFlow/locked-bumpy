/// Made-up guide records about paper boats. Not health text: they only
/// exercise the shape and the rules of `specs/GUIDE-CONTRACT.md`.
Map<String, dynamic> paperBoatGuide({
  String need = 'IRON',
  String status = 'approved',
  String reviewer = 'Fixture reviewer',
  String date = '2026-11-24',
}) => {
  'id': 'guide_${need.toLowerCase()}',
  'need': need,
  'status': status,
  'approved_by': status == 'approved' ? reviewer : '',
  'approved_date': status == 'approved' ? date : '',
  'last_checked': '2026-11-24',
  'costume_line': 'My cape is a sail, so I am the boat captain.',
  'point': 'Paper boats sail best when every fold is crisp.',
  'facts': [
    {
      'id': 'boat-f1',
      'kind': 'why',
      'text': 'A crisp fold keeps the paper boat steady on a pond.',
      'source': 'pond-club',
      'claims': ['BOAT-01'],
    },
    {
      'id': 'boat-f2',
      'kind': 'food',
      'text': 'Thick paper holds its shape longer than thin paper.',
      'source': 'pond-club',
      'claims': ['BOAT-02'],
    },
    {
      'id': 'boat-f3',
      'kind': 'pairing',
      'text': 'Wax crayon on the hull keeps water out a little longer.',
      'source': 'fold-guild',
      'claims': ['BOAT-03'],
    },
    {
      'id': 'boat-f4',
      'kind': 'care_team',
      'text': 'A friend at the pond can help you launch from the bank.',
      'source': 'pond-club',
      'claims': ['BOAT-04'],
    },
    {
      'id': 'boat-f5',
      'kind': 'good_to_know',
      'text': 'Folded boats work in puddles as well as ponds.',
      'source': 'fold-guild',
      'claims': ['BOAT-05'],
    },
  ],
  'try_this': [
    'Fold a boat from old paper',
    'Draw a flag on the sail',
    'Launch it from a calm edge',
  ],
  'if_hard': 'On windy days, a boat in the bath is still a boat.',
  'questions': [
    'Could you show me the first fold again?',
    'Which paper works best for a long trip?',
    'Could we race boats at the pond?',
  ],
  'call_today':
      'Call your doctor or midwife today if the paper turns to mush, '
      'even if you are not sure.',
  'call_now': '',
  'closing': 'Your doctor or midwife decides what is right for you.',
  'sources': [
    {
      'key': 'pond-club',
      'org': 'Pond Club',
      'title': 'Folding a paper boat',
      'url': 'https://example.org/boats',
    },
    {
      'key': 'fold-guild',
      'org': 'Fold Guild',
      'title': 'Keeping boats dry',
      'url': 'https://example.org/dry',
    },
  ],
};
