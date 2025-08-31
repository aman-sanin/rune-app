import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import 'events.dart';
import 'countdown.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late final Box eventsBox;
  late final Box tasksBox;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    eventsBox = Hive.box('eventsBox');
    tasksBox = Hive.box('tasksBox');
    _loadEvents();
    _loadTasks();
  }

  void _loadEvents() {
    final storedEvents = eventsBox.get('all_events', defaultValue: []);
    _events = List<Map<String, dynamic>>.from(
      (storedEvents as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  void _loadTasks() {
    final storedTasks = tasksBox.get('all_tasks', defaultValue: []);
    _tasks = List<Map<String, dynamic>>.from(
      (storedTasks as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> get _eventsMap {
    Map<DateTime, List<Map<String, dynamic>>> map = {};
    for (var event in _events) {
      final date = DateTime(
        event['date'].year,
        event['date'].month,
        event['date'].day,
      );
      map.putIfAbsent(date, () => []).add(event);
    }
    return map;
  }

  List<Map<String, dynamic>> get _selectedEvents {
    if (_selectedDay == null) return [];
    final key = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    return _eventsMap[key] ?? [];
  }

  List<Map<String, dynamic>> tasksForEvent(Map<String, dynamic> event) {
    // Tasks linked by title (you can also use a unique ID)
    return _tasks.where((t) => t['linkedEventId'] == event['title']).toList();
  }

  void _showAddEventDialog() {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    bool countdownEnabled = false;
    DateTime selectedDate = _selectedDay ?? _focusedDay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Event Title',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: "Import CSV",
                        icon: Row(
                          children: const [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 2),
                            Text(
                              "CSV",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['csv'],
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            final file = File(result.files.single.path!);
                            final content = await file.readAsString();
                            _importEventsFromCsv(content);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Event Description (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Date: "),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                            setState(() {
                              _selectedDay = picked;
                              _focusedDay = picked;
                            });
                          }
                        },
                        child: Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Enable Countdown"),
                      Checkbox(
                        value: countdownEnabled,
                        onChanged: (val) => setModalState(
                          () => countdownEnabled = val ?? false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.isEmpty) return;
                      final newEvent = {
                        "title": _titleController.text,
                        "description": _descController.text,
                        "date": selectedDate,
                        "countdown": countdownEnabled,
                      };
                      setState(() {
                        _events.add(newEvent);
                        eventsBox.put('all_events', _events);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Add Event"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _importEventsFromCsv(String content) {
    final lines = const LineSplitter().convert(content);
    for (var line in lines) {
      final parts = line.split(',');
      if (parts.length < 2) continue;
      final title = parts[0].trim();
      final dateParts = parts[1].trim().split('/');
      if (dateParts.length != 3) continue;
      final date = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );
      final description = parts.length > 2 ? parts[2].trim() : '';
      final countdown =
          parts.length > 3 && parts[3].trim().toLowerCase() == 'true';
      _events.add({
        "title": title,
        "description": description,
        "date": date,
        "countdown": countdown,
      });
    }
    eventsBox.put('all_events', _events);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: tasksBox.listenable(),
      builder: (context, _, __) {
        _loadTasks();
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Color(0xFF4FC3F7),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final key = DateTime(day.year, day.month, day.day);
                      if (_eventsMap.containsKey(key)) {
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedEvents.isEmpty
                      ? const Center(child: Text("No events on this day"))
                      : ListView.builder(
                          itemCount: _selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = _selectedEvents[index];
                            final linkedTasks = tasksForEvent(event);
                            final hasCountdown = event['countdown'] == true;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                EventTile(
                                  title: event["title"],
                                  date:
                                      "${event['date'].day}/${event['date'].month}/${event['date'].year}",
                                  description: event["description"],
                                  countdown: hasCountdown,
                                  onTap: () async {
                                    final shouldDelete = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EventDetailsScreen(
                                              event: event,
                                              eventsBox: eventsBox,
                                            ),
                                      ),
                                    );

                                    if (shouldDelete == true) {
                                      setState(() {
                                        _events.remove(event);
                                        eventsBox.put('all_events', _events);
                                      });
                                    }
                                  },
                                ),
                                if (linkedTasks.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: linkedTasks
                                          .map(
                                            (task) => ListTile(
                                              title: Text(task['title']),
                                              leading: Checkbox(
                                                value: task['done'],
                                                onChanged: (val) {
                                                  final allTasks =
                                                      (tasksBox.get(
                                                                'all_tasks',
                                                                defaultValue:
                                                                    [],
                                                              )
                                                              as List)
                                                          .map(
                                                            (e) =>
                                                                Map<
                                                                  String,
                                                                  dynamic
                                                                >.from(
                                                                  e as Map,
                                                                ),
                                                          )
                                                          .toList();
                                                  final taskIndex = allTasks
                                                      .indexWhere(
                                                        (t) => t == task,
                                                      );
                                                  setState(() {
                                                    allTasks[taskIndex]['done'] =
                                                        val;
                                                    tasksBox.put(
                                                      'all_tasks',
                                                      allTasks,
                                                    );
                                                  });
                                                },
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                const Divider(),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: Stack(
            children: [
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: _showAddEventDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Event"),
                  backgroundColor: Colors.deepPurple,
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CountdownScreen()),
                    );
                  },
                  backgroundColor: Colors.deepPurple,
                  mini: true,
                  child: const Icon(Icons.hourglass_bottom, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EventTile extends StatelessWidget {
  final String title;
  final String date;
  final String description;
  final bool countdown;
  final VoidCallback? onTap;

  const EventTile({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    this.countdown = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: Theme.of(context).dividerTheme.color ?? Colors.grey,
          width: 1.2,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        subtitle: Text('$date - $description'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (countdown)
              const Icon(
                Icons.hourglass_bottom,
                size: 18,
                color: Colors.orange,
              ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
