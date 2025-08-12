import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _locationKey = 'location_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('fr', 'FR');
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _isLoading = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationEnabled => _locationEnabled;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Charger le thème
      final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeIndex];
      
      // Charger la langue
      final languageCode = prefs.getString(_languageKey) ?? 'fr';
      _locale = Locale(languageCode);
      
      // Charger les préférences notifications
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      
      // Charger les préférences localisation
      _locationEnabled = prefs.getBool(_locationKey) ?? true;
      
    } catch (e) {
      debugPrint('Erreur chargement préférences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    
    _notificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setLocationEnabled(bool enabled) async {
    if (_locationEnabled == enabled) return;
    
    _locationEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationKey, enabled);
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _themeMode = ThemeMode.system;
    _locale = const Locale('fr', 'FR');
    _notificationsEnabled = true;
    _locationEnabled = true;
    
    notifyListeners();
  }

  // Méthodes utiles pour l'UI
  String getThemeLabel() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Automatique';
    }
  }

  String getLanguageLabel() {
    switch (_locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'Français';
    }
  }
}