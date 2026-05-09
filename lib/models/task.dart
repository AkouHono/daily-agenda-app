import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final TaskPriority priority;

  @HiveField(5)
  final DateTime startTime;

  @HiveField(6)
  final DateTime endTime;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.priority,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    String? categoryId,
    TaskPriority? priority,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
