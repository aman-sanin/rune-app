import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';
import '../models/task.dart';

class DatabaseService {
  // Static strings for box names to avoid typos
  static const String eventsBoxName = 'events_box';
  static const String tasksBoxName = 'tasks_box';

  // Get typed boxes
  final Box<Event> _eventsBox = Hive.box<Event>(eventsBoxName);
  final Box<Task> _tasksBox = Hive.box<Task>(tasksBoxName);

  // Public getter for the tasks box
  Box<Task> get tasksBox => _tasksBox;

  // Expose the boxes' listenables for reactive UIs
  ValueListenable<Box<Event>> get eventsListenable => _eventsBox.listenable();
  ValueListenable<Box<Task>> get tasksListenable => _tasksBox.listenable();

  // ----- Event Methods -----

  Future<void> addEvent(Event event) async {
    // Use .add() to let Hive generate a unique, auto-incrementing key.
    await _eventsBox.add(event);
  }

  Event? getEvent(dynamic key) {
    return _eventsBox.get(key);
  }

  Future<void> updateEvent(Event event) async {
    // .save() is a built-in method for HiveObjects.
    await event.save();
  }

  Future<void> deleteEvent(Event event) async {
    await event.delete();
  }

  List<Event> getCountdownEvents() {
    return _eventsBox.values.where((event) => event.countdown).toList();
  }

  // ----- Task Methods -----

  Future<void> addTask(Task task) async {
    // Use .add() here as well for auto-generated keys.
    await _tasksBox.add(task);
  }

  Future<void> updateTask(Task task) async {
    await task.save();
  }

  Future<void> deleteTask(Task task) async {
    await task.delete();
  }
}
