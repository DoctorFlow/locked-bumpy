import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/services/prefs_service.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const marker = 'erase_in_progress';

/// Wraps the mock store ("disk") and fails or stalls chosen writes. Like the
/// legacy plugin, a failed write still changes the cache view; only
/// [reload] brings the cache back in line with disk.
class FlakyPrefs implements SharedPreferences {
  FlakyPrefs(this.disk);

  final SharedPreferences disk;
  final failRemove = <String>{};
  bool failPauseWrite = false;
  bool failMarkerWrite = false;
  bool failReload = false;
  Completer<void>? pauseGate;
  final pauseWrites = <bool>[];
  final _cacheGone = <String>{};
  final _cacheBools = <String, bool>{}; // failed setBool still cached

  @override
  bool containsKey(String key) =>
      _cacheBools.containsKey(key) ||
      (!_cacheGone.contains(key) && disk.containsKey(key));
  @override
  Set<String> getKeys() => {
    ...disk.getKeys().difference(_cacheGone),
    ..._cacheBools.keys,
  };
  @override
  String? getString(String key) =>
      _cacheGone.contains(key) ? null : disk.getString(key);
  @override
  bool? getBool(String key) =>
      _cacheBools[key] ?? (_cacheGone.contains(key) ? null : disk.getBool(key));

  @override
  Future<void> reload() async {
    if (failReload) throw StateError('reload failed');
    _cacheGone.clear();
    _cacheBools.clear();
    await disk.reload();
  }

