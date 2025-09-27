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

  runApp(const RuneApp());
}

class RuneApp extends StatelessWidget {
  const RuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The top-level app now only provides the database service
    // and loads the main screen.
    return Provider(
      create: (_) => DatabaseService(),
      child: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // 1. Add state to manage the current theme
  bool _isDarkMode = true;

  final List<Widget> _screens = [const CalendarScreen(), const TasksScreen()];

  // 2. Add a function to toggle the theme
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. MaterialApp is now built here, so it can be rebuilt with a new theme.
    return MaterialApp(
      title: 'Rune',
      theme: lightTheme,
      darkTheme: darkTheme,
      // 4. Connect the theme mode to our state variable
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          // 5. Use the `leading` property to place an icon on the left
          leading: IconButton(
            icon: Icon(
              _isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle Theme',
            onPressed: _toggleTheme,
          ),
          title: const Text('Rune'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.hourglass_bottom_outlined),
              tooltip: 'View Countdowns',
              onPressed: () {
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
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box),
              label: 'Tasks',
            ),
          ],
        ),
      ),
    );
  }
}
