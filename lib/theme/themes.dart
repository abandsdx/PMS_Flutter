import 'package:flutter/material.dart';

/// A class that defines and holds all the available [ThemeData] for the app.
class AppThemes {
  /// A light theme with a teal primary color, inspired by the "Flatly" Bootswatch theme.
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

  /// A dark theme with a teal primary color, inspired by the "Darkly" Bootswatch theme.
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

  /// A light theme with a fresh, green primary color.
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

  /// A dark theme with a deep blue primary color.
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

  /// A map of theme names to their corresponding [ThemeData] objects.
  static final Map<String, ThemeData> themes = {
    'flatly': flatlyTheme,
    'darkly': darklyTheme,
    'mint': mintTheme,
    'ocean': oceanTheme,
  };

  /// Returns a [ThemeData] object for a given theme name.
  ///
  /// Defaults to [flatlyTheme] if the name is not found.
  static ThemeData getTheme(String themeName) {
    return themes[themeName] ?? flatlyTheme; // Default to flatly
  }
}
