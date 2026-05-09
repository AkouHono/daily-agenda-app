import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../core/ai_service.dart';
import '../../core/preferences_store.dart';
import '../../core/reminder_store.dart';
import '../../core/scheduling_intelligence.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  List<String> _subTasks = [];
  bool _isLoading = false;

  Task? _current(List<Task> tasks) {
    try {
      return tasks.firstWhere((t) => t.id == widget.task.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _generateSubTasks(Task current, String categoryName) async {
    setState(() => _isLoading = true);
    final habitN = ref.read(taskProvider).where((t) => t.isCompleted && t.categoryId == current.categoryId).length;
    final subs = await AIService.suggestSubTasks(
      title: current.title,
      categoryName: categoryName,
      priority: current.priority,
      habitSampleCount: habitN,
    );
    setState(() {
      _subTasks = subs;
      _isLoading = false;
    });
  }

  Future<void> _applyReminder(Task current, int? minutes) async {
    await ref.read(taskProvider.notifier).setReminderLeadMinutes(current.id, minutes);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final categories = ref.watch(categoryProvider);
    final current = _current(tasks);
    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: const Center(child: Text('This task was removed.')),
      );
    }

    final catMatch = categories.where((c) => c.id == current.categoryId);
    final Category? cat = catMatch.isEmpty ? null : catMatch.first;
    final categoryName = cat?.name ?? 'General';

    final conflicts = SchedulingIntelligence.conflictingTasks(current, tasks);
    final raw = ReminderStore.rawMinutes(current.id);
    final effective = ReminderStore.effectiveMinutes(current.id, PreferencesStore.defaultReminderMinutes);

    return Scaffold(
      appBar: AppBar(title: const Text('Task details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              current.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat.yMMMEd().format(current.startTime)} · '
              '${DateFormat.Hm().format(current.startTime)} – ${DateFormat.Hm().format(current.endTime)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(current.description.isEmpty ? 'No description' : current.description,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
            if (conflicts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Material(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Overlaps with: ${conflicts.map((e) => e.title).join(", ")}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(AIService.coachingLine(current, categoryName),
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 24),
            Text('Reminder', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              raw == null
                  ? 'Using app default (${PreferencesStore.defaultReminderMinutes} min before start).'
                  : effective == 0
                      ? 'Reminders off for this task.'
                      : 'Fires $effective minutes before start.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('App default'),
                  selected: raw == null,
                  onSelected: (_) => _applyReminder(current, null),
                ),
                ChoiceChip(
                  label: const Text('Off'),
                  selected: raw == 0,
                  onSelected: (_) => _applyReminder(current, 0),
                ),
                for (final m in [5, 15, 30])
                  ChoiceChip(
                    label: Text('${m}m'),
                    selected: raw == m,
                    onSelected: (_) => _applyReminder(current, m),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            _buildAiSection(context, current, categoryName),
            if (_subTasks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Suggested sub-tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 10),
              ..._subTasks.map(
                (s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(LucideIcons.circle, size: 16, color: Theme.of(context).colorScheme.outline),
                    title: Text(s),
                    trailing: Icon(LucideIcons.sparkles, size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                ).animate().fadeIn().slideX(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiSection(BuildContext context, Task current, String categoryName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text('Smart breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'On-device suggestions from your title, category, and past completions.',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : () => _generateSubTasks(current, categoryName),
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.wand2),
              label: Text(_isLoading ? 'Analyzing…' : 'Generate sub-tasks'),
            ),
          ),
        ],
      ),
    );
  }
}
