import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import '../domain/models/urgent_signs.dart';

/// Loads the shared urgent list from the bundle, once, through the same
/// review gate as guides. Null means hidden: screens then show
/// [UrgentSigns.fallback]. A missing or broken file never crashes.
class UrgentLoader {
  UrgentLoader._();

  static const String path = 'assets/content/urgent_signs.json';

  static Future<UrgentSigns?>? _urgent;

  static Future<UrgentSigns?> load() => _urgent ??= _read();

  /// Replaces the loaded list with [signs] (null means hidden). Tests only.
  @visibleForTesting
  static void debugSet(UrgentSigns? signs) => _urgent = Future.value(signs);

  /// Forgets the loaded list, so the next [load] reads the file. Tests only.
  @visibleForTesting
  static void debugReset() => _urgent = null;

  static Future<UrgentSigns?> _read() async {
    try {
      return UrgentSigns.review(await rootBundle.loadString(path));
    } catch (_) {
      return null;
    }
  }
}
