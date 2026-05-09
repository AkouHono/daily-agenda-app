import '../models/task.dart';

/// Local scheduling logic: overlaps, gaps, and habit signals from past tasks.
class SchedulingIntelligence {
  SchedulingIntelligence._();

  static bool intervalsOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  static bool taskOverlaps(Task a, Task b) {
    if (a.id == b.id) return false;
    return intervalsOverlap(a.startTime, a.endTime, b.startTime, b.endTime);
  }

  /// Other incomplete tasks that overlap [candidate] in time.
  static List<Task> conflictingTasks(Task candidate, List<Task> allTasks) {
    return allTasks
        .where(
          (t) =>
              t.id != candidate.id &&
              !t.isCompleted &&
              taskOverlaps(candidate, t),
        )
        .toList();
  }

  static bool hasConflict(Task candidate, List<Task> allTasks) {
    return conflictingTasks(candidate, allTasks).isNotEmpty;
  }

  /// Count of pending tasks on the same calendar day as [day].
  static int pendingCountForDay(List<Task> tasks, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return tasks
        .where(
          (t) =>
              !t.isCompleted &&
              t.startTime.year == d.year &&
              t.startTime.month == d.month &&
              t.startTime.day == d.day,
        )
        .length;
  }

  /// Hour (0–23) with the most *completed* task starts for [categoryId], or null.
  static int? peakCompletionHourForCategory(String categoryId, List<Task> tasks) {
    final completed = tasks.where((t) => t.isCompleted && t.categoryId == categoryId);
    final buckets = List<int>.filled(24, 0);
    for (final t in completed) {
      buckets[t.startTime.hour]++;
    }
    var best = -1;
    var bestH = 0;
    for (var h = 0; h < 24; h++) {
      if (buckets[h] > best) {
        best = buckets[h];
        bestH = h;
      }
    }
    if (best <= 0) return null;
    return bestH;
  }

  /// Average completed-task duration for category (minutes), or null.
  static double? averageCompletedDurationMinutes(String categoryId, List<Task> tasks) {
    final durations = tasks
        .where((t) => t.isCompleted && t.categoryId == categoryId)
        .map((t) => t.endTime.difference(t.startTime).inMinutes)
        .where((m) => m > 0 && m < 24 * 60)
        .toList();
    if (durations.isEmpty) return null;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  /// First start time on [day] (9:00–17:30 grid) where [duration] fits without overlap.
  static DateTime? suggestNextSlot({
    required DateTime day,
    required Duration duration,
    required List<Task> tasksOnDay,
  }) {
    final pending = tasksOnDay.where((t) => !t.isCompleted).toList();
    for (var h = 9; h <= 17; h++) {
      for (final minute in const [0, 30]) {
        if (h == 17 && minute > 0) continue;
        final start = DateTime(day.year, day.month, day.day, h, minute);
        final end = start.add(duration);
        if (end.hour > 18 || (end.hour == 18 && end.minute > 0)) continue;
        final probe = Task(
          id: '__probe__',
          title: '',
          description: '',
          categoryId: '',
          priority: TaskPriority.medium,
          startTime: start,
          endTime: end,
          createdAt: start,
        );
        if (!hasConflict(probe, pending)) return start;
      }
    }
    return null;
  }

  /// Narrative tips for home screen (no network).
  static List<String> buildAgendaTips({
    required List<Task> tasks,
    required DateTime selectedDay,
    required Map<String, String> categoryIdToName,
  }) {
    final tips = <String>[];
    final day = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dayTasks = tasks.where((t) {
      final s = t.startTime;
      return s.year == day.year && s.month == day.month && s.day == day.day;
    }).toList();

    final pending = dayTasks.where((t) => !t.isCompleted).toList();
    final completedToday = dayTasks.where((t) => t.isCompleted).length;

    for (final t in pending) {
      final others = conflictingTasks(t, tasks);
      if (others.isNotEmpty) {
        tips.add('Overlap: "${t.title}" runs into ${others.length} other task(s). Consider shifting one block.');
        break;
      }
    }

    if (pending.isNotEmpty) {
      final high = pending.where((t) => t.priority == TaskPriority.high).length;
      if (high > 0) {
        tips.add('You have $high high-priority block(s) today — tackle the earliest one while energy is high.');
      }
    }

    if (completedToday > 0 && pending.isEmpty) {
      tips.add('All tasks for this day are done. Great momentum — streak-friendly day.');
    }

    for (final t in pending) {
      final h = peakCompletionHourForCategory(t.categoryId, tasks);
      if (h != null && (t.startTime.hour - h).abs() >= 3) {
        final name = categoryIdToName[t.categoryId] ?? 'this category';
        tips.add('You often finish $name tasks around ${h.toString().padLeft(2, '0')}:00 — current times differ.');
        break;
      }
    }

    final overload = pending.length >= 8;
    if (overload) {
      tips.add('Heavy day (${pending.length} tasks). Merge or defer low-impact items to protect focus.');
    }

    if (tips.isEmpty) {
      tips.add('Tip: batch similar categories back-to-back to reduce context switching.');
    }
    return tips;
  }
}
