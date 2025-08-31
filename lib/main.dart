import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'pages/events.dart';

void main() {
  runApp(const RuneApp());
}

class RuneApp extends StatefulWidget {
  const RuneApp({super.key});

  @override
  State<RuneApp> createState() => _RuneAppState();
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay; // update the focused day
        });
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Color(0xFF4FC3F7),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _RuneAppState extends State<RuneApp> {
  int _currentIndex = 0; // Track the current index of active tab
  bool isDark = true;

  final _screens = const [
    CalendarScreen(),
    EventsPage(),
    Center(child: Text('Tasks')),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.light().textTheme),
        colorScheme: const ColorScheme.light(
          primary: Colors.white,
          secondary: Colors.amber,
          surface: Color(0xFFD4A373), // light surface
        ),
        scaffoldBackgroundColor: Color(0xFFE3CBAA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 60,
          shape: Border(
            bottom: BorderSide(color: Color(0xFFB59B7B), width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFFEFE0C8),
          elevation: 0,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: Color(0xFFB59B7B), width: 1.2),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Color(0xFFB59B7B),
          thickness: 1,
          space: 16,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.orbitronTextTheme(
          // Inter is clean, minimal
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4FC3F7),
          secondary: Colors.amber,
          surface: Color(0xFF1E1E1E), // nice modern dark surface
        ),
        scaffoldBackgroundColor: const Color(0xFF121212), // pure dark
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Rune'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              onPressed: () {
                setState(() {
                  isDark = !isDark;
                });
              },
            ),
          ],
        ),

        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
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
