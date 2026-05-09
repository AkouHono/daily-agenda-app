import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_provider.dart';

class UserLevel {
  final int level;
  final int xp;
  final int xpToNextLevel;

  UserLevel({required this.level, required this.xp, required this.xpToNextLevel});
}

final levelProvider = Provider<UserLevel>((ref) {
  final tasks = ref.watch(taskProvider);
  final completedCount = tasks.where((t) => t.isCompleted).length;
  
  const xpPerTask = 50;
  final totalXp = completedCount * xpPerTask;
  
  final level = (totalXp / 500).floor() + 1;
  final currentLevelXp = totalXp % 500;
  
  return UserLevel(
    level: level,
    xp: currentLevelXp,
    xpToNextLevel: 500,
  );
});
