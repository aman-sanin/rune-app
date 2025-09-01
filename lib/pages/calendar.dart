import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

// ✨ These are now enabled to use your actual files.
import 'countdown.dart';
import 'events.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // State for managing calendar format (Month/Week)
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late final Box eventsBox;
  late final Box tasksBox;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _tasks = [];

  // --- FIX: Removed old scroll controller and state ---
  // final ScrollController _scrollController = ScrollController();
  // bool? _isScrollingCalendar;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    eventsBox = Hive.box('eventsBox');
    tasksBox = Hive.box('tasksBox');
    _loadEvents();
    _loadTasks();
  }

  @override
  void dispose() {
    // --- FIX: Removed scroll controller disposal ---
    // _scrollController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    final storedEvents = eventsBox.get('all_events', defaultValue: []) as List;
    _events = storedEvents.map((e) {
      final eventMap = Map<String, dynamic>.from(e as Map);
      if (eventMap['date'] is String) {
        eventMap['date'] = DateTime.parse(eventMap['date']);
      }
      return eventMap;
    }).toList();
  }

  void _loadTasks() {
    final storedTasks = tasksBox.get('all_tasks', defaultValue: []) as List;
    _tasks = storedTasks.map((e) {
      final taskMap = Map<String, dynamic>.from(e as Map);
      if (taskMap['subtasks'] != null) {
        final rawSubtasks = taskMap['subtasks'] as List;
        taskMap['subtasks'] = rawSubtasks.map((subtask) {
          return Map<String, dynamic>.from(subtask as Map);
        }).toList();
      }
      return taskMap;
    }).toList();
  }

  Map<DateTime, List<Map<String, dynamic>>> get _eventsMap {
    Map<DateTime, List<Map<String, dynamic>>> map = {};
    for (var event in _events) {
      // Ensure date is a DateTime object before accessing properties
      if (event['date'] is DateTime) {
        final date = DateTime(
          event['date'].year,
          event['date'].month,
          event['date'].day,
        );
        map.putIfAbsent(date, () => []).add(event);
      }
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
    return _tasks.where((t) => t['linkedEventId'] == event['title']).toList();
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Event Title',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: "Import CSV",
                          icon: const Row(
                            children: [
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
                              if (mounted) Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
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
                        if (titleController.text.isEmpty) return;
                        final events = List.from(
                          eventsBox.get('all_events', defaultValue: []),
                        );
                        final newEvent = {
                          "title": titleController.text,
                          "description": descController.text,
                          // FIX: Store dates as standardized strings
                          "date": selectedDate.toIso8601String(),
                          "countdown": countdownEnabled,
                        };
                        events.add(newEvent);
                        eventsBox.put('all_events', events);
                        Navigator.pop(context);
                      },
                      child: const Text("Add Event"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _importEventsFromCsv(String content) {
    List<dynamic> currentEvents = List.from(
      eventsBox.get('all_events', defaultValue: []),
    );
    final lines = const LineSplitter().convert(content);

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 2) continue;

      try {
        final title = parts[0].trim();
        final dateParts = parts[1].trim().split('/');
        if (dateParts.length != 3) continue;

        final date = DateTime(
          int.parse(dateParts[2]), // Year
          int.parse(dateParts[1]), // Month
          int.parse(dateParts[0]), // Day
        );

        final description = parts.length > 2 ? parts[2].trim() : '';
        final countdown =
            parts.length > 3 && parts[3].trim().toLowerCase() == 'true';

        currentEvents.add({
          "title": title,
          "description": description,
          // FIX: Store dates as standardized strings
          "date": date.toIso8601String(),
          "countdown": countdown,
        });
      } catch (e) {
        debugPrint("Error parsing CSV line: $line, Error: $e");
      }
    }
    eventsBox.put('all_events', currentEvents);
  }

  // --- FIX: Replaced entire build method with the modern, responsive version ---
  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Detect the device orientation for a responsive UI
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return ValueListenableBuilder(
      valueListenable: eventsBox.listenable(),
      builder: (context, Box box, __) {
        // Reload data whenever the database changes
        _loadEvents();
        _loadTasks();

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                TableCalendar(
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    // Show a more compact header in landscape mode
                    formatButtonShowsNext: !isLandscape,
                  ),
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
                  eventLoader: (day) =>
                      _eventsMap[DateTime(day.year, day.month, day.day)] ?? [],
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
                  // Make calendar format responsive to orientation
                  calendarFormat: isLandscape
                      ? CalendarFormat.week
                      : _calendarFormat,
                  onFormatChanged: (format) {
                    // Only allow format changes when in portrait mode
                    if (!isLandscape) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    }
                  },
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
                                  title: event["title"] ?? "No Title",
                                  date: event['date'] != null
                                      ? "${event['date'].day}/${event['date'].month}/${event['date'].year}"
                                      : "No Date",
                                  description:
                                      event["description"] ?? "No Description",
                                  countdown: hasCountdown,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EventDetailsScreen(
                                              event: event,
                                              eventsBox: eventsBox,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                if (linkedTasks.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16.0,
                                      right: 16.0,
                                      bottom: 8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: linkedTasks
                                          .map(
                                            (task) =>
                                                Text("• ${task['title']}"),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              Positioned(
                bottom: 16,
                left: 32,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CountdownScreen(),
                      ),
                    );
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
