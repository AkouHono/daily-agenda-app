import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final categories = ref.watch(categoryProvider);

    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;
    final completionRate = totalTasks == 0 ? 0 : (completedTasks / totalTasks * 100).toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(completedTasks, totalTasks, completionRate),
            const SizedBox(height: 30),
            Text('Tasks by Category', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildCategoryPieChart(tasks, categories),
            const SizedBox(height: 30),
            Text('Weekly Productivity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildWeeklyBarChart(tasks),
            const SizedBox(height: 30),
            Text('Completed this week', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildWeeklyCompletionChart(tasks),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(int completed, int total, int rate) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Completion',
            value: '$rate%',
            icon: LucideIcons.checkCircle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Total Tasks',
            value: '$total',
            icon: LucideIcons.list,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(List<Task> tasks, List<Category> categories) {
    final Map<String, int> counts = {};
    for (var task in tasks) {
      counts[task.categoryId] = (counts[task.categoryId] ?? 0) + 1;
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          sections: categories.map((cat) {
            final count = counts[cat.id] ?? 0;
            return PieChartSectionData(
              color: cat.color,
              value: count.toDouble(),
              title: count > 0 ? '${cat.name}\n$count' : '',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<Task> tasks) {
    // Simplified: just counting tasks per day of current week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final Map<int, int> dailyCounts = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0};

    for (var task in tasks) {
      if (task.startTime.isAfter(weekStart)) {
        dailyCounts[task.startTime.weekday] = (dailyCounts[task.startTime.weekday] ?? 0) + 1;
      }
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          barGroups: dailyCounts.entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.indigo, width: 16, borderRadius: BorderRadius.circular(4))],
          )).toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Text(days[value.toInt() - 1], style: const TextStyle(fontSize: 12));
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildWeeklyCompletionChart(List<Task> tasks) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final Map<int, int> completedByWeekday = {for (var i = 1; i <= 7; i++) i: 0};

    for (final t in tasks) {
      if (!t.isCompleted) continue;
      final s = t.startTime;
      if (s.isBefore(weekStart) || !s.isBefore(weekEnd)) continue;
      completedByWeekday[s.weekday] = (completedByWeekday[s.weekday] ?? 0) + 1;
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          barGroups: completedByWeekday.entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      color: Colors.teal,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              )
              .toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final i = value.toInt();
                  if (i < 1 || i > 7) return const SizedBox.shrink();
                  return Text(days[i - 1], style: const TextStyle(fontSize: 12));
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
