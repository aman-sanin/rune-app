// lib/models/task.dart
import 'package:hive/hive.dart';
part 'task.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  bool isDone;

  @HiveField(2)
  int? linkedEventId;

  @HiveField(3)
  HiveList<Task>? subtasks;

  @HiveField(4) // New field to identify subtasks
  dynamic parentKey;

  Task({
    required this.title,
    this.isDone = false,
    this.linkedEventId,
    this.parentKey,
  });
}
