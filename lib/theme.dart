import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  textTheme: GoogleFonts.orbitronTextTheme(ThemeData.light().textTheme),
  colorScheme: const ColorScheme.light(
    primary: Color.fromARGB(255, 38, 64, 189),
    secondary: Colors.amber,
    surface: Color(0xFFD4A373), // light surface
    error: Colors.red,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFFE3CBAA),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    toolbarHeight: 60,
    shape: Border(bottom: BorderSide(color: Color(0xFFB59B7B), width: 1.5)),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFFEFE0C8),
    elevation: 0,
    margin: const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: Color(0xFFB59B7B), width: 1.2),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFB59B7B),
    thickness: 1,
    space: 16,
  ),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF4FC3F7),
    secondary: Colors.amber,
    surface: Color(0xFF1E1E1E), // nice modern dark surface
    error: Colors.redAccent,
    onError: Colors.black,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E1E),
    elevation: 0,
    margin: const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(color: Colors.grey[800]!, width: 1.2),
    ),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey[800],
    thickness: 1,
    space: 16,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212), // pure dark
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    toolbarHeight: 60,
    shape: Border(
      bottom: BorderSide(color: Color.fromARGB(255, 76, 87, 93), width: 1.5),
    ),
  ),
);
