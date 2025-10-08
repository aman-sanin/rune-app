// In lib/pages/task_details.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../services/database_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final dynamic taskKey;
  const TaskDetailsScreen({super.key, required this.taskKey});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late final DatabaseService _dbService;
  late Task _task;
  late final TextEditingController _titleController;
  late final TextEditingController _newSubtaskController;
  late final FocusNode _subtaskFocusNode;
  bool _isAddingSubtask = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    final task = _dbService.tasksBox.get(widget.taskKey);

    if (task == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      _task = Task(title: "Deleted Task");
    } else {
      _task = task;
    }
    _titleController = TextEditingController(text: _task.title);
    _newSubtaskController = TextEditingController();
    _subtaskFocusNode = FocusNode();

    _newSubtaskController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _newSubtaskController.dispose();
    _subtaskFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title cannot be empty.")));
      return;
    }
    _task.title = _titleController.text;
    await _task.save();
    setState(() {
      _isEditing = false;
      _isAddingSubtask = false;
    });
  }

  Future<void> _commitNewSubtask({String? value}) async {
    final title = value ?? _newSubtaskController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _isAddingSubtask = false;
      });
      return;
    }

    final newSubtask = Task(title: title, parentKey: _task.key);
    await _dbService.addTask(newSubtask);

    _task.subtasks ??= HiveList(_dbService.tasksBox);
    _task.subtasks!.add(newSubtask);
    await _task.save();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _newSubtaskController.clear();
        _subtaskFocusNode.requestFocus();
        setState(() {});
      }
    });
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task?"),
        content: const Text(
          "This will also delete all its subtasks. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _dbService.deleteTask(_task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = _newSubtaskController.text.isEmpty
        ? Colors.grey.withOpacity(0.5)
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Task" : "Task Details"),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: "Add Subtask",
              icon: const Icon(Icons.add_task_outlined),
              onPressed: () {
                if (_isAddingSubtask) {
                  _commitNewSubtask();
                } else {
                  setState(() {
                    _isAddingSubtask = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _subtaskFocusNode.requestFocus();
                    });
                  });
                }
              },
            ),
          IconButton(
            tooltip: _isEditing ? "Save Changes" : "Edit Task",
            icon: Icon(_isEditing ? Icons.save : Icons.edit_outlined),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _isEditing
                ? TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Task Title",
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    _task.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Subtasks",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _dbService.tasksListenable,
                builder: (context, Box<Task> box, _) {
                  final freshTask = box.get(_task.key);
                  final subtasks = freshTask?.subtasks ?? HiveList(box);
                  final itemCount =
                      subtasks.length + (_isAddingSubtask ? 1 : 0);

                  if (itemCount == 0 && _isEditing) {
                    return const Center(
                      child: Text("No subtasks yet. Add one!"),
                    );
                  }
                  return ListView.builder(
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (_isAddingSubtask && index == subtasks.length) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          // UPDATED: TextField is now configured for "double-enter to save"
                          child: TextField(
                            controller: _newSubtaskController,
                            focusNode: _subtaskFocusNode,
                            autofocus: true,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: "New subtask title...",
                              border: InputBorder.none,
                              icon: Icon(
                                Icons.subdirectory_arrow_right,
                                color: iconColor,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _newSubtaskController.clear();
                                  setState(() {
                                    _isAddingSubtask = false;
                                  });
                                },
                              ),
                            ),
                            // NEW: Logic to detect a double-enter
                            onChanged: (text) {
                              if (text.endsWith("\n\n")) {
                                // Remove the trailing newlines and commit
                                _commitNewSubtask(value: text.trim());
                              }
                            },
                          ),
                        );
                      }
                      final subtask = subtasks[index];
                      return ListTile(
                        title: Text(subtask.title),
                        leading: Icon(
                          subtask.isDone
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: subtask.isDone ? Colors.green : null,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TaskDetailsScreen(taskKey: subtask.key),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    },
                  );
                },
              ),
            ),
            if (_isEditing)
              Center(
                child: TextButton.icon(
                  onPressed: _deleteTask,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text("Delete Task"),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
