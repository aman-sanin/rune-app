// In lib/pages/events.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/database_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final dynamic eventKey;

  const EventDetailsScreen({super.key, required this.eventKey});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final DatabaseService _dbService;
  late Event _event;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    final event = _dbService.getEvent(widget.eventKey);

    if (event == null) {
      Navigator.of(context).pop();
      return;
    }

    _event = event;

    _titleController = TextEditingController(text: _event.title);
    _descriptionController = TextEditingController(text: _event.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title cannot be empty.")));
      // Don't exit edit mode if save fails
      setState(() {
        _isEditing = true;
      });
      return;
    }

    _event.title = _titleController.text;
    _event.description = _descriptionController.text;
    await _dbService.updateEvent(_event);
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _dbService.deleteEvent(_event);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Event" : "Event Details"),
        actions: [
          IconButton(
            tooltip: _isEditing ? "Save Changes" : "Edit Event",
            icon: Icon(_isEditing ? Icons.save : Icons.edit_outlined),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- TITLE ---
            _isEditing
                ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: Theme.of(context).textTheme.headlineMedium,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Title",
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      _event.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
            const Divider(height: 1),

            // --- DATE AND COUNTDOWN ---
            // These widgets remain largely the same, controlled by the toggle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMMd().format(_event.date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_isEditing)
                    TextButton(
                      child: const Text("Change"),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _event.date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() => _event.date = pickedDate);
                        }
                      },
                    ),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text("Enable Countdown"),
              value: _event.countdown,
              onChanged: _isEditing
                  ? (value) => setState(() => _event.countdown = value)
                  : null,
            ),
            const Divider(height: 1),

            // --- DESCRIPTION ---
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _descriptionController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Description...",
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        _event.description?.isNotEmpty ?? false
                            ? _event.description!
                            : "No description provided.",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
            ),

            // --- DELETE BUTTON ---
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _deleteEvent,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text("Delete Event"),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
