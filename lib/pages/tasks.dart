import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final Box tasksBox;
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    tasksBox = Hive.box('tasksBox');

    // ✨ FIX: This section now deeply converts both tasks and their nested subtasks.
    final rawTasks = tasksBox.get('all_tasks', defaultValue: []) as List;
    tasks = rawTasks.map((task) {
      // 1. Convert the parent task
      final taskMap = Map<String, dynamic>.from(task as Map);

      // 2. If subtasks exist, convert them too
      if (taskMap['subtasks'] != null) {
        final rawSubtasks = taskMap['subtasks'] as List;
        taskMap['subtasks'] = rawSubtasks.map((subtask) {
          return Map<String, dynamic>.from(subtask as Map);
        }).toList();
      }
      return taskMap;
    }).toList();
  }

  // The rest of your code from here is correct and does not need changes.
  void _showAddOrEditTaskDialog({
    Map<String, dynamic>? parentTask,
    Map<String, dynamic>? taskToEdit,
  }) {
    final isEditing = taskToEdit != null;
    final titleController = TextEditingController(
      text: isEditing ? taskToEdit['title'] : '',
    );

    String dialogTitle;
    if (isEditing) {
      dialogTitle = "Edit Task";
    } else if (parentTask != null) {
      dialogTitle = "Add Subtask";
    } else {
      dialogTitle = "Add Task";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Task Title'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    if (isEditing) {
                      taskToEdit['title'] = titleController.text;
                    } else if (parentTask != null) {
                      parentTask['subtasks'].add({
                        "title": titleController.text,
                        "done": false,
                      });
                    } else {
                      tasks.add({
                        "title": titleController.text,
                        "done": false,
                        "subtasks": [],
                        "linkedEvent": null,
                      });
                    }
                    tasksBox.put('all_tasks', tasks);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(Map<String, dynamic> task) {
    setState(() {
      tasks.remove(task);
      tasksBox.put('all_tasks', tasks);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required with mixin

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: tasks.isEmpty
            ? const Center(child: Text("No tasks yet"))
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        onDoubleTap: () =>
                            _showAddOrEditTaskDialog(taskToEdit: task),
                        behavior: HitTestBehavior.opaque,
                        child: ListTile(
                          title: Text(
                            task['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: (task['done'] ?? false)
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          leading: Checkbox(
                            value: task['done'],
                            onChanged: (val) {
                              setState(() {
                                task['done'] = val;
                                if (task['subtasks'] != null) {
                                  for (var st in task['subtasks']) {
                                    st['done'] = val;
                                  }
                                }
                                tasksBox.put('all_tasks', tasks);
                              });
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () =>
                                    _showAddOrEditTaskDialog(parentTask: task),
                                tooltip: "Add Subtask",
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTask(task),
                                tooltip: "Delete Task",
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (task['subtasks'] != null &&
                          task['subtasks'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Column(
                            children: List.generate(task['subtasks'].length, (
                              subIndex,
                            ) {
                              final subtask = task['subtasks'][subIndex];
                              return GestureDetector(
                                onTap: () {},
                                onDoubleTap: () => _showAddOrEditTaskDialog(
                                  taskToEdit: subtask,
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: ListTile(
                                  title: Text(
                                    subtask['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                      decoration: (subtask['done'] ?? false)
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  leading: Checkbox(
                                    value: subtask['done'],
                                    onChanged: (val) {
                                      setState(() {
                                        subtask['done'] = val;
                                        if (task['subtasks'].every(
                                          (st) => st['done'] == true,
                                        )) {
                                          task['done'] = true;
                                        } else {
                                          task['done'] = false;
                                        }
                                        tasksBox.put('all_tasks', tasks);
                                      });
                                    },
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            task['subtasks'].removeAt(subIndex);
                                            tasksBox.put('all_tasks', tasks);
                                          });
                                        },
                                        tooltip: "Delete Subtask",
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      const Divider(),
                    ],
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
