import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late final Box eventsBox;
  List<Map<String, dynamic>> countdownEvents = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    eventsBox = Hive.box('eventsBox');
    _loadCountdownEvents();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {}); // refresh countdowns every second
    });
  }

  void _loadCountdownEvents() {
    final allEvents = (eventsBox.get('all_events', defaultValue: []) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    countdownEvents = allEvents.where((e) => e['countdown'] == true).toList();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _getTimeLeft(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) return "Event passed";

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Countdowns")),
      body: countdownEvents.isEmpty
          ? const Center(child: Text("No countdowns enabled"))
          : ListView.builder(
              itemCount: countdownEvents.length,
              itemBuilder: (context, index) {
                final event = countdownEvents[index];
                final date = event['date'] as DateTime;
                return ListTile(
                  title: Text(event['title']),
                  subtitle: Text(_getTimeLeft(date)),
                  trailing: const Icon(
                    Icons.hourglass_bottom,
                    color: Colors.deepPurple,
                  ),
                );
              },
            ),
    );
  }
}
