import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/database_service.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: dbService.tasksListenable,
        builder: (context, box, _) {
          // CORRECTED FILTER: A top-level task is one with no parentKey.
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
      ),
    );
  }
}

class TaskTile extends StatefulWidget {
  final Task task;
  const TaskTile({super.key, required this.task});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  // ... (toggleDone and toggleSubtaskDone methods are unchanged) ...
  void _toggleDone(bool? value) {
    widget.task.isDone = value ?? false;
    if (widget.task.isDone) {
      widget.task.subtasks?.forEach((sub) => sub.isDone = true);
    }
    widget.task.save();
    setState(() {});
  }

  void _toggleSubtaskDone(Task subtask, bool? value) {
    subtask.isDone = value ?? false;
    if (!subtask.isDone) {
      widget.task.isDone = false;
    } else if (widget.task.subtasks?.every((s) => s.isDone) ?? false) {
      widget.task.isDone = true;
    }
    widget.task.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method is mostly unchanged) ...
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Add Subtask",
                  icon: const Icon(Icons.add_task_outlined),
                  onPressed: () => _showAddOrEditTaskDialog(
                    context,
                    parentTask: widget.task,
                  ),
                ),
                IconButton(
                  tooltip: "Delete Task",
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    final dbService = Provider.of<DatabaseService>(
                      context,
                      listen: false,
                    );
                    dbService.deleteTask(widget.task);
                  },
                ),
              ],
            ),
            onTap: () =>
                _showAddOrEditTaskDialog(context, taskToEdit: widget.task),
          ),
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
                    onTap: () => _showAddOrEditTaskDialog(
                      context,
                      taskToEdit: subtask,
                      parentTask: widget.task,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

void _showAddOrEditTaskDialog(
  BuildContext context, {
  Task? parentTask,
  Task? taskToEdit,
}) {
  final dbService = Provider.of<DatabaseService>(context, listen: false);
  final isEditing = taskToEdit != null;
  final titleController = TextEditingController(
    text: isEditing ? taskToEdit.title : '',
  );

  String title = "Add Task";
  if (isEditing) title = "Edit Task";
  if (parentTask != null && !isEditing) title = "Add Subtask";

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

              if (isEditing) {
                taskToEdit.title = newTitle;
                parentTask != null ? parentTask.save() : taskToEdit.save();
              } else if (parentTask != null) {
                // CORRECTED: Create subtask with parentKey
                final newSubtask = Task(
                  title: newTitle,
                  parentKey: parentTask.key,
                );
                parentTask.subtasks ??= HiveList(dbService.tasksBox);
                parentTask.subtasks!.add(newSubtask);
                parentTask.save();
              } else {
                // CORRECTED: Create top-level task (no parentKey)
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
