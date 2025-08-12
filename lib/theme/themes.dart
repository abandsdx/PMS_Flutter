import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData flatlyTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.teal,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData darklyTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: const Color(0xFF222222),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF375a7f), // A bluish-grey from Bootswatch Darkly
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.teal,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: Colors.tealAccent,
    ),
  );

  static final ThemeData mintTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: const Color(0xFFf5f5f5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
     colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData oceanTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF1a2228),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0d3d56),
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: Colors.lightBlueAccent,
    ),
  );

  static final Map<String, ThemeData> themes = {
    'flatly': flatlyTheme,
    'darkly': darklyTheme,
    'mint': mintTheme,
    'ocean': oceanTheme,
  };

  static ThemeData getTheme(String themeName) {
    return themes[themeName] ?? flatlyTheme; // Default to flatly
  }
}
