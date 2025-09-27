// lib/models/event.dart
import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  bool countdown;

  Event({
    required this.title,
    this.description,
    required this.date,
    this.countdown = false,
  });
}
