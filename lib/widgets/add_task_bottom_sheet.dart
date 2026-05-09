import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../core/preferences_store.dart';
import '../core/reminder_store.dart';
import '../core/scheduling_intelligence.dart';

class AddTaskBottomSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const AddTaskBottomSheet({super.key, required this.selectedDate});

  @override
  ConsumerState<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends ConsumerState<AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategoryId;
  TaskPriority _priority = TaskPriority.medium;
  late DateTime _startTime;
  late DateTime _endTime;
  int _reminderMinutes = -1;



  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final d = widget.selectedDate;
    _startTime = DateTime(d.year, d.month, d.day, now.hour, now.minute);
    _endTime = _startTime.add(const Duration(hours: 1));
    _reminderMinutes = -1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoryProvider);
      if (categories.isNotEmpty) {
        setState(() => _selectedCategoryId = categories.first.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime _combineDayAndClock(DateTime day, DateTime clock) {
    return DateTime(day.year, day.month, day.day, clock.hour, clock.minute);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final base = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    final d = widget.selectedDate;
    final merged = DateTime(d.year, d.month, d.day, picked.hour, picked.minute);
    setState(() {
      if (isStart) {
        _startTime = merged;
        if (!_endTime.isAfter(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = merged;
      }
    });
  }

  void _applySmartSlot() {
    final tasks = ref.read(taskProvider);
    final d = widget.selectedDate;
    final onDay = tasks.where((t) {
      final s = t.startTime;
      return s.year == d.year && s.month == d.month && s.day == d.day;
    }).toList();
    final slot = SchedulingIntelligence.suggestNextSlot(
      day: d,
      duration: const Duration(hours: 1),
      tasksOnDay: onDay,
    );
    if (slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No open 1h slot found 9:00–18:00 — adjust manually.')),
      );
      return;
    }
    setState(() {
      _startTime = slot;
      _endTime = slot.add(const Duration(hours: 1));
    });
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty || _selectedCategoryId == null) return;

    final task = Task(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      categoryId: _selectedCategoryId!,
      priority: _priority,
      startTime: _combineDayAndClock(widget.selectedDate, _startTime),
      endTime: _combineDayAndClock(widget.selectedDate, _endTime),
      createdAt: DateTime.now(),
    );

    if (!task.endTime.isAfter(task.startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    Future<void> persistReminderForNewTask() async {
      if (_reminderMinutes < 0) {
        await ReminderStore.clearOverride(task.id);
      } else {
        await ReminderStore.setMinutesFor(task.id, _reminderMinutes);
      }
    }

    final notifier = ref.read(taskProvider.notifier);
    if (notifier.hasConflict(task)) {
      final others = notifier.conflictsFor(task);
      final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Schedule overlap'),
              content: Text(
                'This block overlaps with ${others.length} task(s): '
                '${others.map((e) => e.title).take(3).join(", ")}${others.length > 3 ? "…" : ""}. '
                'Save anyway?',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Adjust')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save anyway')),
              ],
            ),
          ) ??
          false;
      if (!proceed) return;
      await persistReminderForNewTask();
      await notifier.addTask(task, forceThroughConflict: true);
    } else {
      await persistReminderForNewTask();
      await notifier.addTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'New task',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat.yMMMEd().format(widget.selectedDate),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _applySmartSlot,
                icon: const Icon(LucideIcons.sparkles, size: 18),
                label: const Text('Suggest next free hour'),
              ),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color : cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : cat.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTimePicker(context, 'Start', _startTime, () => _pickTime(isStart: true)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePicker(context, 'End', _endTime, () => _pickTime(isStart: false)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Reminder', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _reminderChip(context, label: 'App default (${PreferencesStore.defaultReminderMinutes}m)', value: -1),
                _reminderChip(context, label: 'Off', value: 0),
                _reminderChip(context, label: '5m', value: 5),
                _reminderChip(context, label: '15m', value: 15),
                _reminderChip(context, label: '30m', value: 30),
              ],
            ),
            const SizedBox(height: 20),
            Text('Priority', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Row(
              children: TaskPriority.values.map((p) {
                final isSelected = _priority == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          p.name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? scheme.onPrimary : scheme.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: _saveTask,
                child: const Text('Create task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _reminderChip(BuildContext context, {required String label, required int value}) {
    final selected = _reminderMinutes == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _reminderMinutes = value),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, DateTime time, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(DateFormat('HH:mm').format(time)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
