import 'package:flutter/material.dart';
import '../theme/themes.dart';
import '../config.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;
  String _themeName;

  ThemeProvider(String themeName)
      : _themeName = themeName,
        _themeData = AppThemes.getTheme(themeName);

  ThemeData get themeData => _themeData;
  String get themeName => _themeName;

  void setTheme(String themeName) async {
    if (AppThemes.themes.containsKey(themeName)) {
      _themeName = themeName;
      _themeData = AppThemes.getTheme(themeName);
      Config.theme = themeName; // Update config
      await Config.saveTheme(themeName); // Save to storage
      notifyListeners();
    }
  }
}
