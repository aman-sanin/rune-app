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

  void _showAddTaskDialog({
    Map<String, dynamic>? parentTask,
    String? linkedEventId,
  }) {
    final _titleController = TextEditingController();
    bool linkToEvent = linkedEventId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parentTask == null ? "Add Task" : "Add Subtask"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            if (linkedEventId == null)
              StatefulBuilder(
                builder: (context, setStateDialog) => CheckboxListTile(
                  value: linkToEvent,
                  onChanged: (val) =>
                      setStateDialog(() => linkToEvent = val ?? false),
                  title: const Text("Link to an Event"),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isEmpty) return;

              final currentTasks =
                  (tasksBox.get('all_tasks', defaultValue: []) as List)
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

              if (parentTask == null) {
                currentTasks.add({
                  "title": _titleController.text,
                  "done": false,
                  "subtasks": [],
                  "linkedEventId": linkToEvent ? linkedEventId : null,
                });
              } else {
                parentTask['subtasks'].add({
                  "title": _titleController.text,
                  "done": false,
                });
              }

              tasksBox.put('all_tasks', currentTasks);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteTask(Map<String, dynamic> task) {
    final currentTasks = (tasksBox.get('all_tasks', defaultValue: []) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    currentTasks.remove(task);
    tasksBox.put('all_tasks', currentTasks);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: tasksBox.listenable(),
      builder: (context, Box box, _) {
        tasks = (box.get('all_tasks', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final linkedTasks = tasks
            .where((t) => t['linkedEventId'] != null)
            .toList();
        final standaloneTasks = tasks
            .where((t) => t['linkedEventId'] == null)
            .toList();

        Widget buildTaskList(List<Map<String, dynamic>> taskList) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: taskList.length,
            itemBuilder: (context, index) {
              final task = taskList[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        final allTasks =
                            (tasksBox.get('all_tasks', defaultValue: [])
                                    as List)
                                .map((e) => Map<String, dynamic>.from(e as Map))
                                .toList();
                        final taskIndex = allTasks.indexWhere((t) => t == task);
                        setState(() {
                          allTasks[taskIndex]['done'] = val;
                          // Check/uncheck subtasks
                          if (allTasks[taskIndex]['subtasks'] != null) {
                            for (var st in allTasks[taskIndex]['subtasks']) {
                              st['done'] = val;
                            }
                          }
                          tasksBox.put('all_tasks', allTasks);
                        });
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _showAddTaskDialog(parentTask: task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTask(task),
                        ),
                      ],
                    ),
                  ),
                  // Subtasks
                  if (task['subtasks'] != null && task['subtasks'].isNotEmpty)
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
                                color: Colors.grey,
                                decoration: (subtask['done'] ?? false)
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            leading: Checkbox(
                              value: subtask['done'],
                              onChanged: (val) {
                                final allTasks =
                                    (tasksBox.get('all_tasks', defaultValue: [])
                                            as List)
                                        .map(
                                          (e) => Map<String, dynamic>.from(
                                            e as Map,
                                          ),
                                        )
                                        .toList();
                                final parentIndex = allTasks.indexWhere(
                                  (t) => t == task,
                                );
                                setState(() {
                                  allTasks[parentIndex]['subtasks'][subIndex]['done'] =
                                      val;
                                  tasksBox.put('all_tasks', allTasks);
                                });
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                final allTasks =
                                    (tasksBox.get('all_tasks', defaultValue: [])
                                            as List)
                                        .map(
                                          (e) => Map<String, dynamic>.from(
                                            e as Map,
                                          ),
                                        )
                                        .toList();
                                final parentIndex = allTasks.indexWhere(
                                  (t) => t == task,
                                );
                                setState(() {
                                  allTasks[parentIndex]['subtasks'].removeAt(
                                    subIndex,
                                  );
                                  tasksBox.put('all_tasks', allTasks);
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
          );
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: tasks.isEmpty
                ? const Center(child: Text("No tasks yet"))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (linkedTasks.isNotEmpty) ...[
                          const Text(
                            "Linked Tasks",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          buildTaskList(linkedTasks),
                        ],
                        if (standaloneTasks.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Standalone Tasks",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          buildTaskList(standaloneTasks),
                        ],
                      ],
                    ),
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTaskDialog(),
            icon: const Icon(Icons.add),
            label: const Text("Add Task"),
            backgroundColor: Colors.deepPurple,
          ),
        );
      },
    );
  }
}
