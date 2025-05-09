import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale? _locale;
  static const String _selectedLocaleKey = 'selected_locale';

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale(); // Load saved locale on initialization
  }

  // Method to load the saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_selectedLocaleKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      _locale = Locale(languageCode);
    }
    // If no locale is saved, _locale remains null, and MaterialApp will use the system default
    // or the first in supportedLocales if system default is not supported.
    notifyListeners(); // Notify listeners even if no locale was loaded, to trigger initial build
  }

  // Method to set the locale and save it
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLocaleKey, locale.languageCode);
    notifyListeners();
  }

  // Method to clear the saved locale (revert to system default)
  Future<void> clearLocale() async {
    _locale = null; // Setting to null will make MaterialApp use system/default
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLocaleKey);
    notifyListeners();
  }
}