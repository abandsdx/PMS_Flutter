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

  /// A dark theme with clearer contrast for text on dark surfaces.
  static final ThemeData darklyTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1a2027),
    canvasColor: const Color(0xFF1a2027),
    cardColor: const Color(0xFF202a32),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF375a7f),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4aa3df),
      onPrimary: Colors.white,
      secondary: Color(0xFF5ad1d1),
      onSecondary: Colors.black,
      surface: Color(0xFF202a32),
      onSurface: Color(0xFFE5EBF1),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Color(0xFFE5EBF1), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFFD8E0E8), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFFC9D2DB)),
      bodyMedium: TextStyle(color: Color(0xFFBBC5D0)),
      bodySmall: TextStyle(color: Color(0xFFAAB4BF)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF24303b),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF3b4a58)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF3b4a58)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF5ad1d1), width: 1.6),
      ),
      labelStyle: const TextStyle(color: Color(0xFFB0BCC7)),
      hintStyle: const TextStyle(color: Color(0xFF8FA1B0)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: Color(0xFFE5EBF1)),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF202a32)),
        elevation: WidgetStatePropertyAll(8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4aa3df),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF5ad1d1),
      ),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(Color(0xFF24303b)),
      headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      dataRowColor: WidgetStatePropertyAll(Color(0xFF202a32)),
      dataTextStyle: TextStyle(color: Color(0xFFE5EBF1)),
      dividerThickness: 0.7,
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
    scaffoldBackgroundColor: const Color(0xFF0f1820),
    canvasColor: const Color(0xFF0f1820),
    cardColor: const Color(0xFF16232c),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0b3a52),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1291d0),
      onPrimary: Colors.white,
      secondary: Color(0xFF5ec8ff),
      onSecondary: Colors.black,
      surface: Color(0xFF16232c),
      onSurface: Color(0xFFe8f1f6),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Color(0xFFe8f1f6), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFFd6e6ef), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFFc8d8e3)),
      bodyMedium: TextStyle(color: Color(0xFFb9c8d3)),
      bodySmall: TextStyle(color: Color(0xFFaab8c2)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF142029),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2b3c4a))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2b3c4a))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF5ec8ff), width: 1.6)),
      labelStyle: const TextStyle(color: Color(0xFF9fb5c4)),
      hintStyle: const TextStyle(color: Color(0xFF7f93a2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: Color(0xFFe8f1f6)),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF16232c)),
        elevation: WidgetStatePropertyAll(8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1291d0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF5ec8ff),
      ),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(Color(0xFF0b3a52)),
      headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      dataRowColor: WidgetStatePropertyAll(Color(0xFF16232c)),
      dataTextStyle: TextStyle(color: Color(0xFFd6e6ef)),
      dividerThickness: 0.7,
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
