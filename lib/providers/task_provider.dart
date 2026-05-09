import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/hive_service.dart';
import '../core/scheduling_intelligence.dart';
import '../models/task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/notifications/notification_service.dart';
import '../core/reminder_store.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    state = HiveService.taskBox.values.toList();
    _rescheduleAllReminders();
  }

  Future<void> _rescheduleAllReminders() async {
    for (final t in state) {
      await _syncReminder(t);
    }
  }

  Future<void> _syncReminder(Task task) async {
    final cat = HiveService.categoryById(task.categoryId);
    await NotificationService.syncTaskReminder(task, categoryName: cat?.name ?? 'Task');
  }

  bool hasConflict(Task task) {
    return SchedulingIntelligence.hasConflict(task, state);
  }

  List<Task> conflictsFor(Task task) {
    return SchedulingIntelligence.conflictingTasks(task, state);
  }

  /// Internal helper to sync with Firebase if logged in
  Future<void> _autoSync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await syncTasks();
    }
  }

  /// Returns `false` if overlap detected and [force] is false.
  Future<bool> addTask(Task task, {bool forceThroughConflict = false}) async {
    if (!forceThroughConflict && hasConflict(task)) {
      return false;
    }
    await HiveService.taskBox.put(task.id, task);
    state = [...state, task];
    await _syncReminder(task);
    await _autoSync();
    return true;
  }

  Future<bool> updateTask(Task task, {bool forceThroughConflict = false}) async {
    if (!forceThroughConflict && hasConflict(task)) {
      return false;
    }
    await HiveService.taskBox.put(task.id, task);
    state = [
      for (final t in state)
        if (t.id == task.id) task else t
    ];
    await _syncReminder(task);
    await _autoSync();
    return true;
  }

  Future<void> deleteTask(String id) async {
    await NotificationService.cancelForTask(id);
    await ReminderStore.remove(id);
    await HiveService.taskBox.delete(id);
    state = state.where((t) => t.id != id).toList();
    
    // Cloud deletion
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(id)
          .delete();
    }
  }

  Future<void> toggleTaskCompletion(String id) async {
    final task = state.firstWhere((t) => t.id == id);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await HiveService.taskBox.put(task.id, updatedTask);
    state = [
      for (final t in state)
        if (t.id == id) updatedTask else t
    ];
    await _syncReminder(updatedTask);
    await _autoSync();
  }

  Future<void> setReminderLeadMinutes(String taskId, int? minutes) async {
    if (minutes == null) {
      await ReminderStore.clearOverride(taskId);
    } else {
      await ReminderStore.setMinutesFor(taskId, minutes);
    }
    final t = state.firstWhere((x) => x.id == taskId);
    await _syncReminder(t);
  }

  Future<void> refreshAllReminders() async {
    for (final t in state) {
      await _syncReminder(t);
    }
  }

  Future<void> syncTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (var task in state) {
        final docRef = firestore.collection('users').doc(user.uid).collection('tasks').doc(task.id);
        batch.set(docRef, {
          'id': task.id,
          'title': task.title,
          'description': task.description,
          'categoryId': task.categoryId,
          'priority': task.priority.name,
          'startTime': task.startTime.toIso8601String(),
          'endTime': task.endTime.toIso8601String(),
          'isCompleted': task.isCompleted,
          'createdAt': task.createdAt.toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Push Sync failed: $e');
      rethrow;
    }
  }

  Future<void> pullTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .get();

      final cloudTasks = snapshot.docs.map((doc) {
        final data = doc.data();
        return Task(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          categoryId: data['categoryId'],
          priority: TaskPriority.values.byName(data['priority']),
          startTime: DateTime.parse(data['startTime']),
          endTime: DateTime.parse(data['endTime']),
          isCompleted: data['isCompleted'],
          createdAt: DateTime.parse(data['createdAt']),
        );
      }).toList();

      // Clear local and save cloud tasks
      await HiveService.taskBox.clear();
      for (var t in cloudTasks) {
        await HiveService.taskBox.put(t.id, t);
      }
      
      state = cloudTasks;
      await _rescheduleAllReminders();
    } catch (e) {
      print('Pull Sync failed: $e');
      rethrow;
    }
  }
}
