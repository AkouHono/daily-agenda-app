import 'package:hive_flutter/hive_flutter.dart';

/// Per-task reminder lead time in minutes (0 = disabled). Keys = task ids.
class ReminderStore {
  static const _boxName = 'task_reminders';
  static Box<int>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<int>(_boxName);
  }

  static Box<int> get _b {
    final b = _box;
    if (b == null) throw StateError('ReminderStore.init() not called');
    return b;
  }

  static int? rawMinutes(String taskId) => _b.get(taskId);

  static Future<void> setMinutesFor(String taskId, int minutes) async {
    await _b.put(taskId, minutes.clamp(0, 120));
  }

  /// Use app default again (inherit [appDefault]).
  static Future<void> clearOverride(String taskId) => _b.delete(taskId);

  static Future<void> remove(String taskId) => _b.delete(taskId);

  /// Stored value if present, else [appDefault]. `0` means reminders off for this task.
  static int effectiveMinutes(String taskId, int appDefault) {
    return _b.get(taskId) ?? appDefault;
  }
}
