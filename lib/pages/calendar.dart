import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:collection/collection.dart';

import '../models/event.dart';
import '../services/database_service.dart';
import 'events.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  void _showAddEventDialog(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    bool isCountdown = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Add Event",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Event Title",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description (Optional)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${DateFormat.yMMMd().format(selectedDate)}",
                        ),
                        TextButton(
                          child: const Text("Change"),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null) {
                              setModalState(() => selectedDate = pickedDate);
                            }
                          },
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text("Enable Countdown"),
                      value: isCountdown,
                      onChanged: (val) =>
                          setModalState(() => isCountdown = val),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      child: const Text("Save Event"),
                      onPressed: () {
                        if (titleController.text.isEmpty) return;

                        final newEvent = Event(
                          title: titleController.text,
                          description: descController.text,
                          date: selectedDate,
                          countdown: isCountdown,
                        );

                        dbService.addEvent(newEvent);
                        Navigator.pop(context); // Close the bottom sheet
                      },
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

  // In lib/pages/calendar.dart

  // In lib/pages/calendar.dart

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      body: ValueListenableBuilder<Box<Event>>(
        valueListenable: dbService.eventsListenable,
        builder: (context, box, _) {
          final events = box.values.toList();
          final eventsByDate = groupBy(
            events,
            (Event e) => _normalizeDate(e.date),
          );

          // Use OrientationBuilder to return a different layout based on rotation
          return OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                // --- LANDSCAPE LAYOUT (Original Style) ---
                return Row(
                  children: [
                    Expanded(
                      // 3. Flex values restored to your original preference
                      flex: 3,
                      child: TableCalendar<Event>(
                        firstDay: DateTime.utc(2020),
                        lastDay: DateTime.utc(2030),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        eventLoader: (day) =>
                            eventsByDate[_normalizeDate(day)] ?? [],
                        // 1. Calendar is now fixed to week view in landscape
                        calendarFormat: CalendarFormat.week,
                        // 2. Format button is hidden in landscape
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: _EventListView(
                        events:
                            eventsByDate[_normalizeDate(_selectedDay!)] ?? [],
                      ),
                    ),
                  ],
                );
              } else {
                // --- PORTRAIT LAYOUT ---
                return Column(
                  children: [
                    TableCalendar<Event>(
                      firstDay: DateTime.utc(2020),
                      lastDay: DateTime.utc(2030),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      eventLoader: (day) =>
                          eventsByDate[_normalizeDate(day)] ?? [],
                    ),
                    const SizedBox(height: 8.0),
                    Expanded(
                      child: _EventListView(
                        events:
                            eventsByDate[_normalizeDate(_selectedDay!)] ?? [],
                      ),
                    ),
                  ],
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EventListView extends StatelessWidget {
  final List<Event> events;
  const _EventListView({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text("No events on this day."));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(event.title),
            subtitle: Text(event.description ?? ''),
            trailing: event.countdown
                ? const Icon(Icons.hourglass_bottom, color: Colors.orange)
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(eventKey: event.key),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
