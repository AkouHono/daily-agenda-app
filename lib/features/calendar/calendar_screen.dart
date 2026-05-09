import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> _tasksForDay(List<Task> tasks, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final list = tasks.where((t) {
      final s = t.startTime;
      return s.year == d.year && s.month == d.month && s.day == d.day;
    }).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final selected = _selected ?? _focused;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Use date'),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Task>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => _sameDay(_selected, d),
            calendarFormat: CalendarFormat.month,
            eventLoader: (d) => _tasksForDay(tasks, d),
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selected = selectedDay;
                _focused = focusedDay;
              });
            },
            onPageChanged: (focusedDay) => _focused = focusedDay,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  DateFormat.yMMMEd().format(selected),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._tasksForDay(tasks, selected).map(
                  (t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      t.isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: t.isCompleted ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      t.title,
                      style: TextStyle(
                        decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat.Hm().format(t.startTime)} – ${DateFormat.Hm().format(t.endTime)} · ${t.priority.name}',
                    ),
                  ),
                ),
                if (_tasksForDay(tasks, selected).isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'No tasks this day',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
