import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/task.dart';
import 'preferences_store.dart';
import 'reminder_store.dart';

class HiveService {
  static const String taskBoxName = 'tasks';
  static const String categoryBoxName = 'categories';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(TaskAdapter());

    // Open Boxes
    await Hive.openBox<Task>(taskBoxName);
    await Hive.openBox<Category>(categoryBoxName);

    final categoryBox = Hive.box<Category>(categoryBoxName);
    if (categoryBox.isEmpty) {
      for (final c in Category.defaultCategories) {
        await categoryBox.put(c.id, c);
      }
    }

    await PreferencesStore.init();
    await ReminderStore.init();
  }

  static Box<Task> get taskBox => Hive.box<Task>(taskBoxName);
  static Box<Category> get categoryBox => Hive.box<Category>(categoryBoxName);

  /// Resolves a category by stable [id] even if legacy data used non-string keys.
  static Category? categoryById(String id) {
    final direct = categoryBox.get(id);
    if (direct != null) return direct;
    for (final c in categoryBox.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}
