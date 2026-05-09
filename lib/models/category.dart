import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final int iconCodePoint;

  Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  static List<Category> get defaultCategories => [
    Category(
      id: 'work',
      name: 'Work',
      colorValue: Colors.blue.value,
      iconCodePoint: Icons.work.codePoint,
    ),
    Category(
      id: 'personal',
      name: 'Personal',
      colorValue: Colors.green.value,
      iconCodePoint: Icons.person.codePoint,
    ),
    Category(
      id: 'health',
      name: 'Health',
      colorValue: Colors.red.value,
      iconCodePoint: Icons.favorite.codePoint,
    ),
    Category(
      id: 'other',
      name: 'Other',
      colorValue: Colors.grey.value,
      iconCodePoint: Icons.category.codePoint,
    ),
  ];
}
