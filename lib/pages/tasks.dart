import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final Box tasksBox;
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    tasksBox = Hive.box('tasksBox');

    // Load tasks from Hive
    tasks = (tasksBox.get('all_tasks', defaultValue: []) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  void _showAddTaskDialog({Map<String, dynamic>? parentTask}) {
    final _titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(parentTask == null ? "Add Task" : "Add Subtask"),
          content: TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Task Title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  setState(() {
                    if (parentTask == null) {
                      tasks.add({
                        "title": _titleController.text,
                        "done": false,
                        "subtasks": [],
                        "linkedEvent": null,
                      });
                    } else {
                      parentTask['subtasks'].add({
                        "title": _titleController.text,
                        "done": false,
                      });
                    }
                    tasksBox.put('all_tasks', tasks);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
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
                      // Parent Task
                      ListTile(
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

                              // Check/uncheck all subtasks
                              if (task['subtasks'] != null) {
                                for (var st in task['subtasks']) {
                                  st['done'] = val;
                                }
                              }

                              tasksBox.put('all_tasks', tasks);
                            });
                          },
                          fillColor: MaterialStateProperty.resolveWith<Color?>((
                            states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return Theme.of(context).colorScheme.primary;
                            }
                            return null;
                          }),
                          checkColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  _showAddTaskDialog(parentTask: task),
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

                      // Subtasks
                      if (task['subtasks'] != null &&
                          task['subtasks'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Column(
                            children: List.generate(task['subtasks'].length, (
                              subIndex,
                            ) {
                              final subtask = task['subtasks'][subIndex];
                              return ListTile(
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

                                      // Auto-check parent task if all subtasks done
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
                                  fillColor: MaterialStateProperty.resolveWith((
                                    states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return Theme.of(
                                        context,
                                      ).colorScheme.primary;
                                    }
                                    return null;
                                  }),
                                  checkColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      task['subtasks'].removeAt(subIndex);

                                      // Update parent done status after removal
                                      if (task['subtasks'].isEmpty ||
                                          task['subtasks'].every(
                                            (st) => st['done'] == true,
                                          )) {
                                        task['done'] = task['subtasks'].isEmpty
                                            ? task['done']
                                            : true;
                                      } else {
                                        task['done'] = false;
                                      }

                                      tasksBox.put('all_tasks', tasks);
                                    });
                                  },
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
        onPressed: () => _showAddTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
