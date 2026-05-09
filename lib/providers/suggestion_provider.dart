import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/scheduling_intelligence.dart';
import 'task_provider.dart';
import 'category_provider.dart';

/// Tips for the date currently selected on the agenda.
final agendaTipsForDateProvider = Provider.family<List<String>, DateTime>((ref, day) {
  final tasks = ref.watch(taskProvider);
  final categories = ref.watch(categoryProvider);
  final idToName = {for (final c in categories) c.id: c.name};
  return SchedulingIntelligence.buildAgendaTips(
    tasks: tasks,
    selectedDay: day,
    categoryIdToName: idToName,
  );
});
