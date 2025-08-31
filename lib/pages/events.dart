import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final Box eventsBox;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.eventsBox,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late bool countdownEnabled;

  @override
  void initState() {
    super.initState();
    countdownEnabled = widget.event['countdown'] ?? false;
  }

  void _toggleCountdown(bool? value) {
    setState(() {
      countdownEnabled = value ?? false;
      widget.event['countdown'] = countdownEnabled;

      // This logic for finding and updating is fragile if titles/dates are not unique.
      // For this to be robust, each event should have a unique ID.
      final allEvents = widget.eventsBox.get('all_events', defaultValue: []);
      final updatedEvents = (allEvents as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // We find the event by its original properties before they were changed.
      final index = updatedEvents.indexWhere(
        (e) =>
            e['title'] == widget.event['title'] &&
            e['date'] == widget.event['date'],
      );

      if (index != -1) {
        updatedEvents[index]['countdown'] = countdownEnabled;
        widget.eventsBox.put('all_events', updatedEvents);
      }
    });
  }

  // ✨ NEW: Method to show the edit dialog
  void _showEditEventDialog() {
    final titleController = TextEditingController(text: widget.event['title']);
    final descriptionController = TextEditingController(
      text: widget.event['description'],
    );
    DateTime selectedDate = widget.event['date'];

    // Store original values to find the event in Hive later
    final String originalTitle = widget.event['title'];
    final DateTime originalDate = widget.event['date'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // Use StatefulBuilder to update the date in the dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the widget's state with new values
                    setState(() {
                      widget.event['title'] = titleController.text;
                      widget.event['description'] = descriptionController.text;
                      widget.event['date'] = selectedDate;
                    });

                    // Persist changes to Hive
                    final allEvents = widget.eventsBox.get(
                      'all_events',
                      defaultValue: [],
                    );
                    final updatedEvents = (allEvents as List)
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();

                    final index = updatedEvents.indexWhere(
                      (e) =>
                          e['title'] == originalTitle &&
                          e['date'] == originalDate,
                    );

                    if (index != -1) {
                      updatedEvents[index] = widget.event;
                      widget.eventsBox.put('all_events', updatedEvents);
                    }

                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
        // ✨ NEW: Edit button in the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditEventDialog,
            tooltip: 'Edit Event',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event['title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              // Use DateFormat for consistent formatting
              DateFormat('dd/MM/yyyy').format(widget.event['date']),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.event['description'],
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Enable Countdown"),
                Switch(value: countdownEnabled, onChanged: _toggleCountdown),
              ],
            ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // This signals the previous screen to delete the event
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.delete),
                label: const Text("Delete Event"),
                // ✨ IMPROVEMENT: Use the theme's error color
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
