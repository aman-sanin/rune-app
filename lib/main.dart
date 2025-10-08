// In lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/event.dart';
import 'models/task.dart';
import 'pages/calendar.dart';
import 'pages/countdown.dart';
import 'pages/tasks.dart';
import 'services/database_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(TaskAdapter());

  await Hive.openBox<Event>(DatabaseService.eventsBoxName);
  await Hive.openBox<Task>(DatabaseService.tasksBoxName);

  // The Provider now wraps the entire app, which is standard practice.
  runApp(Provider(create: (_) => DatabaseService(), child: const RuneApp()));
}

class RuneApp extends StatefulWidget {
  const RuneApp({super.key});

  @override
  State<RuneApp> createState() => _RuneAppState();
}

class _RuneAppState extends State<RuneApp> {
  // Theme state is now managed at the top level of the app.
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // MOVED: MaterialApp is now the root widget.
    return MaterialApp(
      title: 'Rune',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      // The home screen is now passed the theme toggling function.
      home: MainScreen(isDarkMode: _isDarkMode, onThemeToggle: _toggleTheme),
    );
  }
}

class MainScreen extends StatefulWidget {
  // It now receives theme data from its parent.
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const MainScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const CalendarScreen(), const TasksScreen()];

  @override
  Widget build(BuildContext context) {
    // This widget now only builds the Scaffold, which is correct.
    // The `context` here is now BELOW MaterialApp, so it can find the Navigator.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            widget.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          tooltip: 'Toggle Theme',
          onPressed: widget.onThemeToggle, // Use the passed-in function
        ),
        title: const Text('Rune'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.hourglass_bottom_outlined),
            tooltip: 'View Countdowns',
            onPressed: () {
              // This will now work correctly!
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CountdownScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Tasks'),
        ],
      ),
    );
  }
}
