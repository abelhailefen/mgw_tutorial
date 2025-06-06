// lib/provider/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    print("ThemeProvider: Loading theme mode preference...");
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themeModeKey);

    if (savedTheme != null) {
      print("ThemeProvider: Found saved theme mode: $savedTheme");
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
         // If saved value is 'system' or something else unexpected, use system
         _themeMode = ThemeMode.system;
         print("ThemeProvider: Saved value '$savedTheme' is not 'light' or 'dark'. Falling back to system.");
      }
    } else {
      
      print("ThemeProvider: No saved theme mode found. Defaulting to light mode.");
      _themeMode = ThemeMode.light;
      
    }

    notifyListeners();
     print("ThemeProvider: Initial theme mode set to $_themeMode. Notified listeners.");
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    print("ThemeProvider: Setting theme mode to $mode");
    // Only update if the mode is actually changing
    if (_themeMode != mode) {
       _themeMode = mode;
       final prefs = await SharedPreferences.getInstance();
       String themeString;
       switch (mode) {
         case ThemeMode.light:
           themeString = 'light';
           break;
         case ThemeMode.dark:
           themeString = 'dark';
           break;
         case ThemeMode.system:
           themeString = 'system'; // Although the current UI doesn't offer system
           break;
       }
       await prefs.setString(_themeModeKey, themeString);
       print("ThemeProvider: Saved theme mode preference: $themeString");
       notifyListeners(); // Notify listeners to rebuild the UI with the new theme
    } else {
       print("ThemeProvider: Theme mode is already $mode, no change.");
    }
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    await setThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }
}