  @override
  List<String>? getStringList(String key) =>
      _cacheGone.contains(key) ? null : disk.getStringList(key);
  @override
  Future<bool> setString(String key, String value) {
    _cacheGone.remove(key);
    return disk.setString(key, value);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    _cacheGone.remove(key);
    return disk.setStringList(key, value);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    if (key == 'is_paused') {
      final gate = pauseGate;
      if (gate != null) await gate.future;
      if (failPauseWrite) throw StateError('write failed');
      pauseWrites.add(value);
    }
    if (key == marker && failMarkerWrite) {
      _cacheBools[key] = value; // cache says written; disk is not
      throw StateError('marker write failed');
    }
    _cacheGone.remove(key);
    _cacheBools.remove(key);
    return disk.setBool(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    _cacheGone.add(key);
    _cacheBools.remove(key);
    if (failRemove.contains(key)) throw StateError('remove failed');
    return disk.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences disk;
  late FlakyPrefs flaky;
  late AppState state;

  AppState coldBoot() => AppState.withPrefs(PrefsService.wrap(disk));

  Future<void> start(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    disk = await SharedPreferences.getInstance();
    flaky = FlakyPrefs(disk);
    state = AppState.withPrefs(
      PrefsService.wrap(flaky),
      now: () => DateTime(2026, 11, 23),
    );
  }

  const active = <String, Object>{
    'due_date_iso': '2027-05-10',
    'baby_nickname': 'Cub',
  };

  group('Pause persistence under failure', () {
    test('Pause hides at once and a failed write never un-hides', () async {
      await start(active);
      flaky
        ..pauseGate = Completer<void>()
        ..failPauseWrite = true;
      var notified = false;
      state.addListener(() => notified = true);

      final pending = state.pause();
      expect(state.isPaused, isTrue);
      expect(notified, isTrue);

      flaky.pauseGate!.complete();
      await pending; // the failure must not escape to the button
      expect(state.isPaused, isTrue);
      expect(state.pauseSavePending, isTrue);
      expect(coldBoot().isPaused, isFalse);

      flaky
        ..pauseGate = null
        ..failPauseWrite = false;
      await state.savePendingPause();
      expect(state.pauseSavePending, isFalse);
      expect(coldBoot().isPaused, isTrue);
    });

    test('a double tap on Pause cannot unpause', () async {
      await start(active);
      await Future.wait([state.pause(), state.pause()]);
      expect(state.isPaused, isTrue);
      expect(coldBoot().isPaused, isTrue);
    });

    test(
      'rapid Pause, Resume, Pause with a slow first write ends paused',
      () async {
        await start(active);
        flaky.pauseGate = Completer<void>();
        final writes = [state.pause(), state.resume(), state.pause()];
        expect(state.isPaused, isTrue);
        flaky.pauseGate!.complete();
        await Future.wait(writes);
        expect(flaky.pauseWrites, [true, false, true]);
        expect(coldBoot().isPaused, isTrue);
      },
    );

    test('Pause tapped during Start Fresh wins on disk', () async {
      await start({...active, 'is_paused': true});
      flaky.pauseGate = Completer<void>();
      final fresh = state.clearTodayCheckIns();
      final paused = state.pause();
      flaky.pauseGate!.complete();
      await Future.wait([fresh, paused]);
      expect(state.isPaused, isTrue);
      expect(coldBoot().isPaused, isTrue);
    });
  });

  group('Erase under failure', () {
    const everything = <String, Object>{
      ...active,
      'corrected_due_date_iso': '2027-05-17',
      'skin_tone': 'deep',
      'is_halloween': false,
      'daily_needs_v2': <String>['2026-11-23', 'water'],
      'checkin_ids': 'water',
      'checkin_date': '2026-11-23',
      'other_app_setting': 'preserved',
    };

    test('partial removal keeps the marker, restart fails closed, '
        'Resume is refused and retry finishes', () async {
      await start(everything);
      flaky.failRemove.add('baby_nickname');

      expect(await state.eraseAll(), isFalse);
      expect(state.isFirstRun, isFalse);
      expect(state.isPaused, isTrue);
      expect(state.eraseFailed, isTrue);
      expect(state.erasePending, isTrue);
      // Half erased on disk: due date gone, nickname left, marker still set.
      expect(disk.getString('due_date_iso'), isNull);
      expect(disk.getString('baby_nickname'), 'Cub');
      expect(disk.getBool(marker), isTrue);
      expect(disk.getString('other_app_setting'), 'preserved');

      // Restart: no due date on disk, yet no fresh setup over leftovers.
      final rebooted = coldBoot();
      expect(rebooted.isFirstRun, isFalse);
      expect(rebooted.isPaused, isTrue);
      expect(rebooted.erasePending, isTrue);
      expect(rebooted.eraseFailed, isTrue);

      // Failed resume: neither Resume nor Start Fresh can leave Pause.
      await state.resume();
      await state.clearTodayCheckIns();
      expect(state.isPaused, isTrue);
      expect(state.erasePending, isTrue);
      await rebooted.resume();
      expect(rebooted.isPaused, isTrue);

      // Retry. The cache claimed the key gone before; reload proved otherwise.
      flaky.failRemove.clear();
      expect(await state.eraseAll(), isTrue);
      expect(state.isFirstRun, isTrue);
      expect(state.isPaused, isFalse);
      expect(state.eraseFailed, isFalse);
      expect(state.erasePending, isFalse);
      expect(disk.getKeys(), {'other_app_setting'});
      expect(coldBoot().isFirstRun, isTrue);
    });

    test('a crash mid-Erase (marker plus leftovers) fails closed and the '
        'restarted app can retry', () async {
      await start({
        marker: true,
        'baby_nickname': 'Cub', // due date already removed before the crash
        'other_app_setting': 'preserved',
      });
      expect(state.isFirstRun, isFalse);
      expect(state.isPaused, isTrue);
      expect(state.erasePending, isTrue);
      await state.resume();
      expect(state.isPaused, isTrue);

      expect(await state.eraseAll(), isTrue);
      expect(state.isFirstRun, isTrue);
      expect(disk.getKeys(), {'other_app_setting'});
    });

    test('failed marker removal keeps the app closed until retry', () async {
      await start(everything);
      flaky.failRemove.add(marker);

      expect(await state.eraseAll(), isFalse);
      expect(state.erasePending, isTrue);
      expect(disk.getBool(marker), isTrue);
      expect(coldBoot().isFirstRun, isFalse);
      expect(coldBoot().isPaused, isTrue);

      flaky.failRemove.clear();
      expect(await state.eraseAll(), isTrue);
      expect(disk.getKeys(), {'other_app_setting'});
      expect(coldBoot().isFirstRun, isTrue);
    });

    test(
      'failed marker write deletes nothing; reload shows Resume is safe',
      () async {
        await start(everything);
        flaky.failMarkerWrite = true;

        expect(await state.eraseAll(), isFalse);
        expect(state.eraseFailed, isTrue);
        expect(state.erasePending, isFalse); // cache said set; disk said no
        expect(disk.getString('due_date_iso'), '2027-05-10');
        expect(disk.getString('baby_nickname'), 'Cub');
        expect(coldBoot().isPaused, isTrue);

        await state.resume();
        expect(state.isPaused, isFalse);
        expect(state.eraseFailed, isFalse);
      },
    );

    test('an unreadable disk after Erase fails closed', () async {
      await start(everything);
      flaky.failReload = true;

      expect(await state.eraseAll(), isFalse);
      expect(state.erasePending, isTrue);
      await state.resume();
      expect(state.isPaused, isTrue);
      expect(coldBoot().isFirstRun, isFalse);

      flaky.failReload = false;
      expect(await state.eraseAll(), isTrue);
      expect(state.isFirstRun, isTrue);
      expect(disk.getKeys(), {'other_app_setting'});
    });

    test('stale or rapid taps during Erase cannot undo it', () async {
      await start(everything);
      flaky.pauseGate = Completer<void>();
      final pausing = state.pause(); // write stalls
      final erase = state.eraseAll(); // queued behind it
      expect(identical(state.eraseAll(), erase), isTrue);

      await state.resume(); // ignored while erasing
      expect(state.isPaused, isTrue);
      final latePause = state.pause(); // ignored while erasing
      await state.clearTodayCheckIns(); // ignored while erasing
      expect(state.isPaused, isTrue);

      flaky.pauseGate!.complete();
      await pausing;
      await latePause;
      expect(await erase, isTrue);
      expect(flaky.pauseWrites, [true]);
      expect(disk.getKeys(), {'other_app_setting'});
      expect(state.isFirstRun, isTrue);
    });
  });
}
