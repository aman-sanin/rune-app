import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _showAddEventDialog(BuildContext context) {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
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
            // use a local setState for the modal
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
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Event Description',
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
                            setModalState(() {
                              selectedDate = picked; // update modal date
                            });
                            setState(() {
                              _selectedDay =
                                  picked; // update main calendar selected day
                              _focusedDay = picked; // update calendar focus
                            });
                          }
                        },
                        child: Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.isNotEmpty) {
                        setState(() {
                          _events.add({
                            "title": _titleController.text,
                            "date": selectedDate,
                            "description": _descController.text,
                          });
                        });
                        Navigator.pop(context);
                      }
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

  final List<Map<String, dynamic>> _events = [
    {
      "title": "Hackathon Night",
      "date": DateTime(2025, 9, 15),
      "description": "Main Lab",
    },
    {
      "title": "Cyber Talk",
      "date": DateTime(2025, 9, 20),
      "description": "Auditorium",
    },
    {
      "title": "Game Dev Meetup",
      "date": DateTime(2025, 9, 25),
      "description": "Room 404",
    },
  ];

  // Map dates to events for markers
  Map<DateTime, List<Map<String, dynamic>>> get _eventsMap {
    Map<DateTime, List<Map<String, dynamic>>> map = {};
    for (var event in _events) {
      final date = DateTime(
        event["date"].year,
        event["date"].month,
        event["date"].day,
      );
      if (map[date] == null) {
        map[date] = [event];
      } else {
        map[date]!.add(event);
      }
    }
    return map;
  }

  // Events for selected day
  List<Map<String, dynamic>> get _selectedEvents {
    if (_selectedDay == null) return [];
    final key = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    return _eventsMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Calendar + events list
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        return EventTile(
                          title: event["title"],
                          date:
                              "${event['date'].day}/${event['date'].month}/${event['date'].year}",
                          description: event["description"],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Add Event button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddEventDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.amber, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// EventTile remains the same
class EventTile extends StatelessWidget {
  final String title;
  final String date;
  final String description;

  const EventTile({
    super.key,
    required this.title,
    required this.date,
    required this.description,
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
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () {
          // Navigate to event details page
        },
      ),
    );
  }
}
