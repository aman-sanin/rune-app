import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          EventTile(title: 'Event 1', date: '2024-06-01', description: "des1"),
          EventTile(title: 'Event 2', date: '2024-06-05', description: "des2"),
          EventTile(title: 'Event 3', date: '2024-06-10', description: "des3"),
        ],
      ),

      // Add Event Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add event page
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.onPrimary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface,
          width: 1.2,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
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
