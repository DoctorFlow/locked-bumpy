/// A made-up shared "urgent" record about paper boats. Not health text: it
/// only exercises the shape and rules of Amendment 2 in
/// `specs/GUIDE-CONTRACT.md`.
Map<String, dynamic> paperBoatUrgent({
  String status = 'approved',
  String reviewer = 'Fixture reviewer',
  String date = '2026-11-24',
  List<Object?>? signs,
}) => {
  'id': 'urgent_signs',
  'status': status,
  'approved_by': status == 'approved' ? reviewer : '',
  'approved_date': status == 'approved' ? date : '',
  'last_checked': '2026-11-24',
  'title': 'Pull the boat out of the pond',
  'intro': 'Rain or shine, lift it out, if you see any of these:',
  'signs':
      signs ??
      [
        'The sail has a hole in it',
        'The hull is soaked through',
        'A duck is sitting on the deck',
      ],
  'action': 'Fetch a dry towel. If none is near, ask the pond keeper.',
  'sources': [
    {
      'key': 'pond-club',
      'org': 'Pond Club',
      'title': 'Boat rescue card',
      'url': 'https://example.org/rescue',
    },
  ],
};
