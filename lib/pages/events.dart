import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
    // Initialize countdown flag, default false if not set
    countdownEnabled = widget.event['countdown'] ?? false;
  }

  void _toggleCountdown(bool? value) {
    setState(() {
      countdownEnabled = value ?? false;
      widget.event['countdown'] = countdownEnabled;

      // Update the Hive box
      final allEvents = widget.eventsBox.get('all_events', defaultValue: []);
      final updatedEvents = (allEvents as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final index = updatedEvents.indexWhere(
        (e) =>
            e['title'] == widget.event['title'] &&
            e['date'] == widget.event['date'],
      );

      if (index != -1) {
        updatedEvents[index] = widget.event;
        widget.eventsBox.put('all_events', updatedEvents);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Details")),
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
              "${widget.event['date'].day}/${widget.event['date'].month}/${widget.event['date'].year}",
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
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.delete),
                label: const Text("Delete Event"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
