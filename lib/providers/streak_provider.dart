import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_provider.dart';

final streakProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskProvider);
  if (tasks.isEmpty) return 0;

  // Simple streak logic: consecutive days with at least one completed task
  final completedDates = tasks
      .where((t) => t.isCompleted)
      .map((t) => DateTime(t.startTime.year, t.startTime.month, t.startTime.day))
      .toSet()
      .toList();

  completedDates.sort((a, b) => b.compareTo(a)); // Newest first

  if (completedDates.isEmpty) return 0;

  int streak = 0;
  DateTime currentDay = DateTime.now();
  currentDay = DateTime(currentDay.year, currentDay.month, currentDay.day);

  // If no task completed today, check yesterday
  if (!completedDates.contains(currentDay)) {
    currentDay = currentDay.subtract(const Duration(days: 1));
  }

  for (var i = 0; i < 365; i++) {
    final checkDay = currentDay.subtract(Duration(days: i));
    if (completedDates.contains(checkDay)) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
});
