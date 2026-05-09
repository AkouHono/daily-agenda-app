import 'package:hive_flutter/hive_flutter.dart';

/// App-wide notification and quiet-hours preferences (Hive box `app_settings`).
class PreferencesStore {
  static const _boxName = 'app_settings';
  static const _kDefaultReminder = 'default_reminder_minutes';
  static const _kDndStart = 'dnd_start_hour';
  static const _kDndEnd = 'dnd_end_hour';

  static Box<dynamic>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    if (_box!.get(_kDefaultReminder) == null) await _box!.put(_kDefaultReminder, 15);
    if (_box!.get(_kDndStart) == null) await _box!.put(_kDndStart, 22);
    if (_box!.get(_kDndEnd) == null) await _box!.put(_kDndEnd, 7);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null) throw StateError('PreferencesStore.init() not called');
    return b;
  }

  static int get defaultReminderMinutes => (_b.get(_kDefaultReminder) as int?) ?? 15;

  static Future<void> setDefaultReminderMinutes(int minutes) async {
    await _b.put(_kDefaultReminder, minutes.clamp(0, 120));
  }

  /// Inclusive start of quiet hours (0–23), e.g. 22 for 10 PM.
  static int get dndStartHour => (_b.get(_kDndStart) as int?) ?? 22;

  /// End hour (0–23), e.g. 7 for 7 AM. May cross midnight when start > end.
  static int get dndEndHour => (_b.get(_kDndEnd) as int?) ?? 7;

  static Future<void> setDndHours({required int startHour, required int endHour}) async {
    await _b.put(_kDndStart, startHour.clamp(0, 23));
    await _b.put(_kDndEnd, endHour.clamp(0, 23));
  }

  /// Returns true if [when] local time falls inside quiet hours.
  static bool isWithinQuietHours(DateTime when) {
    final h = when.hour;
    final start = dndStartHour;
    final end = dndEndHour;
    if (start == end) return false;
    if (start < end) {
      return h >= start && h < end;
    }
    return h >= start || h < end;
  }
}
