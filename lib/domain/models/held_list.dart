import 'dart:convert';

/// One record held back for the physician's re-check.
///
/// [file] is the content pack's file name (`week_cards.json`), [id] the
/// record's id in that pack (a week card's id is `week-<n>`, see
/// `WeekCard.id`), and [reason] says why, for the review sheet.
class HeldRecord {
  const HeldRecord({
    required this.file,
    required this.id,
    required this.reason,
  });

  final String file;
  final String id;
  final String reason;

  factory HeldRecord.fromJson(Map<String, dynamic> j) => HeldRecord(
    file: j['file'] as String,
    id: j['id'] as String,
    reason: j['reason'] as String,
  );
}

/// The records in `assets/content/held.json`.
///
/// A held record is treated exactly like a draft whatever its stamp says:
/// hidden in a normal build, shown with a "Held" tag in a review build. The
/// stamp itself is never changed; the physician re-checks the record and
/// takes it off this list.
class HeldList {
  HeldList(Iterable<HeldRecord> records)
    : records = List.unmodifiable(records),
      _keys = {for (final r in records) _key(r.file, r.id)};

  static const String assetPath = 'assets/content/held.json';

  /// The packs a hold can name. A hold on any other file is a mistake.
  static const Set<String> files = {'today_lines.json', 'week_cards.json'};

  static final HeldList empty = HeldList(const []);

  final List<HeldRecord> records;
  final Set<String> _keys;

  static String _key(String file, String id) => '$file\u0000$id';

  /// The bare file name of [assetPath] (`assets/content/x.json` → `x.json`).
  static String fileOf(String assetPath) => assetPath.split('/').last;

  /// Whether record [id] of [file] is held. [file] may be a full asset path.
  bool holds(String file, String id) => _keys.contains(_key(fileOf(file), id));

  /// Parses the JSON list in [raw]. Throws [FormatException] on a broken
  /// file, so a test names the problem instead of quietly holding nothing.
  static HeldList parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('held.json is not a list');
    }
    return HeldList([
      for (final e in decoded) HeldRecord.fromJson(e as Map<String, dynamic>),
    ]);
  }

  /// Every hold that names no record: an unknown file, or an id that is not
  /// in [idsByFile] for its file. An empty result means every hold is live.
  List<HeldRecord> unmatched(Map<String, Set<String>> idsByFile) => [
    for (final r in records)
      if (!files.contains(r.file) ||
          !(idsByFile[r.file]?.contains(r.id) ?? false))
        r,
  ];
}
