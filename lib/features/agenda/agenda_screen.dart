import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../calendar/calendar_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/level_provider.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/add_task_bottom_sheet.dart';
import '../analytics/analytics_screen.dart';
import '../auth/login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final categories = ref.watch(categoryProvider);
    final streak = ref.watch(streakProvider);
    final tips = ref.watch(agendaTipsForDateProvider(_selectedDate));
    final levelData = ref.watch(levelProvider);
    
    final dailyTasks = tasks.where((task) => 
      task.startTime.year == _selectedDate.year &&
      task.startTime.month == _selectedDate.month &&
      task.startTime.day == _selectedDate.day
    ).toList();

    dailyTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.flame, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        title: const Text('Daily Agenda'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendar),
            tooltip: 'View Calendar',
            onPressed: () async {
              final picked = await Navigator.push<DateTime>(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings2),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.cloud),
            tooltip: 'Cloud Sync',
            onPressed: () async {
              // Ensure user is logged in
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }

              if (FirebaseAuth.instance.currentUser != null && context.mounted) {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshing tasks from cloud...'), duration: Duration(seconds: 1)),
                  );
                  await ref.read(taskProvider.notifier).pullTasks();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Agenda updated from Cloud!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sync failed: ${e.toString().split(']').last}')),
                    );
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.barChart2),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateTimeline(),
          if (tips.isNotEmpty) _buildSuggestions(context, tips),
          _buildLevelProgress(levelData),
          Expanded(
            child: dailyTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dailyTasks.length,
                    itemBuilder: (context, index) {
                      final task = dailyTasks[index];
                      final category = categories.firstWhere(
                        (c) => c.id == task.categoryId,
                        orElse: () => categories.first,
                      );
                      return TaskTile(task: task, category: category)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 100 * index))
                          .slideX(begin: 0.2);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        tooltip: 'Create a new task',
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Task'),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildLevelProgress(UserLevel levelData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level ${levelData.level}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${levelData.xp} / ${levelData.xpToNextLevel} XP', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: levelData.xp / levelData.xpToNextLevel,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, List<String> tips) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Insights',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.take(2).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    t,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.35),
                  ),
                ),
              ),
        ],
      ),
    ).animate().slideY(begin: -0.2).fadeIn();
  }

  Widget _buildDateTimeline() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.clipboardList, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No tasks for this day',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Tap + to create a new task', style: TextStyle(color: Colors.grey)),
        ],
      ),
    ).animate().fadeIn();
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskBottomSheet(selectedDate: _selectedDate),
    );
  }
}
