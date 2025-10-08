// In lib/pages/tasks.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/database_service.dart';
import 'task_details.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // The _importTasksFromCsv and _showAddOptions methods remain unchanged...
  Future<void> _importTasksFromCsv() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final file = File(filePath);
    final csvString = await file.readAsString();
    final List<List<dynamic>> rows = const CsvToListConverter().convert(
      csvString,
    );

    if (rows.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("CSV file is empty or invalid.")),
        );
      }
      return;
    }

    int successfulImports = 0;
    int failedImports = 0;
    Task? currentParentTask;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      try {
        final parentTitle = row[0].toString();
        final subtaskTitle = row[1].toString();

        if (parentTitle.isNotEmpty) {
          final newTask = Task(title: parentTitle);
          await dbService.addTask(newTask);
          currentParentTask = dbService.tasksBox.values.last;
          successfulImports++;
        } else if (subtaskTitle.isNotEmpty && currentParentTask != null) {
          final newSubtask = Task(
            title: subtaskTitle,
            parentKey: currentParentTask.key,
          );
          currentParentTask.subtasks ??= HiveList(dbService.tasksBox);
          currentParentTask.subtasks!.add(newSubtask);
          await currentParentTask.save();
          successfulImports++;
        } else {
          failedImports++;
        }
      } catch (e) {
        failedImports++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Import complete: $successfulImports tasks/subtasks added, $failedImports failed.",
          ),
        ),
      );
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.add_task),
              title: const Text('Add a new task'),
              onTap: () {
                Navigator.pop(context);
                showAddTaskDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import tasks from CSV'),
              onTap: () {
                Navigator.pop(context);
                _importTasksFromCsv();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: dbService.tasksListenable,
        builder: (context, box, _) {
          final tasks = box.values
              .where((task) => task.parentKey == null)
              .toList();

          if (tasks.isEmpty) {
            return const Center(child: Text("No tasks yet. Add one!"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskTile(task: task);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// UPDATED: TaskTile is restored to its original, more detailed state
class TaskTile extends StatefulWidget {
  final Task task;
  const TaskTile({super.key, required this.task});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  void _toggleDone(bool? value) {
    setState(() {
      widget.task.isDone = value ?? false;
      if (widget.task.isDone) {
        for (var sub in (widget.task.subtasks ?? <Task>[])) {
          sub.isDone = true;
        }
      }
      widget.task.save();
    });
  }

  // RESTORED: Logic for toggling individual subtasks
  void _toggleSubtaskDone(Task subtask, bool? value) {
    setState(() {
      subtask.isDone = value ?? false;
      if (!subtask.isDone) {
        widget.task.isDone = false;
      } else {
        // If all subtasks are done, mark the parent as done
        final allSubtasksDone =
            widget.task.subtasks?.every((s) => s.isDone) ?? true;
        if (allSubtasksDone) {
          widget.task.isDone = true;
        }
      }
      widget.task.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      // RESTORED: Column layout to show parent task and subtasks
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: widget.task.isDone,
              onChanged: _toggleDone,
            ),
            title: Text(
              widget.task.title,
              style: TextStyle(
                decoration: widget.task.isDone
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TaskDetailsScreen(taskKey: widget.task.key),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          // RESTORED: Subtask list display
          if (widget.task.subtasks?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(
                left: 48.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Column(
                children: widget.task.subtasks!.map((subtask) {
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: subtask.isDone,
                      onChanged: (val) => _toggleSubtaskDone(subtask, val),
                    ),
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration: subtask.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskDetailsScreen(taskKey: subtask.key),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

void showAddTaskDialog(BuildContext context, {Task? parentTask}) {
  final dbService = Provider.of<DatabaseService>(context, listen: false);
  final titleController = TextEditingController();
  String title = parentTask != null ? "Add Subtask" : "Add Task";

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () {
              final newTitle = titleController.text;
              if (newTitle.isEmpty) return;
              if (parentTask != null) {
                final newSubtask = Task(
                  title: newTitle,
                  parentKey: parentTask.key,
                );
                parentTask.subtasks ??= HiveList(dbService.tasksBox);
                parentTask.subtasks!.add(newSubtask);
                parentTask.save();
              } else {
                final newTask = Task(title: newTitle);
                dbService.addTask(newTask);
              }
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
