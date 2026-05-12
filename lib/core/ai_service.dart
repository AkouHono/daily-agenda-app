import '../models/task.dart';

class AIService {
  /// AI features have been removed from requirements.
  /// This service now returns default/empty values.

  /// Takes a task title and returns a structured breakdown string
  static Future<String> breakdownTask(String title) async {
    return 'Task breakdown is currently disabled.';
  }

  /// Returns a list of strings for sub-tasks (used in TaskDetailScreen)
  static Future<List<String>> suggestSubTasks({
    required String title,
    required String categoryName,
    required TaskPriority priority,
    required int habitSampleCount,
  }) async {
    return [];
  }

  /// A quick "coaching" line based on task context
  static String coachingLine(Task task, String categoryName) {
    if (task.priority == TaskPriority.high) {
      return "Focus on $categoryName today—this is a top priority.";
    }
    return "You've got this! Breaking this into steps makes it easier.";
  }

  /// Refines a task description
  static Future<String> refineDescription(String description) async {
     return description;
  }
}
