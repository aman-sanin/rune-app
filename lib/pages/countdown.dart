// In lib/pages/countdown.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/database_service.dart';

class CountdownScreen extends StatelessWidget {
  const CountdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Countdowns")),
      // 1. Wrap the body in a ValueListenableBuilder
      body: ValueListenableBuilder<Box<Event>>(
        // 2. Listen to the events box for any changes
        valueListenable: dbService.eventsListenable,
        builder: (context, box, _) {
          // 3. Filter the events INSIDE the builder to get a live list
          final countdownEvents = box.values
              .where((event) => event.countdown)
              .toList();

          if (countdownEvents.isEmpty) {
            return const Center(child: Text("No countdowns are enabled."));
          }

          return ListView.builder(
            itemCount: countdownEvents.length,
            itemBuilder: (context, index) {
              // The CountdownTile widget itself doesn't need any changes
              return CountdownTile(event: countdownEvents[index]);
            },
          );
        },
      ),
    );
  }
}

class CountdownTile extends StatefulWidget {
  final Event event;
  const CountdownTile({super.key, required this.event});

  @override
  State<CountdownTile> createState() => _CountdownTileState();
}

class _CountdownTileState extends State<CountdownTile> {
  Timer? _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeLeft(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final difference = widget.event.date.difference(now);
    if (mounted) {
      setState(() {
        _timeLeft = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return "Event has passed";
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.event.title),
      subtitle: Text(_formatDuration(_timeLeft)),
      trailing: const Icon(Icons.hourglass_bottom, color: Colors.orange),
    );
  }
}
