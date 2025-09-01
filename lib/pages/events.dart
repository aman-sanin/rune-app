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
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late DateTime selectedDate;
  bool isEditing = false; // toggle editing mode

  @override
  void initState() {
    super.initState();
    countdownEnabled = widget.event['countdown'] ?? false;
    titleController = TextEditingController(text: widget.event['title']);
    descriptionController = TextEditingController(
      text: widget.event['description'],
    );
    selectedDate = widget.event['date'];
  }

  void _toggleCountdown(bool? value) {
    setState(() {
      countdownEnabled = value ?? false;
      widget.event['countdown'] = countdownEnabled;
      _saveToHive();
    });
  }

  void _saveToHive() {
    final allEvents =
        (widget.eventsBox.get('all_events', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final index = allEvents.indexWhere(
      (e) =>
          e['title'] == widget.event['title'] &&
          e['date'] == widget.event['date'],
    );
    if (index != -1) {
      allEvents[index] = widget.event;
      widget.eventsBox.put('all_events', allEvents);
    }
  }

  void _toggleEditing() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        widget.event['date'] = selectedDate;
        _saveToHive();
      });
    }
  }

  void _saveChanges() {
    setState(() {
      widget.event['title'] = titleController.text;
      widget.event['description'] = descriptionController.text;
      widget.event['date'] = selectedDate;
      countdownEnabled = countdownEnabled;
      _saveToHive();
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Event" : "Event Details"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            tooltip: isEditing ? "Save" : "Edit",
            onPressed: isEditing ? _saveChanges : _toggleEditing,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            isEditing
                ? TextField(
                    controller: titleController,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    widget.event['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 8),

            // Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(selectedDate),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            isEditing
                ? TextField(
                    controller: descriptionController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  )
                : Text(
                    widget.event['description'],
                    style: const TextStyle(fontSize: 18),
                  ),
            const SizedBox(height: 16),

            // Countdown
            Row(
              children: [
                const Text("Enable Countdown"),
                Switch(
                  value: countdownEnabled,
                  onChanged: isEditing ? _toggleCountdown : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Delete button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.delete),
                label: const Text("Delete Event"),
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
