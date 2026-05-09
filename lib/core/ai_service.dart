import 'package:dio/dio.dart';
import '../models/task.dart';

class AIService {
  static const String _apiKey = 'AIzaSyApR5VbL9cm4u-i21NBSIYidYja8Dye33E';
  static final _dio = Dio();

  /// Takes a task title and returns a structured breakdown string
  static Future<String> breakdownTask(String title) async {
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

    final data = {
      "contents": [
        {
          "parts": [
            {"text": "I am using a productivity app. Please break down the task \"$title\" into 4-6 clear, actionable sub-tasks. Format your response as a simple bulleted list. Keep it concise and professional."}
          ]
        }
      ]
    };

    try {
      final response = await _dio.post(url, data: data);
      final text = response.data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.trim();
    } catch (e) {
      if (e is DioException) {
        print('AI DEBUG ERROR: ${e.response?.statusCode} - ${e.response?.data}');
      }
      return 'AI Error: Unable to reach Gemini API. Please check your connection.';
    }
  }

  /// Returns a list of strings for sub-tasks (used in TaskDetailScreen)
  static Future<List<String>> suggestSubTasks({
    required String title,
    required String categoryName,
    required TaskPriority priority,
    required int habitSampleCount,
  }) async {
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

    final prompt = '''
    Task: $title
    Category: $categoryName
    Priority: ${priority.name}
    Past completions in this category: $habitSampleCount

    Suggest 3-5 specific sub-tasks to complete this. 
    Return ONLY the sub-tasks, one per line, no numbers or bullets.
    ''';

    final data = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    try {
      final response = await _dio.post(url, data: data);
      final text = response.data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    } catch (e) {
      return [];
    }
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
     if (description.isEmpty) return description;
     
     const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

     final data = {
      "contents": [
        {
          "parts": [
            {"text": "Rewrite this task description to be more professional and clear: \"$description\""}
          ]
        }
      ]
    };

     try {
      final response = await _dio.post(url, data: data);
      final text = response.data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.trim();
    } catch (e) {
      return description;
    }
  }
}
